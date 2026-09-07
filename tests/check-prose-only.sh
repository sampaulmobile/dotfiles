#!/usr/bin/env bash
#
# Tripwire for prose-only passes: every file under bin/ and tests/ that
# differs from <base-ref> must be identical once full-line comments and
# blank lines are stripped. Fails naming the file and the first differing
# line.
#
#   tests/check-prose-only.sh <base-ref> [repo-dir]
#
# The shebang counts as code, and so do end-of-line comments — stripping is
# full-line only, so touching a trailing comment reports as a code change.
# That is the intended bar: edit a comment only where it owns the whole line.
#
# Blind spot: a full-line "#" inside a quoted jq/awk program is stripped too,
# though to bash it is string content — an apostrophe there ends the quote,
# and jq/awk semantics can change, with this check none the wiser. Run
# `bash -n` alongside, and run the affected script against its base version.
#
# bash 3.2 clean (macOS /bin/bash): no mapfile, no associative arrays.

set -uo pipefail

usage() {
    cat <<'USAGE'
usage: tests/check-prose-only.sh <base-ref> [repo-dir]

Compares every bin/ and tests/ file changed since <base-ref> against its
base version with full-line comments and blank lines removed, and fails if
any executable line differs. repo-dir defaults to this script's own repo.
USAGE
}

# Strips full-line comments and blank lines. Line 1 is kept when it is a
# shebang: an interpreter change is a code change.
strip_prose() {
    awk 'NR == 1 && /^#!/ { print; next }
         /^[ \t]*#/ { next }
         /^[ \t]*$/ { next }
         { print }'
}

case "${1:-}" in
    ''|-h|--help) usage; exit 2 ;;
esac
base=$1

if [ -n "${2:-}" ]; then
    repo=$2
else
    here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo=$(dirname "$here")
fi

if ! git -C "$repo" rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    echo "check-prose-only: not a commit in $repo: $base" >&2
    exit 2
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-prose-only.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT

# --no-renames: with rename detection a renamed+edited file lists only its new
# path, which has no base version, so both the deletion and the edit would
# pass silently.
git -C "$repo" diff --no-renames --name-only "$base" -- bin tests > "$tmp/files" || exit 2

status=0
checked=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    # A file the base ref never had cannot have lost code.
    git -C "$repo" cat-file -e "$base:$f" 2>/dev/null || continue
    if [ ! -f "$repo/$f" ]; then
        printf 'FAIL %s: file deleted (removing code is not a prose change)\n' "$f"
        status=1
        continue
    fi
    git -C "$repo" show "$base:$f" | strip_prose > "$tmp/a"
    strip_prose < "$repo/$f" > "$tmp/b"
    checked=$(( checked + 1 ))
    if cmp -s "$tmp/a" "$tmp/b"; then
        printf '  ok   %s\n' "$f"
        continue
    fi
    diff -u "$tmp/a" "$tmp/b" > "$tmp/d" 2>&1
    printf 'FAIL %s: code changed, not just prose\n' "$f"
    awk '/^@@/ { hunk = $0 }
         /^[-+]/ && !/^(---|\+\+\+)/ {
             if (hunk != "") print "       " hunk
             print "       " $0
             exit
         }' "$tmp/d"
    status=1
done < "$tmp/files"

echo
if [ "$status" -ne 0 ]; then
    echo "PROSE-ONLY CHECK FAILED (base $base)"
    exit 1
fi
echo "ok: $checked file(s) changed vs $base, none of them in code"
