#!/usr/bin/env bash
#
# bin/claude-settings-check reports what a live settings.json lacks relative
# to its .example. This runs it over fixture pairs: a live file that differs
# only in ways that are NOT drift (key order, scalar values, local extras)
# must be clean; one missing a hook, an allowlist entry and a nested key must
# name exactly those. Nothing outside the fixtures is read.
#
#   tests/test-settings-check.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
check="$repo/bin/claude-settings-check"
fx="$here/fixtures"

work=$(mktemp -d "${TMPDIR:-/tmp}/settings-check-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad()  { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

# run <live> <example> -> sets $out and $rc
run() {
    out=$("$check" "$1" "$2" 2>&1)
    rc=$?
}

# expect_rc <label> <want-rc>
expect_rc() {
    if [[ "$rc" == "$2" ]]; then ok "$1 (rc=$2)"; else bad "$1" "want rc=$2, got rc=$rc: $out"; fi
}
# expect_line <label> <substring that must appear on some output line>
expect_line() {
    if grep -qF -- "$2" <<< "$out"; then ok "$1"; else bad "$1" "no line containing [$2] in: $out"; fi
}
# expect_no_line <label> <substring that must NOT appear>
expect_no_line() {
    if grep -qF -- "$2" <<< "$out"; then bad "$1" "unexpected [$2] in: $out"; else ok "$1"; fi
}

echo "clean live file: reordered keys, different scalar values, local extras"
run "$fx/settings-live-clean.json" "$fx/settings-example.json"
expect_rc   "exits 0" 0
if [[ -z "$out" ]]; then ok "prints nothing"; else bad "prints nothing" "got: $out"; fi

echo "gappy live file"
run "$fx/settings-live-gappy.json" "$fx/settings-example.json"
expect_rc      "exits 1" 1
expect_line    "header counts the gaps"            "is missing 5 entries present in settings-example.json"
expect_line    "hook with a different command"     "hooks.PreToolUse       matcher=Bash command=~/dotfiles/bin/claude-guard-pipe-truncate"
expect_line    "allowlist entry"                   "permissions.allow      Bash(uv tree:*)"
expect_line    "nested scalar key"                 "voice.enabled"
expect_line    "whole missing object"              "statusLine.type"
expect_no_line "present hook is not reported"      "flag-done"
expect_no_line "differing scalar value is not drift" "effortLevel"
expect_no_line "local-only entries are not drift"  "git push"

echo "unusable inputs"
run "$work/nope.json" "$fx/settings-example.json"
expect_rc   "missing live file exits 2" 2
expect_line "and says so" "no live file"
printf '{"broken": \n' > "$work/broken.json"
run "$work/broken.json" "$fx/settings-example.json"
expect_rc   "invalid JSON exits 2" 2
expect_line "and says so" "not valid JSON"

echo "identical files"
run "$fx/settings-example.json" "$fx/settings-example.json"
expect_rc "exits 0" 0

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
