#!/usr/bin/env bash
#
# get_agent_snippet (bin/tmux-claude-lib): the one-line "what is this agent
# doing" under a subagent row. Narration wins over a tool call, the fallback
# reads "→ Tool: arg", the result is flat and at most maxlen chars — and a
# long narration must not stall the dashboard (the flatten used to run in
# bash, whose ${var//} is quadratic on long strings under bash 3.2).
# Transcripts are generated here; no tmux, no agent, no network.
#
#   tests/test-agent-snippet.sh

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

pass=0
fail=0
check() {  # <label> <want> <got>
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %-40s %s\n' "$1" "${3:0:60}"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-40s want [%s] got [%s]\n' "$1" "$2" "$3"
        fail=$(( fail + 1 ))
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not installed — skipping" >&2
    exit 0
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-snippet-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# assistant <file> <content-json>: appends one assistant record
assistant() {
    printf '{"type":"assistant","message":{"role":"assistant","content":%s}}\n' "$2" >> "$1"
}

echo "── narration"
f="$tmp/narration.jsonl"
assistant "$f" '[{"type":"tool_use","name":"Read","input":{"file_path":"/a/b/old.py"}}]'
assistant "$f" '[{"type":"text","text":"line one\nline\ttwo\r\n\u0007bell"}]'
check "newest text wins, flattened" "line one line two  bell" "$(get_agent_snippet "$f" 60)"
check "truncation keeps maxlen-1 + ellipsis" "line…" "$(get_agent_snippet "$f" 5)"

echo "── tool_use fallback"
f="$tmp/tool.jsonl"
assistant "$f" '[{"type":"text","text":""}]'
assistant "$f" '[{"type":"tool_use","name":"Bash","input":{"command":"ls /a/b\necho x","description":"list"}}]'
check "first line of command" "→ Bash: ls /a/b" "$(get_agent_snippet "$f" 60)"
f="$tmp/path.jsonl"
assistant "$f" '[{"type":"tool_use","name":"Read","input":{"file_path":"/a/b/thing.py"}}]'
check "path-like arg is basenamed" "→ Read: thing.py" "$(get_agent_snippet "$f" 60)"
f="$tmp/url.jsonl"
assistant "$f" '[{"type":"tool_use","name":"WebFetch","input":{"url":"https://x.test/a/b"}}]'
check "URL is not basenamed" "→ WebFetch: https://x.test/a/b" "$(get_agent_snippet "$f" 60)"
f="$tmp/mcp.jsonl"
assistant "$f" '[{"type":"tool_use","name":"mcp__x__thing","input":{"n":3,"label":"hello"}}]'
check "unknown tool: first string input" "→ mcp__x__thing: hello" "$(get_agent_snippet "$f" 60)"

echo "── nothing yet"
f="$tmp/empty.jsonl"
: > "$f"
check "empty transcript" "" "$(get_agent_snippet "$f" 60)"
check "missing file" "" "$(get_agent_snippet "$tmp/nope.jsonl" 60)"

echo "── mtime cache"
f="$tmp/cached.jsonl"
assistant "$f" '[{"type":"text","text":"first"}]'
cache="$tmp/snippet.cache"
check "computed" "first" "$(get_agent_snippet "$f" 60 "$cache")"
if [[ -f "$cache" ]]; then
    printf '  ok   %-40s\n' "cache file written"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %-40s\n' "cache file written"
    fail=$(( fail + 1 ))
fi
check "cache hit" "first" "$(get_agent_snippet "$f" 60 "$cache")"

echo "── long multi-line narration (multibyte)"
# 40KB of short lines with non-ASCII in every one — the shape of a subagent's
# final report. Old bash-side flatten: ~15s+ under bash 3.2; must be instant.
f="$tmp/long.jsonl"
line='résumé of a finding — with an arrow → and a bullet •\n'
text=""
for _ in $(seq 1 800); do text+="$line"; done
assistant "$f" "[{\"type\":\"text\",\"text\":\"${text}\"}]"
start=$SECONDS
got=$(get_agent_snippet "$f" 300)
elapsed=$(( SECONDS - start ))
check "flattened to 300 chars" "300" "$(printf '%s' "$got" | wc -m | tr -d ' ')"
check "ends with ellipsis" "…" "${got: -1}"
case "$got" in
    *$'\n'*|*$'\t'*) check "no newline/tab survives" "flat" "has control chars" ;;
    *) check "no newline/tab survives" "flat" "flat" ;;
esac
if (( elapsed < 5 )); then
    printf '  ok   %-40s %ss\n' "40KB narration under 5s" "$elapsed"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %-40s %ss\n' "40KB narration under 5s" "$elapsed"
    fail=$(( fail + 1 ))
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
