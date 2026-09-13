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
model=""
get_context_and_model()  { printf '1234\t%s' "$model"; }
get_totals_incremental() { printf '10\t20\t3\t-'; }
_agent_file_mtime()      { printf '1700000000'; }

echo "get_row_stats record"
rec=$(get_row_stats row "$work/t.jsonl")
check "eight columns" "$(printf '%s' "$rec" | awk -F'\t' '{print NF}')" "8"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$rec"
check "empty model is written as -"   "$mdl" "-"
check "mtime stays in its column"      "$mt"  "1700000000"
check "window stays in its column"     "$win" "0"

model="claude-opus-5"
IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "$work/t.jsonl")"
check "a model passes through"         "$mdl" "claude-opus-5"
check "mtime unchanged with a model"   "$mt"  "1700000000"

IFS=$'\t' read -r ctx tout tall turns cost mdl mt win <<< "$(get_row_stats row "")"
check "no transcript reads unknown"    "$mdl" "unknown"

echo "load_data's read of the collect record"
# The collect step prefixes cwd, cwd_ok and status; the reader maps the two
# placeholders ("-" cwd, "-" model) back to empty.
model=""
printf '%s\t%s\t%s\t%s' "-" 1 idle "$(get_row_stats row "$work/t.jsonl")" > "$work/rec"
IFS=$'\t' read -r cwd cwd_ok st ctx tout tall turns cost mdl mt win < "$work/rec"
[[ "$cwd" == "-" ]] && cwd=""
[[ "$mdl" == "-" ]] && mdl=""
check "cwd maps back to empty"         "$cwd" ""
check "model maps back to empty"       "$mdl" ""
check "status lands in its column"     "$st"  "idle"
check "window lands in its column"     "$win" "0"

echo; echo "passed $pass, failed $fail"
(( fail == 0 ))
