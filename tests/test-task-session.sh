#!/usr/bin/env bash
#
# bin/tmux-task-session's pure halves over a throwaway fake worktree tree
# (mktemp -d): the session name it derives and the claude command line it
# types. Offline — the script is SOURCED, so its tmux-touching main never
# runs and no server is started or contacted.
#
#   tests/test-task-session.sh
#
# The naming cases assert equality with project-dirs-lib's session_name_for
# rather than with a literal: the contract is "the same name Ctrl+F and
# wt-tmux-cleanup use", not a string this test picked.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/task-session-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

# ---- fake tree: an agent worktree and a worktrunk sibling of one repo ----
mkdir -p "$work/dev/proj1/.git/worktrees/agent-abc123"
mkdir -p "$work/dev/proj1/.claude/worktrees/agent-abc123"
echo "gitdir: $work/dev/proj1/.git/worktrees/agent-abc123" > "$work/dev/proj1/.claude/worktrees/agent-abc123/.git"
echo "ref: refs/heads/feat/option-c" > "$work/dev/proj1/.git/worktrees/agent-abc123/HEAD"

mkdir -p "$work/dev/proj1/.git/worktrees/feat-option-c"
mkdir -p "$work/dev/proj1.feat-option-c"
echo "gitdir: $work/dev/proj1/.git/worktrees/feat-option-c" > "$work/dev/proj1.feat-option-c/.git"
echo "ref: refs/heads/feat/option-c" > "$work/dev/proj1/.git/worktrees/feat-option-c/HEAD"

# ---- source the script; search_dirs must be set first (bash 3.2 quirk, see
# ---- project-dirs-lib) so nothing reads this machine's ~/dev ----
search_dirs=("$work/dev:1")
PROJECT_DIRS_LOCAL=/nonexistent
# shellcheck source=/dev/null
source "$repo/bin/tmux-task-session"

echo "── task_session_name: one rule with session_name_for, never a second copy"

agent_wt="$work/dev/proj1/.claude/worktrees/agent-abc123"
session_name_for "$agent_wt"
want="$session_name"
task_session_name "$agent_wt"
if [[ "$task_session_name_out" == "$want" && -n "$want" ]]; then
    ok "agent worktree -> $want (== session_name_for)"
else
    bad "agent worktree == session_name_for" "want [$want] got [$task_session_name_out]"
fi

sibling="$work/dev/proj1.feat-option-c"
session_name_for "$sibling"
want="$session_name"
task_session_name "$sibling"
if [[ "$task_session_name_out" == "$want" && -n "$want" ]]; then
    ok "worktrunk sibling -> $want (== session_name_for)"
else
    bad "worktrunk sibling == session_name_for" "want [$want] got [$task_session_name_out]"
fi

# Both worktrees are the same branch of the same repo, so both must land on
# the ONE session a dispatcher can address by name.
task_session_name "$agent_wt"; a="$task_session_name_out"
task_session_name "$sibling";  b="$task_session_name_out"
if [[ "$a" == "$b" ]]; then
    ok "agent worktree and worktrunk sibling of one branch share a session name"
else
    bad "one branch, one session name" "agent [$a] sibling [$b]"
fi

echo "── task_claude_command: the line typed into the agent window"

pfile="$work/dev/proj1.feat-option-c/.feature/launch-prompt.md"

task_claude_command "proj1_feat-option-c" "$pfile"
got="$task_claude_command_out"
want="claude -n 'proj1_feat-option-c' \"\$(cat '$pfile')\""
if [[ "$got" == "$want" ]]; then
    ok "no seat flags -> bare claude -n plus the prompt file"
else
    bad "no seat flags" "want [$want]"$'\n       '"got  [$got]"
fi

# The prompt reaches claude through "$(cat <file>)", never as a typed
# literal: a brief is arbitrary multi-line text and nothing about it may have
# to survive shell quoting.
case "$got" in
    *'"$(cat '*) ok "prompt is read from the file by the shell, not typed inline" ;;
    *) bad "prompt read from file" "got [$got]" ;;
esac

task_claude_command "s" "$pfile" opus high
got="$task_claude_command_out"
want="claude -n 's' --model opus --effort high \"\$(cat '$pfile')\""
if [[ "$got" == "$want" ]]; then
    ok "seat opus:high -> --model opus --effort high (both, resolved)"
else
    bad "seat opus:high -> --model opus --effort high" "want [$want]"$'\n       '"got  [$got]"
fi

task_claude_command "s" "$pfile" opus ""
got="$task_claude_command_out"
if [[ "$got" == *"--model opus"* && "$got" != *"--effort"* ]]; then
    ok "model only -> --model, no --effort"
else
    bad "model only" "got [$got]"
fi

task_claude_command "s" "$pfile" "" xhigh
got="$task_claude_command_out"
if [[ "$got" == *"--effort xhigh"* && "$got" != *"--model"* ]]; then
    ok "effort only -> --effort, no --model"
else
    bad "effort only" "got [$got]"
fi

echo "── task_claude_command: quoting"

task_claude_command "it's" "$work/o'brien/.feature/launch-prompt.md"
got="$task_claude_command_out"
want="claude -n 'it'\\''s' \"\$(cat '$work/o'\\''brien/.feature/launch-prompt.md')\""
if [[ "$got" == "$want" ]]; then
    ok "apostrophes in the session name and the path are escaped"
else
    bad "apostrophe escaping" "want [$want]"$'\n       '"got  [$got]"
fi

# The escaped line must actually round-trip through a shell: what the pane's
# shell parses has to be the argv the caller asked for.
mkdir -p "$work/o'brien/.feature"
printf 'brief body\n' > "$work/o'brien/.feature/launch-prompt.md"
argv=$(eval "set -- ${got#claude }; printf '%s\n' \"\$@\"")
want=$'-n\nit\'s\nbrief body'
if [[ "$argv" == "$want" ]]; then
    ok "the built line parses back to the intended argv"
else
    bad "built line parses back to argv" "want [$want]"$'\n       '"got  [$argv]"
fi

echo "── task_claude_command: model/effort are typed unquoted, so they are validated"
if task_claude_command "s" "$pfile" 'opus; rm -rf /' high 2>/dev/null; then
    bad "a model value with shell metacharacters is refused" "got [$task_claude_command_out]"
else
    ok "a model value with shell metacharacters is refused"
fi
if task_claude_command "s" "$pfile" opus 'high$(id)' 2>/dev/null; then
    bad "an effort value with shell metacharacters is refused" "got [$task_claude_command_out]"
else
    ok "an effort value with shell metacharacters is refused"
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
