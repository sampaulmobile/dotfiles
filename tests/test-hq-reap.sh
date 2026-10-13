#!/usr/bin/env bash
#
# bin/hq-reap's pure halves: the whole kill/park/keep decision table
# (reap_decide), the resume command builder (reap_resume_cmd,
# reap_parse_model_effort), task-args detection (reap_is_task_args) and the
# busy-pane test (reap_pane_busy). Offline — the script is SOURCED, which
# stops before the live tmux/ps/jq glue and the args dispatch (the
# BASH_SOURCE guard near the top of bin/hq-reap), so no tmux server is
# started or touched and no real machine session is read.
#
#   tests/test-hq-reap.sh
#
# The case that matters most in reap_decide is precedence: the never-a-
# candidate checks (not a task session, not tied, attached, busy pane, a bad
# agent-pane status) must all fire before tier 1 or tier 2 ever look at PR
# state, or an attached session sitting on a MERGED PR would get killed out
# from under whoever is looking at it.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo_dir/bin/hq-reap"

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

echo "── sourcing bin/hq-reap ran no live pass (main is guarded)"
if declare -f reap_decide >/dev/null && declare -f reap_resume_cmd >/dev/null \
    && declare -f reap_is_task_args >/dev/null && declare -f reap_pane_busy >/dev/null; then
    ok "functions available after sourcing"
else
    bad "reap_decide/reap_resume_cmd/reap_is_task_args/reap_pane_busy not defined by sourcing" ""
fi

echo "── reap_decide: the decision table"

# case_ <label> <want> <task> <tied> <attached> <busy> <pane_bad> <dirty> \
#       <pr_state> <unpushed> <merged_local> <pr_head> <wt_head> <phase> \
#       <pane_count> <has_transcript> <idle_secs> <park_secs> <parked>
# <want> comes right after <label> (not last) so bash 3.2 needs no
# negative-offset/last-element trick to pull it back out.
case_() {
    local label="$1" want="$2"
    shift 2
    local got
    got=$(reap_decide "$@")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-46s -> %s\n' "$label" "$got"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-46s -> got [%s] want [%s]\n' "$label" "$got" "$want"
        fail=$(( fail + 1 ))
    fi
}

case_ "not a task session" "keep not a task session" \
    false true false "" "" false none false false - - "" 0 false 0 43200 false

case_ "no row (not tied to a worktree)" "keep not tied to a worktree" \
    true false false "" "" false none false false - - "" 0 false 0 43200 false

case_ "attached" "keep attached" \
    true true true "" "" false MERGED false true - - "" 0 false 0 43200 false

case_ "busy pane" "keep busy pane: npm run dev" \
    true true false "npm run dev" "" false none false false - - "" 0 false 0 43200 false

case_ "agent pane working" "keep agent working" \
    true true false "" working false none false false - - "" 0 false 0 43200 false

case_ "agent pane permission" "keep agent permission" \
    true true false "" permission false none false false - - "" 0 false 0 43200 false

case_ "agent pane unknown" "keep agent unknown" \
    true true false "" unknown false none false false - - "" 0 false 0 43200 false

case_ "MERGED, removable (merged_local) -> kill" "kill merged" \
    true true false "" "" false MERGED false true - - "" 0 false 0 43200 false

case_ "MERGED, unpushed, not merged_local -> keep" "keep merged, unpushed" \
    true true false "" "" false MERGED true false aaa bbb "" 0 false 0 43200 false

case_ "dirty beats everything past the never-candidate checks" "keep DIRTY" \
    true true false "" "" true MERGED false true - - "" 0 false 0 43200 false

case_ "CLOSED, pushed -> kill" "kill closed" \
    true true false "" "" false CLOSED false false headsha headsha "" 0 false 0 43200 false

case_ "CLOSED, unpushed but PR head == worktree head -> kill" "kill closed" \
    true true false "" "" false CLOSED true false samesha samesha "" 0 false 0 43200 false

case_ "CLOSED, unpushed, PR head != worktree head -> keep" "keep closed, unpushed" \
    true true false "" "" false CLOSED true false aaa bbb "" 0 false 0 43200 false

case_ "OPEN, phase not done -> keep" "keep phase implement" \
    true true false "" "" false OPEN false false - - implement 1 true 50000 43200 false

case_ "OPEN, no phase at all -> keep" "keep phase none" \
    true true false "" "" false OPEN false false - - "" 1 true 50000 43200 false

case_ "OPEN, done, idle 11h < 12h park threshold -> keep" "keep idle 39600s < 43200s" \
    true true false "" "" false OPEN false false - - done 1 true 39600 43200 false

case_ "OPEN, done, idle 13h >= 12h park threshold -> park" "park idle 46800s" \
    true true false "" "" false OPEN false false - - done 1 true 46800 43200 false

case_ "OPEN, done, already parked -> keep (never re-signal)" "keep already parked" \
    true true false "" "" false OPEN false false - - "done" 1 true 46800 43200 true

case_ "OPEN, done, two agent panes -> keep" "keep 2 agent panes" \
    true true false "" "" false OPEN false false - - done 2 true 46800 43200 false

case_ "OPEN, done, no transcript -> keep" "keep no transcript" \
    true true false "" "" false OPEN false false - - done 1 false 46800 43200 false

case_ "no PR, pushed -> SHIPPED?" "keep SHIPPED?" \
    true true false "" "" false none false false - - "" 0 false 0 43200 false

case_ "no PR, unpushed -> PARKED" "keep PARKED" \
    true true false "" "" false none true false - - "" 0 false 0 43200 false

echo "── reap_is_task_args: /feature --run detection"

if reap_is_task_args "-n 'x' --model opus --effort high /feature --run --requester=hq-hub"; then
    ok "a task session's claude argv (brief starts with /feature --run)"
else
    bad "task argv should match" "reap_is_task_args returned false"
fi

if reap_is_task_args "--resume x-hub"; then
    bad "a hub's --resume argv should not match" "reap_is_task_args returned true"
else
    ok "a hub session's claude argv (--resume, no brief) does not match"
fi

echo "── reap_pane_busy: shell/editor allow-list"

for shellcmd in zsh bash sh fish nvim vim vi -zsh; do
    if reap_pane_busy "$shellcmd"; then
        bad "shell/editor command should not count as busy" "$shellcmd"
    else
        ok "'$shellcmd' is not busy"
    fi
done

for busycmd in npm node make pytest; do
    if reap_pane_busy "$busycmd"; then
        ok "'$busycmd' counts as busy"
    else
        bad "non-shell/editor command should count as busy" "$busycmd"
    fi
done

echo "── reap_parse_model_effort"

reap_parse_model_effort "claude -n 'x' --model opus --effort high /feature --run"
if [[ "$reap_model_out" == opus && "$reap_effort_out" == high ]]; then
    ok "model and effort both parsed from argv"
else
    bad "model/effort parse" "got model=[$reap_model_out] effort=[$reap_effort_out]"
fi

reap_parse_model_effort "claude -n 'x' /feature --run"
if [[ -z "$reap_model_out" && -z "$reap_effort_out" ]]; then
    ok "no seat flags -> both empty"
else
    bad "no seat flags should parse empty" "got model=[$reap_model_out] effort=[$reap_effort_out]"
fi

echo "── reap_resume_cmd: the typed command that wakes a parked session"

reap_resume_cmd "myproj_feat-x"
if [[ "$reap_resume_cmd_out" == "claude --resume 'myproj_feat-x'" ]]; then
    ok "no seat flags -> bare claude --resume"
else
    bad "no seat flags" "got [$reap_resume_cmd_out]"
fi

reap_resume_cmd "myproj_feat-x" opus
if [[ "$reap_resume_cmd_out" == "claude --resume 'myproj_feat-x' --model opus" ]]; then
    ok "model only -> --model, no --effort"
else
    bad "model only" "got [$reap_resume_cmd_out]"
fi

reap_resume_cmd "myproj_feat-x" opus high
if [[ "$reap_resume_cmd_out" == "claude --resume 'myproj_feat-x' --model opus --effort high" ]]; then
    ok "model and effort both ride the resume command"
else
    bad "model + effort" "got [$reap_resume_cmd_out]"
fi

reap_resume_cmd "it's a session"
want="claude --resume 'it'\\''s a session'"
if [[ "$reap_resume_cmd_out" == "$want" ]]; then
    ok "an apostrophe in the session name is escaped"
else
    bad "apostrophe escaping" "want [$want]"$'\n       '"got  [$reap_resume_cmd_out]"
fi

# The escaped line must round-trip through a real shell: what a pane's shell
# parses has to be the argv the resume was asked for.
argv=$(eval "set -- ${reap_resume_cmd_out#claude }; printf '%s\n' \"\$@\"")
want_argv=$'--resume\nit\'s a session'
if [[ "$argv" == "$want_argv" ]]; then
    ok "the built resume command parses back to the intended argv"
else
    bad "resume command round-trips through a shell" "want [$want_argv]"$'\n       '"got  [$argv]"
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
