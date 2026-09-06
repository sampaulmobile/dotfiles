#!/usr/bin/env bash
#
# _agent_ttys_filter — the parsing half of agent_ttys — over canned
# `ps -o tty=,comm=` lines. Offline: no ps of the real machine is consulted,
# no tmux server, no agents.
#
#   tests/test-agent-ttys.sh        # or: bash tests/test-agent-ttys.sh
#
# The case that matters is a TIE: one tty owning both a codex and a node
# process must resolve to codex, or the dashboard reads a claude transcript
# for a codex pane (and finds nothing).

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

pass=0
fail=0
check() {  # <label> <want> <got>
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %-34s %s\n' "$1" "${3//$'\n'/ | }"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-34s want [%s] got [%s]\n' "$1" "${2//$'\n'/ | }" "${3//$'\n'/ | }"
        fail=$(( fail + 1 ))
    fi
}

# lookup <map-body> <tty> — the fork-free idiom every caller of
# _agent_tty_map uses, so the tie-break is asserted the way it is consumed
lookup() {
    local map=$'\n'"$1" rest
    rest="${map#*$'\n'"$2"$'\t'}"
    [[ "$rest" == "$map" ]] && return
    printf '%s' "${rest%%$'\n'*}"
}

echo "── one agent per tty"
got=$(printf 'ttys001 claude\nttys002 codex\n' | _agent_ttys_filter)
check "claude and codex"  $'ttys001\tclaude\nttys002\tcodex' "$got"
check "  lookup ttys001"  "claude" "$(lookup "$got" ttys001)"
check "  lookup ttys002"  "codex"  "$(lookup "$got" ttys002)"

echo "── a wrapper/shim shows up as node"
got=$(printf 'ttys003 node\n' | _agent_ttys_filter)
check "bare node is claude" $'ttys003\tclaude' "$got"

echo "── ties: codex wins"
# codex running an npm tool, or an npm-installed codex under a node wrapper
got=$(printf 'ttys004 node\nttys004 codex\n' | _agent_ttys_filter)
check "codex before claude"  $'ttys004\tcodex\nttys004\tclaude' "$got"
check "  lookup takes codex" "codex" "$(lookup "$got" ttys004)"
# and the same when ps happens to list them the other way round
got=$(printf 'ttys004 codex\nttys004 node\n' | _agent_ttys_filter)
check "order-independent"    "codex" "$(lookup "$got" ttys004)"

echo "── ignored rows"
got=$(printf '?? codex\n?? node\n' | _agent_ttys_filter)
check "processes with no tty" "" "$got"
got=$(printf 'ttys005 zsh\nttys006 vim\n' | _agent_ttys_filter)
check "non-agent commands"    "" "$got"
check "miss returns nothing"  "" "$(lookup $'ttys001\tclaude' ttys009)"

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
