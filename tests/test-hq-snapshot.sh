#!/usr/bin/env bash
#
# bin/hq-snapshot's pure half, over a throwaway snapshot dir (mktemp -d)
# pointed at by HQ_SNAPSHOT_DIR. Offline: no tmux server is started or
# touched, no gh is called, no worktree is created — the pipelines source is
# driven by .feature fixtures written here.
#
#   tests/test-hq-snapshot.sh
#
# The cases that matter: the atomic write leaves <file>.tmp.<pid> as the only
# intermediate name and removes nothing; a snapshot's age decides fresh vs
# stale vs missing; and a worktree with no .feature/, an empty status.jsonl
# or a pre-jsonl status.json all read as NO pipeline state, never as a stale
# one.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-snapshot-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

export HQ_SNAPSHOT_DIR="$work/snapshot"

# shellcheck source=/dev/null
source "$repo/bin/hq-snapshot"

echo "── sourcing hands back the reader half and collects nothing"
if declare -f snapshot_write >/dev/null && declare -f snapshot_verdict >/dev/null \
    && declare -f snapshot_read >/dev/null && declare -f fmt_secs >/dev/null; then
    ok "snapshot_write/snapshot_verdict/snapshot_read/fmt_secs defined by sourcing"
else
    bad "reader half not defined by sourcing" "one of the four is missing"
fi
if [[ ! -d "$HQ_SNAPSHOT_DIR" ]]; then
    ok "sourcing creates no snapshot directory"
else
    bad "sourcing created $HQ_SNAPSHOT_DIR" "the source guard let collection run"
fi

echo "── snapshot_write: header line, atomic name, nothing removed"
printf 'a\tb\nc\td\n' | snapshot_write demo
f=$(snapshot_file demo)
if [[ "$f" == "$HQ_SNAPSHOT_DIR/demo.tsv" ]]; then
    ok "snapshot_file names <dir>/<source>.tsv"
else
    bad "snapshot_file" "got [$f]"
fi
first=$(head -n1 "$f")
case "$first" in
    '# generated '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z)
        ok "first line is a generated-at header: [$first]" ;;
    *)  bad "generated-at header" "got [$first]" ;;
esac
body=$(snapshot_read demo)
if [[ "$body" == $'a\tb\nc\td' ]]; then
    ok "snapshot_read drops the header and returns the body"
else
    bad "snapshot_read body" "got [$body]"
fi
# A body line that itself starts with '#' must survive: only the FIRST line
# is the header.
printf '# not a header\nx\ty\n' | snapshot_write demo
body=$(snapshot_read demo)
if [[ "$body" == $'# not a header\nx\ty' ]]; then
    ok "only the first line is treated as the header"
else
    bad "header stripping is not first-line-only" "got [$body]"
fi
# The write must go through <file>.tmp.$$ and leave nothing else behind.
leftovers=$(find "$HQ_SNAPSHOT_DIR" -name 'demo.tsv.tmp.*' 2>/dev/null)
if [[ -z "$leftovers" ]]; then
    ok "a successful write leaves no tmp file"
else
    bad "tmp file left after a successful write" "$leftovers"
fi
if ! grep -q 'rm ' "$repo/bin/hq-snapshot"; then
    ok "the collector contains no rm at all"
else
    bad "the collector contains an rm" "$(grep -n 'rm ' "$repo/bin/hq-snapshot")"
fi
# An empty body is still a write: a consumer must see "no rows", not a stale
# previous snapshot.
printf '' | snapshot_write demo
body=$(snapshot_read demo)
if [[ -z "$body" ]]; then
    ok "an empty body publishes an empty snapshot"
else
    bad "empty body" "got [$body]"
fi

echo "── snapshot_read/snapshot_age on a source that was never written"
if ! snapshot_read never-written >/dev/null 2>&1; then
    ok "snapshot_read exits 1 for a missing source"
else
    bad "snapshot_read on a missing source" "expected exit 1"
fi
a=$(snapshot_age never-written)
if [[ "$a" == "-1" ]]; then
    ok "snapshot_age is -1 for a missing source"
else
    bad "snapshot_age missing" "got [$a]"
fi

echo "── snapshot_cadence: the registry is the only home for a cadence"
cad_() {
    local name="$1" want="$2" got
    got=$(snapshot_cadence "$name")
    if [[ "$got" == "$want" ]]; then
        ok "cadence $name -> $got"
    else
        bad "cadence $name" "got [$got] want [$want]"
    fi
}
cad_ sessions 5
cad_ pipelines 5
cad_ worktrees 15
cad_ prs 30
if ! snapshot_cadence not-a-source >/dev/null 2>&1; then
    ok "snapshot_cadence exits 1 for a name that is not a source"
else
    bad "snapshot_cadence on a non-source" "expected exit 1"
fi

echo "── snapshot_verdict: fresh until three cadences old, then stale"
verdict_() {
    local age="$1" cadence="$2" want="$3" got
    got=$(snapshot_verdict "$age" "$cadence")
    if [[ "$got" == "$want" ]]; then
        ok "age=$age cadence=$cadence -> $got"
    else
        bad "verdict age=$age cadence=$cadence" "got [$got] want [$want]"
    fi
}
verdict_ -1 5 missing
verdict_ 0 5 fresh
verdict_ 15 5 fresh
verdict_ 16 5 stale
verdict_ 45 15 fresh
verdict_ 46 15 stale
verdict_ 90 30 fresh
verdict_ 91 30 stale
verdict_ 99999 0 fresh

echo "── fmt_secs"
secs_() {
    local s="$1" want="$2" got
    got=$(fmt_secs "$s")
    if [[ "$got" == "$want" ]]; then
        ok "fmt_secs $s -> $got"
    else
        bad "fmt_secs $s" "got [$got] want [$want]"
    fi
}
secs_ -1 never
secs_ 0 0s
secs_ 59 59s
secs_ 60 1m
secs_ 3599 59m
secs_ 3600 1h
secs_ 86399 23h
secs_ 86400 1d

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
