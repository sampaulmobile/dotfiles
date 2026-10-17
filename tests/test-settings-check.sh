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

# run_apply <live> <example> -> sets $out and $rc; mutates <live> in place
run_apply() {
    out=$("$check" --apply "$1" "$2" 2>&1)
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
# expect_eq <label> <actual> <expected>
expect_eq() {
    if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1" "got $2"; fi
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
expect_no_line "present hook is not reported"      "deck hook done"
expect_no_line "differing scalar value is not drift" "effortLevel"
expect_no_line "local-only entries are not drift"  "git push"
expect_line    "names the fix"                     "fix: bin/claude-settings-check --apply"

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

echo "--apply: adds the gappy fixture's 5 gaps"
cp "$fx/settings-live-gappy.json" "$work/apply-live.json"
run_apply "$work/apply-live.json" "$fx/settings-example.json"
expect_rc   "exits 0" 0
expect_line "reports hook added"        "hooks.PreToolUse"
expect_line "reports permissions added" "Bash(uv tree:*)"
expect_line "reports voice.enabled added" "voice.enabled"
expect_line "reports statusLine.type added" "statusLine.type"
expect_line "reports statusLine.command added" "statusLine.command"
expect_line "prints a backup path" "backup:"

run "$work/apply-live.json" "$fx/settings-example.json"
expect_rc "a re-run of the check finds no gaps" 0
if [[ -z "$out" ]]; then ok "re-check prints nothing"; else bad "re-check prints nothing" "got: $out"; fi

bak_count=$(find "$work" -maxdepth 1 -name 'apply-live.json.bak.*' | wc -l | tr -d ' ')
expect_eq "exactly one backup written" "$bak_count" 1
bak_file=$(find "$work" -maxdepth 1 -name 'apply-live.json.bak.*')
if cmp -s "$bak_file" "$fx/settings-live-gappy.json"; then
    ok "backup is byte-identical to the pre-apply file"
else
    bad "backup is byte-identical to the pre-apply file" "differs"
fi

run_apply "$work/apply-live.json" "$fx/settings-example.json"
expect_rc "second apply exits 0" 0
if [[ -z "$out" ]]; then ok "second apply adds nothing"; else bad "second apply adds nothing" "got: $out"; fi
bak_count2=$(find "$work" -maxdepth 1 -name 'apply-live.json.bak.*' | wc -l | tr -d ' ')
expect_eq "second apply writes no second backup" "$bak_count2" 1

echo "--apply: hook joins its existing matcher group"
pretool=$(jq '.hooks.PreToolUse' "$work/apply-live.json")
grp_count=$(jq 'length' <<< "$pretool")
expect_eq "PreToolUse still has one matcher group" "$grp_count" 1
first_cmd=$(jq -r '.[0].hooks[0].command' <<< "$pretool")
if [[ "$first_cmd" == *some-other-guard ]]; then ok "pre-existing hook is still first"; else bad "pre-existing hook is still first" "got $first_cmd"; fi
second_cmd=$(jq -r '.[0].hooks[1].command' <<< "$pretool")
if [[ "$second_cmd" == *claude-guard-pipe-truncate ]]; then ok "new hook appended to the group"; else bad "new hook appended to the group" "got $second_cmd"; fi

echo "--apply: hook with a new matcher appends the whole group"
cp "$fx/settings-live-gappy.json" "$work/newmatcher-live.json"
jq '.hooks.PreToolUse += [{"matcher":"Write","hooks":[{"type":"command","command":"~/dotfiles/bin/some-write-guard"}]}]' \
    "$fx/settings-example.json" > "$work/newmatcher-example.json"
run_apply "$work/newmatcher-live.json" "$work/newmatcher-example.json"
expect_rc   "exits 0" 0
expect_line "reports the new matcher" "matcher=Write"
last_matcher=$(jq -r '.hooks.PreToolUse[-1].matcher' "$work/newmatcher-live.json")
expect_eq "new group appended at the end of the event array" "$last_matcher" "Write"

echo "--apply: permissions entry appended, existing order intact"
allow=$(jq '.permissions.allow' "$work/apply-live.json")
expect_eq "first allow entry unchanged" "$(jq -r '.[0]' <<< "$allow")" "Bash(git status:*)"
expect_eq "second allow entry unchanged" "$(jq -r '.[1]' <<< "$allow")" "Bash(git push:*)"
expect_eq "new allow entry appended last" "$(jq -r '.[-1]' <<< "$allow")" "Bash(uv tree:*)"

echo "--apply: scalar keys added"
expect_eq "voice.enabled added" "$(jq -r '.voice.enabled' "$work/apply-live.json")" "true"
expect_eq "statusLine.type added" "$(jq -r '.statusLine.type' "$work/apply-live.json")" "command"

echo "--apply: live-only keys and differing values preserved untouched"
preserved=$(jq -n --slurpfile before "$fx/settings-live-gappy.json" \
                    --slurpfile after "$work/apply-live.json" '
  ($before[0]) as $b | ($after[0]) as $a |
  [$b | paths(scalars)] as $leafpaths |
  [ $leafpaths[] | . as $p | select( ($b|getpath($p)) != ($a|getpath($p)) ) | $p ] as $changed |
  $changed == []
')
expect_eq "every pre-existing leaf keeps its value" "$preserved" "true"
expect_eq "live-only model key preserved" "$(jq -r '.model' "$work/apply-live.json")" "opus[1m]"
expect_eq "differing effortLevel preserved" "$(jq -r '.effortLevel' "$work/apply-live.json")" "medium"

echo "--apply: symlink target gains the entries, link stays a link"
cp "$fx/settings-live-gappy.json" "$work/sym-real.json"
ln -s sym-real.json "$work/sym-link.json"
run_apply "$work/sym-link.json" "$fx/settings-example.json"
expect_rc "exits 0" 0
if [[ -L "$work/sym-link.json" && "$(readlink "$work/sym-link.json")" == "sym-real.json" ]]; then
    ok "link is still a symlink to the same target"
else
    bad "link is still a symlink to the same target" "$(ls -l "$work/sym-link.json")"
fi
run "$work/sym-real.json" "$fx/settings-example.json"
expect_rc "target gained the entries (check via the real file)" 0

echo "--apply: non-JSON live file refused, file and disk state unchanged"
printf '{"broken": \n' > "$work/broken-apply.json"
cp "$work/broken-apply.json" "$work/broken-apply.json.orig"
run_apply "$work/broken-apply.json" "$fx/settings-example.json"
expect_rc "exits nonzero" 2
if cmp -s "$work/broken-apply.json" "$work/broken-apply.json.orig"; then
    ok "file byte-identical"
else
    bad "file byte-identical" "changed"
fi
stray=$(find "$work" -maxdepth 1 \( -name 'broken-apply.json.bak.*' -o -name 'broken-apply.json.tmp.*' \) | wc -l | tr -d ' ')
expect_eq "no backup or tmp file left" "$stray" 0

echo "--apply: wrong-shape conflict refused, file unchanged"
jq '.voice = "oops"' "$fx/settings-live-gappy.json" > "$work/wrongshape-live.json"
cp "$work/wrongshape-live.json" "$work/wrongshape-live.json.orig"
run_apply "$work/wrongshape-live.json" "$fx/settings-example.json"
expect_rc "exits nonzero" 1
if cmp -s "$work/wrongshape-live.json" "$work/wrongshape-live.json.orig"; then
    ok "file byte-identical"
else
    bad "file byte-identical" "changed"
fi
stray2=$(find "$work" -maxdepth 1 \( -name 'wrongshape-live.json.bak.*' -o -name 'wrongshape-live.json.tmp.*' \) | wc -l | tr -d ' ')
expect_eq "no backup or tmp file left" "$stray2" 0

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
