#!/usr/bin/env bash
#
# bin/tmux-claude-notify speaks two hook schemas — Claude Code's
# Notification payload and codex's PermissionRequest payload. This feeds it
# both and checks the message and title it would show, with `osascript`
# shadowed by a stub so nothing actually notifies.
#
#   tests/test-notify.sh

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

stub_dir=$(mktemp -d "${TMPDIR:-/tmp}/notify-test.XXXXXX")
trap 'rm -rf "$stub_dir"' EXIT
cat > "$stub_dir/osascript" <<'STUB'
#!/bin/bash
# print the AppleScript we were asked to run instead of running it
printf '%s\n' "$2"
STUB
chmod +x "$stub_dir/osascript"

pass=0
fail=0

# expect <label> <payload> <expected-osascript-line>
expect() {
    local label="$1" payload="$2" want="$3" got
    got=$(PATH="$stub_dir:$PATH" bash -c \
        'printf "%s" "$1" | "$2" 2>/dev/null; wait' _ "$payload" "$repo/bin/tmux-claude-notify")
    got="${got//$'\n'/ }"
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %s\n' "$label"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %s\n       want: %s\n       got:  %s\n' "$label" "$want" "$got"
        fail=$(( fail + 1 ))
    fi
}

expect "claude permission prompt" \
    '{"hook_event_name":"Notification","notification_type":"permission_prompt","cwd":"/home/u/dev/proj"}' \
    'display notification "proj needs permission" with title "Claude Code"'

expect "claude idle prompt" \
    '{"notification_type":"idle_prompt","cwd":"/home/u/dev/proj"}' \
    'display notification "proj is waiting for input" with title "Claude Code"'

# the field order matters: codex sends no notification_type, and an empty
# leading field is exactly what a tab-split `read` would swallow
expect "codex permission request" \
    '{"hook_event_name":"PermissionRequest","cwd":"/home/u/dev/proj","tool_name":"Bash","tool_input":{"command":"ls"}}' \
    'display notification "proj needs permission" with title "Codex"'

expect "codex other event" \
    '{"hook_event_name":"Stop","cwd":"/home/u/dev/proj"}' \
    'display notification "proj needs attention" with title "Codex"'

expect "unparseable payload" \
    'not json at all' \
    'display notification " needs attention" with title "Claude Code"'

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
