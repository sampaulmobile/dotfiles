#!/usr/bin/env bash
#
# tests/check-prose-only.sh against a throwaway git repo: a comment-only
# edit must pass, a code edit must fail, and an end-of-line comment edit
# must fail (full-line stripping only — that is the documented bar).
#
#   tests/test-check-prose-only.sh
#
# Offline: everything happens inside a mktemp git repo, no network, no tmux,
# and the dotfiles checkout is never read or written.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
check="$here/check-prose-only.sh"

pass=0
fail=0

tmp=$(mktemp -d "${TMPDIR:-/tmp}/test-check-prose-only.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT

fixture="$tmp/repo"
mkdir -p "$fixture/bin"
git -C "$fixture" init -q 2>/dev/null || { echo "git init failed"; exit 1; }
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name "prose test"

write_baseline() {
    cat > "$fixture/bin/example" <<'BASELINE'
#!/usr/bin/env bash
# a full-line comment
greet() {
    echo "hello"   # trailing comment
}
greet
BASELINE
}

write_baseline
git -C "$fixture" add bin/example
git -C "$fixture" commit -qm baseline
base=$(git -C "$fixture" rev-parse HEAD)

# expect_ <label> <want-exit> — runs the check over the fixture's worktree.
expect_() {
    local label="$1" want="$2" out got
    out=$("$check" "$base" "$fixture" 2>&1)
    got=$?
    if [ "$got" -eq "$want" ]; then
        printf '  ok   %-52s exit %s\n' "$label" "$got"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-52s got exit %s want %s\n%s\n' "$label" "$got" "$want" "$out"
        fail=$(( fail + 1 ))
    fi
}

echo "── unchanged tree"
expect_ "no changes vs base" 0

echo "── comment-only change is accepted"
write_baseline
cat > "$fixture/bin/example" <<'PROSE'
#!/usr/bin/env bash
# a reworded full-line comment, plus a second line

greet() {
    echo "hello"   # trailing comment
}
greet
PROSE
expect_ "reworded/added full-line comments and blank lines" 0

echo "── code change is rejected"
write_baseline
cat > "$fixture/bin/example" <<'CODE'
#!/usr/bin/env bash
# a full-line comment
greet() {
    echo "goodbye"   # trailing comment
}
greet
CODE
expect_ "changed a string literal" 1

echo "── end-of-line comment change is rejected (full-line stripping only)"
write_baseline
cat > "$fixture/bin/example" <<'EOLC'
#!/usr/bin/env bash
# a full-line comment
greet() {
    echo "hello"
}
greet
EOLC
expect_ "dropped a trailing comment" 1

echo "── shebang change is rejected (the interpreter is code)"
write_baseline
cat > "$fixture/bin/example" <<'SHEBANG'
#!/bin/sh
# a full-line comment
greet() {
    echo "hello"   # trailing comment
}
greet
SHEBANG
expect_ "changed the shebang" 1

echo "── deleting a file is rejected"
write_baseline
rm -f "$fixture/bin/example"
expect_ "removed a tracked script" 1
write_baseline

echo "── files outside bin/ and tests/ are ignored"
echo "notes" > "$fixture/README.md"
git -C "$fixture" add README.md
git -C "$fixture" commit -qm readme
echo "changed" > "$fixture/README.md"
expect_ "an out-of-scope file changed" 0

echo "── a brand-new script is ignored (it had no base version)"
printf '#!/usr/bin/env bash\necho new\n' > "$fixture/bin/brand-new"
expect_ "an added script" 0

echo "── a bad base ref is a usage error, not a pass"
if out=$("$check" definitely-not-a-ref "$fixture" 2>&1); then
    printf '  FAIL %s\n' "unknown base ref reported success"
    fail=$(( fail + 1 ))
else
    got=$?
    if [ "$got" -eq 2 ]; then
        printf '  ok   %-52s exit 2\n' "unknown base ref"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-52s got exit %s want 2\n%s\n' "unknown base ref" "$got" "$out"
        fail=$(( fail + 1 ))
    fi
fi

echo
if [ "$fail" -ne 0 ]; then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
