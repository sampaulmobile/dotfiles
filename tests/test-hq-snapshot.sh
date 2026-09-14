#!/usr/bin/env bash
#
# bin/hq-snapshot's pure half, over a throwaway snapshot dir (mktemp -d)
# pointed at by HQ_SNAPSHOT_DIR. Offline: no tmux server is started or
# touched, no gh is called, no worktree is created — the pipelines source is
# driven by .feature fixtures written here.
#
#   tests/test-hq-snapshot.sh
#
# The cases that matter: the atomic write leaves <file>.tmp.<pid> as the only
# intermediate name and removes nothing; a snapshot's age decides fresh vs
# stale vs missing; and a worktree with no .feature/, an empty status.jsonl
# or a pre-jsonl status.json all read as NO pipeline state, never as a stale
# one.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-snapshot-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

export HQ_SNAPSHOT_DIR="$work/snapshot"

# shellcheck source=/dev/null
source "$repo/bin/hq-snapshot"

echo "── sourcing hands back the reader half and collects nothing"
if declare -f snapshot_write >/dev/null && declare -f snapshot_verdict >/dev/null \
    && declare -f snapshot_read >/dev/null && declare -f fmt_secs >/dev/null; then
    ok "snapshot_write/snapshot_verdict/snapshot_read/fmt_secs defined by sourcing"
else
    bad "reader half not defined by sourcing" "one of the four is missing"
fi
if [[ ! -d "$HQ_SNAPSHOT_DIR" ]]; then
    ok "sourcing creates no snapshot directory"
else
    bad "sourcing created $HQ_SNAPSHOT_DIR" "the source guard let collection run"
fi

echo "── snapshot_write: header line, atomic name, nothing removed"
printf 'a\tb\nc\td\n' | snapshot_write demo
f=$(snapshot_file demo)
if [[ "$f" == "$HQ_SNAPSHOT_DIR/demo.tsv" ]]; then
    ok "snapshot_file names <dir>/<source>.tsv"
else
    bad "snapshot_file" "got [$f]"
fi
first=$(head -n1 "$f")
case "$first" in
    '# generated '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z)
        ok "first line is a generated-at header: [$first]" ;;
    *)  bad "generated-at header" "got [$first]" ;;
esac
body=$(snapshot_read demo)
if [[ "$body" == $'a\tb\nc\td' ]]; then
    ok "snapshot_read drops the header and returns the body"
else
    bad "snapshot_read body" "got [$body]"
fi
# A body line that itself starts with '#' must survive: only the FIRST line
# is the header.
printf '# not a header\nx\ty\n' | snapshot_write demo
body=$(snapshot_read demo)
if [[ "$body" == $'# not a header\nx\ty' ]]; then
    ok "only the first line is treated as the header"
else
    bad "header stripping is not first-line-only" "got [$body]"
fi
# The write must go through <file>.tmp.$$ and leave nothing else behind.
leftovers=$(find "$HQ_SNAPSHOT_DIR" -name 'demo.tsv.tmp.*' 2>/dev/null)
if [[ -z "$leftovers" ]]; then
    ok "a successful write leaves no tmp file"
else
    bad "tmp file left after a successful write" "$leftovers"
fi
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-snapshot"; then
    ok "the collector contains no rm, rmdir, unlink or -delete"
else
    bad "the collector contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-snapshot")"
fi
# An empty body is still a write: a consumer must see "no rows", not a stale
# previous snapshot.
printf '' | snapshot_write demo
body=$(snapshot_read demo)
if [[ -z "$body" ]]; then
    ok "an empty body publishes an empty snapshot"
else
    bad "empty body" "got [$body]"
fi

echo "── snapshot_read/snapshot_age on a source that was never written"
if ! snapshot_read never-written >/dev/null 2>&1; then
    ok "snapshot_read exits 1 for a missing source"
else
    bad "snapshot_read on a missing source" "expected exit 1"
fi
a=$(snapshot_age never-written)
if [[ "$a" == "-1" ]]; then
    ok "snapshot_age is -1 for a missing source"
else
    bad "snapshot_age missing" "got [$a]"
fi

echo "── snapshot_cadence: the registry is the only home for a cadence"
cad_() {
    local name="$1" want="$2" got
    got=$(snapshot_cadence "$name")
    if [[ "$got" == "$want" ]]; then
        ok "cadence $name -> $got"
    else
        bad "cadence $name" "got [$got] want [$want]"
    fi
}
cad_ sessions 5
cad_ pipelines 5
cad_ worktrees 15
cad_ prs 30
if ! snapshot_cadence not-a-source >/dev/null 2>&1; then
    ok "snapshot_cadence exits 1 for a name that is not a source"
else
    bad "snapshot_cadence on a non-source" "expected exit 1"
fi

echo "── snapshot_verdict: fresh until three cadences old, then stale"
verdict_() {
    local age="$1" cadence="$2" want="$3" got
    got=$(snapshot_verdict "$age" "$cadence")
    if [[ "$got" == "$want" ]]; then
        ok "age=$age cadence=$cadence -> $got"
    else
        bad "verdict age=$age cadence=$cadence" "got [$got] want [$want]"
    fi
}
verdict_ -1 5 missing
verdict_ 0 5 fresh
verdict_ 15 5 fresh
verdict_ 16 5 stale
verdict_ 45 15 fresh
verdict_ 46 15 stale
verdict_ 90 30 fresh
verdict_ 91 30 stale
verdict_ 99999 0 fresh

echo "── fmt_secs"
secs_() {
    local s="$1" want="$2" got
    got=$(fmt_secs "$s")
    if [[ "$got" == "$want" ]]; then
        ok "fmt_secs $s -> $got"
    else
        bad "fmt_secs $s" "got [$got] want [$want]"
    fi
}
secs_ -1 never
secs_ 0 0s
secs_ 59 59s
secs_ 60 1m
secs_ 3599 59m
secs_ 3600 1h
secs_ 86399 23h
secs_ 86400 1d

echo "── jsonl_last_line: the append-only contract's last non-empty line"
mkdir -p "$work/wt-live/.feature"
jl="$work/wt-live/.feature/status.jsonl"
printf '%s\n' \
    '{"phase":"plan","round":1,"seat":"orchestrator","pr":null,"updated":"2026-09-13T01:00:00Z"}' \
    '{"phase":"implement","round":2,"seat":"implementer","pr":41,"updated":"2026-09-13T02:00:00Z"}' \
    > "$jl"
last=$(jsonl_last_line "$jl")
case "$last" in
    *'"phase":"implement"'*) ok "the last line wins over earlier ones" ;;
    *) bad "jsonl_last_line" "got [$last]" ;;
esac
# An unterminated final line is still the state: the writer may be mid-append.
printf '{"phase":"review","round":3,"seat":"reviewer"}' >> "$jl"
last=$(jsonl_last_line "$jl")
case "$last" in
    *'"phase":"review"'*) ok "an unterminated last line is still read" ;;
    *) bad "jsonl_last_line unterminated" "got [$last]" ;;
esac
: > "$work/empty.jsonl"
last=$(jsonl_last_line "$work/empty.jsonl")
if [[ -z "$last" ]]; then ok "an empty file has no last line"; else bad "empty jsonl" "got [$last]"; fi
last=$(jsonl_last_line "$work/nope.jsonl")
if [[ -z "$last" ]]; then ok "a missing file has no last line"; else bad "missing jsonl" "got [$last]"; fi

echo "── json_field"
rec='{"repo":"dotfiles","pr":null,"round":2,"pushed":false,"updated":"2026-09-13T02:00:00Z"}'
jf_() {
    local key="$1" want="$2" got
    got=$(json_field "$rec" "$key")
    if [[ "$got" == "$want" ]]; then
        ok "json_field $key -> [$got]"
    else
        bad "json_field $key" "got [$got] want [$want]"
    fi
}
jf_ repo dotfiles
jf_ updated 2026-09-13T02:00:00Z
jf_ round 2
jf_ pushed false
jf_ pr ""
jf_ absent ""

echo "── pipeline_map_load / pipeline_for_cwd"
printf '%s\n' \
    "$work/dev/proj/.claude/worktrees/agent-run"$'\t'"proj_feat-x"$'\t'"proj"$'\t'"feat/x"$'\t'"implement r1 implementer"$'\t'"-"$'\t'"2026-09-13T02:00:00Z" \
    | snapshot_write pipelines
pipeline_map_load
got=$(pipeline_for_cwd "$work/dev/proj/.claude/worktrees/agent-run")
if [[ "$got" == "implement r1 implementer" ]]; then
    ok "a pane at the worktree root gets its state"
else
    bad "pipeline_for_cwd at the root" "got [$got]"
fi
got=$(pipeline_for_cwd "$work/dev/proj/.claude/worktrees/agent-run/bin/deep")
if [[ "$got" == "implement r1 implementer" ]]; then
    ok "a pane in a subdirectory gets the worktree's state"
else
    bad "pipeline_for_cwd under the worktree" "got [$got]"
fi
got=$(pipeline_for_cwd "$work/dev/proj")
if [[ -z "$got" ]]; then
    ok "the repo itself is not the worktree, and gets nothing"
else
    bad "pipeline_for_cwd on the repo" "got [$got]"
fi
got=$(pipeline_for_cwd "")
if [[ -z "$got" ]]; then ok "an empty cwd gets nothing"; else bad "pipeline_for_cwd empty" "got [$got]"; fi

echo "── collect_pipelines: which worktrees get a row"
# A fake HOME, so project_dirs enumerates this tree and never the real ~/dev;
# PROJECT_DIRS_LOCAL is pointed away from the machine's own override.
fh="$work/home"
mkdir -p "$fh/dev/proj/.git"
mk_wt() {   # mk_wt <name> <branch-ref-line>
    mkdir -p "$fh/dev/proj/.claude/worktrees/$1"
    mkdir -p "$fh/dev/proj/.git/worktrees/$1"
    printf 'gitdir: %s\n' "$fh/dev/proj/.git/worktrees/$1" > "$fh/dev/proj/.claude/worktrees/$1/.git"
    printf '%s\n' "$2" > "$fh/dev/proj/.git/worktrees/$1/HEAD"
}
mk_wt run "ref: refs/heads/feat/x"
mkdir -p "$fh/dev/proj/.claude/worktrees/run/.feature"
printf '%s\n' '{"repo":"proj","branch":"feat/x","phase":"implement","round":1,"seat":"implementer","pr":null,"updated":"2026-09-13T02:00:00Z"}' \
    > "$fh/dev/proj/.claude/worktrees/run/.feature/status.jsonl"
mk_wt bare "ref: refs/heads/bare"
mk_wt empty "ref: refs/heads/empty"
mkdir -p "$fh/dev/proj/.claude/worktrees/empty/.feature"
: > "$fh/dev/proj/.claude/worktrees/empty/.feature/status.jsonl"
# The PRE-JSONL status.json must read as no state, never as a stale one.
mk_wt old "ref: refs/heads/old"
mkdir -p "$fh/dev/proj/.claude/worktrees/old/.feature"
printf '%s\n' '{"phase":"ship","round":9,"seat":"orchestrator"}' \
    > "$fh/dev/proj/.claude/worktrees/old/.feature/status.json"

HOME="$fh" PROJECT_DIRS_LOCAL=/nonexistent HQ_SNAPSHOT_DIR="$work/snapshot" \
    "$repo/bin/hq-snapshot" pipelines >/dev/null 2>&1
rc=$?
if (( rc == 0 )); then ok "collect_pipelines exits 0"; else bad "collect_pipelines exit" "got $rc"; fi
body=$(snapshot_read pipelines)
n=$(printf '%s' "$body" | grep -c . )
if (( n == 1 )); then
    ok "exactly one row: the worktree with a status.jsonl"
else
    bad "row count" "got $n rows: [$body]"
fi
IFS=$'\t' read -r p_path p_sess p_repo p_branch p_state p_pr p_upd <<< "$body"
cp_() {
    if [[ "$2" == "$3" ]]; then
        ok "$1 -> [$2]"
    else
        bad "$1" "got [$2] want [$3]"
    fi
}
cp_ path "$p_path" "$fh/dev/proj/.claude/worktrees/run"
cp_ session "$p_sess" "proj_feat-x"
cp_ repo "$p_repo" "proj"
cp_ branch "$p_branch" "feat/x"
cp_ state "$p_state" "implement r1 implementer"
cp_ pr "$p_pr" "-"
cp_ updated "$p_upd" "2026-09-13T02:00:00Z"

echo "── a detached worktree's row keeps its columns in place"
# HEAD at a raw sha means no branch; the empty column would collapse on the
# `read` in pipeline_map_load, which takes column 5 for the state.
mk_wt loose "0000000000000000000000000000000000000000"
mkdir -p "$fh/dev/proj/.claude/worktrees/loose/.feature"
printf '%s\n' '{"repo":"proj","branch":null,"phase":"review","round":2,"seat":"reviewer","pr":null,"updated":"2026-09-13T03:00:00Z"}' \
    > "$fh/dev/proj/.claude/worktrees/loose/.feature/status.jsonl"
HOME="$fh" PROJECT_DIRS_LOCAL=/nonexistent HQ_SNAPSHOT_DIR="$work/snapshot" \
    "$repo/bin/hq-snapshot" pipelines >/dev/null 2>&1
pipeline_map_load
got=$(pipeline_for_cwd "$fh/dev/proj/.claude/worktrees/loose")
if [[ "$got" == "review r2 reviewer" ]]; then
    ok "a detached worktree's state reads back"
else
    bad "detached worktree state" "got [$got] want [review r2 reviewer]"
fi

echo "── the record formats round-trip through a snapshot"
# A worktrees row and a prs search row both carry columns that can be empty.
# A tab is IFS whitespace, so a run of them collapses on `read`: the worktrees
# record writes "-" for an absent branch or pipeline, and the prs reader
# strips its kind prefix instead of splitting. Both are pinned here.
printf '%s\n' \
    "meta"$'\t'"gh_ok"$'\t'"true" \
    "meta"$'\t'"lsof"$'\t'"true" \
    "/repo"$'\t'"MERGED"$'\t'"-"$'\t'"no PR"$'\t'"-"$'\t'"2 days ago"$'\t'"wt"$'\t'"-"$'\t'"1789155336"$'\t'"/repo.x"$'\t'"false"$'\t'"false"$'\t'"none"$'\t'"-"$'\t'"-"$'\t'"true" \
    | snapshot_write worktrees
IFS=$'\t' read -r w_repo w_bucket w_branch w_pr w_flags w_age w_where w_pipe w_epoch w_path w_locked w_sweep \
    w_prstate w_prhead w_wthead w_merged \
    <<< "$(snapshot_read worktrees | grep -v '^meta')"
rt_() {
    if [[ "$2" == "$3" ]]; then ok "$1 -> [$2]"; else bad "$1" "got [$2] want [$3]"; fi
}
rt_ "worktrees repo"   "$w_repo"   "/repo"
rt_ "worktrees branch" "$w_branch" "-"
rt_ "worktrees pipe"   "$w_pipe"   "-"
rt_ "worktrees epoch"  "$w_epoch"  "1789155336"
rt_ "worktrees path"   "$w_path"   "/repo.x"
rt_ "worktrees sweep"  "$w_sweep"  "false"
# The four the sweep's dry run reads instead of asking git. pr_head and
# wt_head are the empty-capable ones, so they are the "-" cases here.
rt_ "worktrees pr_state"     "$w_prstate" "none"
rt_ "worktrees pr_head"      "$w_prhead"  "-"
rt_ "worktrees wt_head"      "$w_wthead"  "-"
rt_ "worktrees merged_local" "$w_merged"  "true"

# ROW_FIELDS is what makes bin/worktrees reject a snapshot whose rows are a
# different width, so it has to track the writer. Counted from the script
# rather than by running it: the producer needs a real repo set and gh.
echo "── bin/worktrees' ROW_FIELDS matches the record it writes"
rf_declared=$(grep -E '^ROW_FIELDS=' "$repo/bin/worktrees" | head -1 | cut -d= -f2)
rf_written=$(( $(grep -o "printf 'row[^']*'" "$repo/bin/worktrees" | grep -o '%s' | wc -l) + 1 ))
rt_ "ROW_FIELDS vs the row printf" "$rf_declared" "$rf_written"
rt_ "the reader reads that many"   "$rf_declared" "17"

# The prs row below has an empty reviewDecision column, which is what the
# kind-prefix strip has to survive.
prs_row="org/repo"$'\t'"7"$'\t'"false"$'\t'"MERGEABLE"$'\t'"green"$'\t'$'\t'"900"$'\t'"a title"$'\t'"https://example.invalid/7"
printf '%s\n' \
    "meta"$'\t'"author"$'\t'"@me" \
    "meta"$'\t'"since"$'\t'"2026-09-13" \
    "open"$'\t'"$prs_row" \
    | snapshot_write prs
got_row=""
while IFS= read -r line; do
    case "$line" in "open"$'\t'*) got_row="${line#open$'\t'}" ;; esac
done < <(snapshot_read prs)
rt_ "prs row survives the kind prefix" "$got_row" "$prs_row"

echo "── bin/worktrees --snapshot and bin/prs --snapshot are the producers"
# Both are what collect_worktrees/collect_prs run; asserted here by reading
# the scripts, since running them would need a real repo set and gh.
if grep -q 'bin/worktrees" --snapshot' "$repo/bin/hq-snapshot"; then
    ok "collect_worktrees runs bin/worktrees --snapshot"
else
    bad "collect_worktrees producer" "does not run bin/worktrees --snapshot"
fi
if grep -q 'bin/prs" --snapshot' "$repo/bin/hq-snapshot"; then
    ok "collect_prs runs bin/prs --snapshot"
else
    bad "collect_prs producer" "does not run bin/prs --snapshot"
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
