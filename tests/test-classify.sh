#!/usr/bin/env bash
#
# classify_pane_status over the captured pane fixtures — one case per
# (agent, state) the attention layer has to tell apart. No tmux server, no
# network, no agent processes: it sources bin/tmux-claude-lib and feeds it
# text, so it is safe to run anywhere.
#
#   tests/test-classify.sh          # or: bash tests/test-classify.sh
#
# Run it with /bin/bash too (macOS ships bash 3.2, which the library must
# keep working on).

# No `set -u`: the library is sourced by scripts that don't use it, and an
# all-blank capture leaves the classifier's line array unset on purpose
# (bash 3.2 `read -a` with no words) — it degrades to "unknown", which is
# what the tests below assert.
set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
fixtures="$here/fixtures"

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

pass=0
fail=0

# expect <fixture> <agent> <expected-status>
expect() {
    local file="$fixtures/$1" agent="$2" want="$3" got
    if [[ ! -f "$file" ]]; then
        printf '  FAIL %-28s missing fixture\n' "$1"
        fail=$(( fail + 1 ))
        return
    fi
    got=$(classify_pane_status "$(cat "$file")" "$agent")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-28s %-6s -> %s\n' "$1" "$agent" "$got"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-28s %-6s -> %s (want %s)\n' "$1" "$agent" "$got" "$want"
        fail=$(( fail + 1 ))
    fi
}

# expect_text <label> <text> <agent> <expected-status>
expect_text() {
    local label="$1" text="$2" agent="$3" want="$4" got
    got=$(classify_pane_status "$text" "$agent")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-28s %-6s -> %s\n' "$label" "$agent" "$got"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-28s %-6s -> %s (want %s)\n' "$label" "$agent" "$got" "$want"
        fail=$(( fail + 1 ))
    fi
}

echo "── claude"
expect claude-idle.txt            claude idle
expect claude-working.txt         claude working
expect claude-permission.txt      claude permission
expect claude-plan-permission.txt claude permission

echo "── claude: the agent argument is optional (every pre-existing caller)"
got=$(classify_pane_status "$(cat "$fixtures/claude-permission.txt")")
if [[ "$got" == "permission" ]]; then
    printf '  ok   %-28s %-6s -> %s\n' "no-agent-arg" "-" "$got"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %-28s %-6s -> %s (want permission)\n' "no-agent-arg" "-" "$got"
    fail=$(( fail + 1 ))
fi

echo "── codex"
expect codex-idle.txt        codex idle
expect codex-working.txt     codex working
expect codex-permission.txt  codex permission
expect codex-dir-trust.txt   codex permission
expect codex-hook-trust.txt  codex permission

echo "── empty / junk input"
expect_text "empty string"   ""                  claude unknown
expect_text "empty string"   ""                  codex  unknown
expect_text "blank lines"    $'\n\n\n'           claude unknown
expect_text "blank lines"    $'\n\n\n'           codex  unknown
expect_text "unrelated text" $'$ ls -la\ntotal 8' claude unknown
expect_text "unrelated text" $'$ ls -la\ntotal 8' codex  unknown

echo "── codex: a quoted approval header must not read as a prompt"
# the overlay's "Yes, " option list is the other half of the test; prose
# mentioning the header alone is just an agent talking about approvals
expect_text "header without options" \
    $'• The overlay reads "Would you like to run the following command?".\n\n› Ask Codex to do anything' \
    codex idle

echo "── codex: only the last 10 non-blank lines count"
# an old approval, long since answered, scrolled out of the window
expect_text "stale approval scrolled off" \
    "$(printf 'Would you like to run the following command?\n› 1. Yes, proceed (y)\n%s\n› Ask Codex to do anything' \
        "$(for i in 1 2 3 4 5 6 7 8 9 10 11 12; do echo "• line $i"; done)")" \
    codex idle

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
