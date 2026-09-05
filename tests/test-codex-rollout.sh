#!/usr/bin/env bash
#
# The codex rollout reader (bin/tmux-claude-lib-codex) over a real — but
# scrubbed — rollout fixture: the numbers the dashboard shows for a codex
# row, and the pane -> rollout lookup that finds the file in the first
# place. No tmux server, no codex, no network.
#
#   tests/test-codex-rollout.sh

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
rollout="$here/fixtures/codex-rollout.jsonl"

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

pass=0
fail=0
check() {  # <label> <want> <got>
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %-34s %s\n' "$1" "$3"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-34s want [%s] got [%s]\n' "$1" "$2" "$3"
        fail=$(( fail + 1 ))
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not installed — skipping" >&2
    exit 0
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/codex-rollout-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

echo "── codex_get_context_and_model"
IFS=$'\t' read -r ctx mdl win <<< "$(codex_get_context_and_model "$rollout")"
# last token_count: last_token_usage.input_tokens (cached tokens are a
# SUBSET of it, so they must not be added on top), model from the last
# turn_context, window straight from the transcript
check "context (last turn input tokens)" "15647" "$ctx"
check "model" "gpt-5" "$mdl"
check "context window" "258400" "$win"

echo "── codex_get_context_and_model: missing file"
IFS=$'\t' read -r ctx mdl win <<< "$(codex_get_context_and_model "$tmp/nope.jsonl")"
check "context" "0" "$ctx"
check "model" "unknown" "$mdl"
check "window" "0" "$win"

echo "── codex_get_totals"
IFS=$'\t' read -r out all turns cost <<< "$(codex_get_totals "$rollout")"
check "cumulative output tokens" "1084" "$out"
check "cumulative total tokens" "76343" "$all"
check "turns (task_started events)" "4" "$turns"
# the fixture's plan bills credits, so rate_limits.primary is null
check "cost falls back to -" "-" "$cost"

echo "── codex_get_totals: mtime cache"
cache="$tmp/totals.cache"
first=$(codex_get_totals "$rollout" "$cache")
if [[ -f "$cache" ]]; then
    printf '  ok   %-34s\n' "cache file written"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %-34s\n' "cache file written"
    fail=$(( fail + 1 ))
fi
second=$(codex_get_totals "$rollout" "$cache")
check "cached result matches" "$first" "$second"

echo "── codex_get_totals: missing file"
check "missing rollout" "$(printf '0\t0\t0\t-')" "$(codex_get_totals "$tmp/nope.jsonl")"

echo "── codex_get_totals: rate limit in COST"
# same shape as the real record, with a populated primary window
{
    printf '{"type":"event_msg","payload":{"type":"task_started"}}\n'
    printf '{"type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"output_tokens":10,"total_tokens":100}},"rate_limits":{"primary":{"used_percent":42.7,"window_minutes":300}}}}\n'
} > "$tmp/rl.jsonl"
IFS=$'\t' read -r out all turns cost <<< "$(codex_get_totals "$tmp/rl.jsonl")"
check "rate-limit window in COST" "5h:42%" "$cost"

echo "── codex_find_pane_jsonl"
CODEX_MAP_DIR="$tmp/map"
mkdir -p "$CODEX_MAP_DIR"
printf '%s\t%s\t%s\n' "sess-id" "$rollout" "/home/u/dev/proj" > "$CODEX_MAP_DIR/42.tsv"
check "map hit (bare pane id)" "$rollout" "$(codex_find_pane_jsonl 42)"
check "map hit (%-prefixed)"   "$rollout" "$(codex_find_pane_jsonl %42)"

printf '%s\t%s\t%s\n' "sess-id" "$tmp/gone.jsonl" "/home/u/dev/proj" > "$CODEX_MAP_DIR/43.tsv"
# A stale entry (rollout deleted) must never be returned: the lookup falls
# through to the cwd scan, which finds nothing here. Point the scan at an
# empty dir so the test can't pick up a real rollout from this machine.
CODEX_SESSIONS_DIR="$tmp/empty-sessions"
mkdir -p "$CODEX_SESSIONS_DIR"
check "stale map entry ignored" "" "$(codex_find_pane_jsonl 43 2>/dev/null)"

echo "── _codex_newest_rollout_for_cwd"
CODEX_SESSIONS_DIR="$tmp/sessions/2026/09/05"
mkdir -p "$CODEX_SESSIONS_DIR"
CODEX_SESSIONS_DIR="$tmp/sessions"
cp "$rollout" "$tmp/sessions/2026/09/05/rollout-2026-09-05T12-00-00-aaaa.jsonl"
check "matches on session_meta cwd" \
    "$tmp/sessions/2026/09/05/rollout-2026-09-05T12-00-00-aaaa.jsonl" \
    "$(_codex_newest_rollout_for_cwd /home/u/dev/proj)"
check "no match for another cwd" "" "$(_codex_newest_rollout_for_cwd /home/u/dev/other)"

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
