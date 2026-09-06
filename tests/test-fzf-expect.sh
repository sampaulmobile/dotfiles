#!/usr/bin/env bash
#
# parse_fzf_expect over the output shapes fzf --expect can produce. Offline:
# it SOURCES bin/tmux-sessionizer, which hands back the helper and stops
# before the picker (the BASH_SOURCE guard near the top of that file), so no
# fzf and no tmux server are involved.
#
#   tests/test-fzf-expect.sh        # or: bash tests/test-fzf-expect.sh
#
# The case that matters: an accept on a query matching NO row makes fzf print
# only the key line, which must read as "nothing was selected" and not as a
# project literally named `ctrl-x`.

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/tmux-sessionizer"

pass=0
fail=0

# expect <label> <fzf-output> <want-status> <want-key> <want-selected>
expect() {
    local label="$1" out="$2" want_rc="$3" want_key="$4" want_sel="$5"
    local rc=0
    fzf_key="unset" selected="unset"
    parse_fzf_expect "$out" || rc=$?
    if [[ "$rc" == "$want_rc" && "$fzf_key" == "$want_key" && "$selected" == "$want_sel" ]]; then
        printf '  ok   %-30s rc=%s key=[%s] selected=[%s]\n' \
            "$label" "$rc" "$fzf_key" "$selected"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-30s rc=%s key=[%s] selected=[%s] (want rc=%s key=[%s] selected=[%s])\n' \
            "$label" "$rc" "$fzf_key" "$selected" "$want_rc" "$want_key" "$want_sel"
        fail=$(( fail + 1 ))
    fi
}

# `$(...)` strips trailing newlines, so these are exactly what the sessionizer
# sees in $fzf_out.
echo "── nothing accepted (must exit the picker, never build a session)"
expect "esc / ctrl-c"          ""              1 "" ""
expect "enter, no match"       ""              1 "" ""
expect "ctrl-x, no match"      "ctrl-x"        1 "" ""
expect "alt-enter, no match"   "alt-enter"     1 "" ""

echo "── a row was accepted"
# a dir row is a ~-shortened display path (literal tilde, re-expanded by the
# caller); a session row is a bare session name
# shellcheck disable=SC2088  # the tilde is data here, not a path to expand
dir_row='~/dev/proj'
expect "enter"                 $'\n'"$dir_row"         0 ""          "$dir_row"
expect "ctrl-x"                $'ctrl-x\n'"$dir_row"   0 "ctrl-x"    "$dir_row"
expect "alt-enter"             $'alt-enter\nsessname'  0 "alt-enter" "sessname"

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
