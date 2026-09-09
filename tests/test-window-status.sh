#!/usr/bin/env bash
#
# aggregate_session_status and window_status_from_panes — the two pure folds
# over scan_agent_panes output that feed status.tsv (per session) and the
# @agent_status window option (per window). No tmux server: the pane lines
# are literal here.
#
#   tests/test-window-status.sh          # or: /bin/bash tests/test-window-status.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

pass=0
fail=0

# expect <label> <got> <want>
expect() {
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %s\n       got:  %s\n       want: %s\n' "$1" "${2//$'\n'/ | }" "${3//$'\n'/ | }"
        fail=$(( fail + 1 ))
    fi
}

T=$'\t'
# session pane window agent status
panes="app${T}%1${T}@1${T}claude${T}idle
app${T}%2${T}@1${T}claude${T}working
app${T}%3${T}@2${T}codex${T}permission
web${T}%4${T}@3${T}claude${T}idle
web${T}%5${T}@4${T}claude${T}unknown
ghost${T}%6${T}@5${T}claude${T}unknown"

echo "aggregate_session_status"
got=$(aggregate_session_status "$panes")
expect "worst status per session, pane of that status, first-seen order" "$got" \
"app${T}permission${T}%3
web${T}idle${T}%4
ghost${T}unknown${T}-"
expect "empty input -> no rows" "$(aggregate_session_status "")" ""
expect "tie: first pane with the worst status wins" \
    "$(aggregate_session_status "s${T}%7${T}@7${T}claude${T}working
s${T}%8${T}@8${T}claude${T}working")" "s${T}working${T}%7"

echo "window_status_from_panes"
got=$(window_status_from_panes "$panes" "")
expect "per window: working beats idle, permission, unknown -> idle" "$got" \
"@1${T}working
@2${T}permission
@3${T}idle
@4${T}idle
@5${T}idle"
got=$(window_status_from_panes "$panes" $'%4\n%2\n%6')
expect "done flags: idle+flag -> done, working+flag stays working" "$got" \
"@1${T}working
@2${T}permission
@3${T}done
@4${T}idle
@5${T}done"
expect "flag for a pane with no agent is ignored" \
    "$(window_status_from_panes "s${T}%1${T}@1${T}claude${T}idle" $'%9')" "@1${T}idle"
expect "pane id match is exact (%1 does not match %10)" \
    "$(window_status_from_panes "s${T}%10${T}@1${T}claude${T}idle" $'%1')" "@1${T}idle"
expect "empty input -> no rows" "$(window_status_from_panes "" "")" ""

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
