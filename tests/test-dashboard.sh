#!/usr/bin/env bash
#
# get_row_stats — the per-row record bin/tmux-claude-dashboard's collect
# step writes and load_data reads back with one `read`. A tab is IFS
# whitespace, so a run of them collapses on `read`: an empty model column
# would shift mtime and window left. Offline: it SOURCES the dashboard, which
# hands back its helpers and stops before the TUI (the BASH_SOURCE guard
# before the main loop), with the transcript readers stubbed here, so no
# tmux server, no transcript and no cache outside a mktemp dir is touched.
#
#   tests/test-dashboard.sh          # or: /bin/bash tests/test-dashboard.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/dashboard-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
export DASHBOARD_CACHE_DIR="$work/cache"

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-dashboard"

pass=0; fail=0
check() {
    local label="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-40s [%s]\n' "$label" "$got"; pass=$((pass + 1))
    else
        printf '  FAIL %-40s got [%s] want [%s]\n' "$label" "$got" "$want"; fail=$((fail + 1))
    fi
}

# The transcript readers are the lib's; only the record shape is under test.
# Each reader call is counted, so a cache hit shows as no new reads.
model=""
reads="$work/reads"
stub_key="1700000000 100"
get_context_and_model()  { echo x >> "$reads"; printf '1234\t%s' "$model"; }
get_totals_incremental() { printf '10\t20\t3\t-'; }
_row_key()               { [[ -n "$1" ]] && printf '%s' "$stub_key"; }
nreads() { if [[ -f "$reads" ]]; then wc -l < "$reads" | tr -d ' '; else echo 0; fi; }

echo "get_row_stats record"
rec=$(get_row_stats row "$work/t.jsonl")
check "eight columns" "$(printf '%s' "$rec" | awk -F'\t' '{print NF}')" "8"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$rec"
check "empty model is written as -"   "$mdl" "-"
check "mtime stays in its column"      "$mt"  "1700000000"
check "window stays in its column"     "$win" "0"

model="claude-opus-5"
stub_key="1700000000 200"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "$work/t.jsonl")"
check "a model passes through"         "$mdl" "claude-opus-5"
check "mtime unchanged with a model"   "$mt"  "1700000000"

echo "get_row_stats row cache"
before=$(nreads)
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "$work/t.jsonl")"
check "same mtime+size reads nothing"  "$(( $(nreads) - before ))" "0"
check "a hit returns the cached line"  "$mdl" "claude-opus-5"
model="claude-sonnet-5"; stub_key="1700000000 300"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "$work/t.jsonl")"
check "a grown transcript re-reads"    "$(( $(nreads) - before ))" "1"
check "a re-read returns the new line" "$mdl" "claude-sonnet-5"
model="claude-haiku-4-5"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(skip_row_cache=1 get_row_stats row "$work/t.jsonl")"
check "skip_row_cache re-reads"        "$mdl" "claude-haiku-4-5"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "$work/t.jsonl")"
check "and rewrites the cache"         "$mdl" "claude-haiku-4-5"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats other "$work/t.jsonl")"
check "rows never share a cache"       "$(( $(nreads) - before ))" "3"

IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "")"
check "no transcript reads unknown"    "$mdl" "unknown"

echo "load_data's read of the collect record"
# The collect step prefixes cwd, cwd_ok and status; the reader maps the two
# placeholders ("-" cwd, "-" model) back to empty.
model=""; stub_key="1700000000 400"
printf '%s\t%s\t%s\t%s' "-" 1 idle "$(get_row_stats row "$work/t.jsonl")" > "$work/rec"
IFS=$'\t' read -r cwd cwd_ok st ctx tout tall turns cost mdl mt win < "$work/rec"
[[ "$cwd" == "-" ]] && cwd=""
[[ "$mdl" == "-" ]] && mdl=""
check "cwd maps back to empty"         "$cwd" ""
check "model maps back to empty"       "$mdl" ""
check "status lands in its column"     "$st"  "idle"
check "window lands in its column"     "$win" "0"

echo "plan_kill: session whole only when every row of it is in the batch"
sessions=(a a b c); panes=(%1 %2 %3 %4)
plan_kill 0;     check "one of two rows: its pane"        "${kill_sessions[*]}|${kill_panes[*]}" "|%1"
plan_kill 0 1;   check "both rows: the session"           "${kill_sessions[*]}|${kill_panes[*]}" "a|"
plan_kill 2;     check "only row: the session"            "${kill_sessions[*]}|${kill_panes[*]}" "b|"
plan_kill 1 2 3; check "mixed batch"                      "${kill_sessions[*]}|${kill_panes[*]}" "b c|%2"
panes=(%1 "" %3 %4)
plan_kill 1;     check "empty target refuses"             "$?|${kill_error:+err}" "1|err"

echo "marks follow pane ids"
sessions=(a b c); panes=(%1 %2 %3); marked=" "
toggle_mark %2; toggle_mark %3; toggle_mark %2
check "toggle twice unmarks"           "$marked" " %3 "
is_marked %1 && r=yes || r=no; check "unmarked pane" "$r" "no"
panes=(%1 %5); prune_marks
check "a gone pane's mark is pruned"   "$marked" " "

echo; echo "passed $pass, failed $fail"
(( fail == 0 ))
