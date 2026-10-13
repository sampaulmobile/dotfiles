#!/usr/bin/env bash
#
# aggregate_session_status, window_status_from_panes and drop_deferred_flags
# — the pure folds over scan_agent_panes output that feed the snapshot's
# sessions source (per session), the @agent_status window option (per
# window) and the attention layer's read-time flag deferral. Also
# live_agent_counts, over a throwaway CLAUDE_SESSIONS_DIR/CLAUDE_PROJECTS_DIR
# fixture tree (mktemp -d, removed on exit) — no tmux server anywhere, and
# the pane lines fed to the pure folds are literal here.
#
#   tests/test-window-status.sh          # or: /bin/bash tests/test-window-status.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/window-status-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

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
# session pane window agent status agents
panes="app${T}%1${T}@1${T}claude${T}idle${T}-
app${T}%2${T}@1${T}claude${T}working${T}-
app${T}%3${T}@2${T}codex${T}permission${T}-
web${T}%4${T}@3${T}claude${T}idle${T}-
web${T}%5${T}@4${T}claude${T}unknown${T}-
ghost${T}%6${T}@5${T}claude${T}unknown${T}-"

echo "aggregate_session_status"
got=$(aggregate_session_status "$panes")
expect "worst status per session, pane of that status, agents - when 0" "$got" \
"app${T}permission${T}%3${T}-
web${T}idle${T}%4${T}-
ghost${T}unknown${T}-${T}-"
expect "empty input -> no rows" "$(aggregate_session_status "")" ""
expect "tie: first pane with the worst status wins" \
    "$(aggregate_session_status "s${T}%7${T}@7${T}claude${T}working${T}-
s${T}%8${T}@8${T}claude${T}working${T}-")" "s${T}working${T}%7${T}-"
expect "agents sum across the session's panes, status/pane unaffected" \
    "$(aggregate_session_status "s${T}%7${T}@7${T}claude${T}idle${T}2
s${T}%8${T}@8${T}claude${T}idle${T}3")" "s${T}idle${T}%7${T}5"
expect "a codex pane's \"-\" agents contributes nothing to the sum" \
    "$(aggregate_session_status "s${T}%7${T}@7${T}codex${T}idle${T}-
s${T}%8${T}@8${T}claude${T}idle${T}4")" "s${T}idle${T}%7${T}4"

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
    "$(window_status_from_panes "s${T}%1${T}@1${T}claude${T}idle${T}-" $'%9')" "@1${T}idle"
expect "pane id match is exact (%1 does not match %10)" \
    "$(window_status_from_panes "s${T}%10${T}@1${T}claude${T}idle${T}-" $'%1')" "@1${T}idle"
expect "empty input -> no rows" "$(window_status_from_panes "" "")" ""
expect "idle + live agents -> working" \
    "$(window_status_from_panes "s${T}%1${T}@1${T}claude${T}idle${T}2" "")" "@1${T}working"
expect "unknown + live agents -> working" \
    "$(window_status_from_panes "s${T}%1${T}@1${T}claude${T}unknown${T}1" "")" "@1${T}working"
expect "permission still wins over live agents on the same pane" \
    "$(window_status_from_panes "s${T}%1${T}@1${T}claude${T}permission${T}2" "")" "@1${T}permission"

echo "drop_deferred_flags"
flags="sess${T}%1
sess${T}%2"
dpanes="sess${T}%1${T}@1${T}claude${T}idle${T}-
sess${T}%2${T}@2${T}claude${T}idle${T}3"
expect "a flag on an agent-free pane survives; one on a live-agent pane is dropped" \
    "$(drop_deferred_flags "$flags" "$dpanes")" "sess${T}%1"
expect "empty flags -> nothing, no fork of the pane lookup" \
    "$(drop_deferred_flags "" "$dpanes")" ""
expect "stale/empty panes body -> fail open, every flag survives" \
    "$(drop_deferred_flags "$flags" "")" "$flags"

echo "live_agent_counts"
export CLAUDE_SESSIONS_DIR="$work/sessions"
export CLAUDE_PROJECTS_DIR="$work/projects"
mkdir -p "$CLAUDE_SESSIONS_DIR"
proj_dir="$CLAUDE_PROJECTS_DIR/-work-proj"
mkdir -p "$proj_dir/sid1/subagents"
cat > "$CLAUDE_SESSIONS_DIR/s1.json" <<EOF
{"tmux":"sess:@1.%1","cwd":"/work/proj","sessionId":"sid1"}
EOF

touch "$proj_dir/sid1/subagents/agent-fresh.jsonl"
touch "$proj_dir/sid1/subagents/agent-fresh.meta.json"

touch "$proj_dir/sid1/subagents/agent-nometa.jsonl"
# no .meta.json for this one

touch "$proj_dir/sid1/subagents/agent-old.jsonl"
touch "$proj_dir/sid1/subagents/agent-old.meta.json"
touch -t "$(date -v-10M +%Y%m%d%H%M.%S 2>/dev/null || date -d '10 minutes ago' +%Y%m%d%H%M.%S)" \
    "$proj_dir/sid1/subagents/agent-old.jsonl"

live_agent_counts $'%1'
expect "fresh agent with meta.json counts; no meta and 10m-old do not" "$LIVE_AGENTS_OUT" $'\n%1\t1\n'

live_agent_counts $'%9'
expect "a pane with no session-JSON entry gets nothing" "$LIVE_AGENTS_OUT" $'\n'

live_agent_counts ""
expect "empty pane-id input -> nothing, zero forks" "$LIVE_AGENTS_OUT" $'\n'

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
