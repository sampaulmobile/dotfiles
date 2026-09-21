#!/usr/bin/env bash
#
# The inbox's two halves: bin/hq-snapshot's `inbox` record and bin/hq-inbox's
# decisions over it. Both run against fixtures in a throwaway tree
# (mktemp -d) that HQ_SNAPSHOT_DIR and HQ_INBOX_DIR point at, so no real
# snapshot, thread log or state file is read or written. Offline: no tmux
# server is started or touched, no gh, no git against another repo.
#
#   tests/test-hq-inbox.sh
#
# The cases that matter: every record is 10 fields wide and maps its empty
# fields to `-` both ways; the headline is the first non-blank body line of
# the LAST entry; a thread whose worktree has been swept keeps a row; each
# phase and each pr-tag lands in its documented bucket; an archive mark goes
# stale on a newer log or a changed state, which is what un-archives a row;
# and both state files key by the branch SLUG, so a mark made while the
# worktree was alive still matches the row the sweep leaves behind.
#
# The key loop itself has no test: it is one blocking `read` on a tty. What
# is asserted here instead is that no fractional `read -t` has come back,
# which is the form bash 3.2 rejects.
#
# TZ=UTC is load-bearing: the thread mtimes are set with `touch -t`, whose
# argument is local time, and the fixture state files carry the epochs.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-inbox-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }
check() {
    local label="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then ok "$label [$got]"; else bad "$label" "got [$got] want [$want]"; fi
}

export TZ=UTC
export HQ_SNAPSHOT_DIR="$work/snapshot"
export HQ_INBOX_DIR="$work/inbox"

# ── the sourced half defines the decisions and touches nothing ──

# shellcheck source=/dev/null
source "$repo/bin/hq-inbox"

echo "── sourcing hands back the decisions and starts no view"
missing=""
for fn in inbox_bucket inbox_parse inbox_archive_stale inbox_unread \
          iso_to_epoch inbox_thread_author inbox_state_get inbox_state_put; do
    declare -f "$fn" >/dev/null || missing+="$fn "
done
if [[ -z "$missing" ]]; then
    ok "the decisions are defined by sourcing"
else
    bad "sourcing defines the decisions" "missing: $missing"
fi
if [[ ! -e "$HQ_INBOX_DIR" && ! -e "$HQ_SNAPSHOT_DIR" ]]; then
    ok "sourcing creates no inbox or snapshot directory"
else
    bad "sourcing created a directory" "one of $HQ_INBOX_DIR / $HQ_SNAPSHOT_DIR exists"
fi
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-inbox"; then
    ok "the viewer contains no deletion"
else
    bad "the viewer contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-inbox")"
fi
# bash 3.2 answers a fractional timeout with `invalid timeout specification`
# and rc 1, so the key being read falls through to the wrong branch.
if ! grep -qE 'read .*-t *[0-9]*\.[0-9]' "$repo/bin/hq-inbox"; then
    ok "the key loop has no fractional read -t"
else
    bad "a fractional read -t is back" "$(grep -nE 'read .*-t *[0-9]*\.[0-9]' "$repo/bin/hq-inbox")"
fi

# ── fixtures ──

mkdir -p "$HQ_SNAPSHOT_DIR" "$HQ_INBOX_DIR/_state"
cp -R "$here/fixtures/inbox-threads/." "$HQ_INBOX_DIR/"
cp "$here/fixtures/inbox-state/archived.tsv" "$here/fixtures/inbox-state/seen.tsv" "$HQ_INBOX_DIR/_state/"
touch -t 202609211002.00 "$HQ_INBOX_DIR/proj/feat-gate.md"
touch -t 202609210930.00 "$HQ_INBOX_DIR/proj/feat-work.md"
touch -t 202609210945.00 "$HQ_INBOX_DIR/lib/fix-stall.md"
touch -t 202609201600.00 "$HQ_INBOX_DIR/proj/feat-swept.md"
touch -t 202609201600.00 "$HQ_INBOX_DIR/proj/feat-held.md"
{ echo '# generated 2026-09-21T19:00:00Z'; cat "$here/fixtures/inbox-pipelines.tsv"; } > "$HQ_SNAPSHOT_DIR/pipelines.tsv"
{ echo '# generated 2026-09-21T19:00:00Z'; cat "$here/fixtures/inbox-prs.tsv"; } > "$HQ_SNAPSHOT_DIR/prs.tsv"

# The collector runs in the SHELL RUNNING THIS SUITE, so the 3.2 pass really
# exercises it rather than whatever `env bash` resolves to.
"${BASH:-bash}" "$repo/bin/hq-snapshot" inbox >"$work/collect.err" 2>&1
rc=$?
if (( rc == 0 )); then ok "collect_inbox exits 0"; else bad "collect_inbox exit" "got $rc: $(cat "$work/collect.err")"; fi

records=$(snapshot_read inbox)

echo "── the record: 10 fields, - for every empty one"
widths=$(printf '%s\n' "$records" | awk -F'\t' '{print NF}' | sort -u | tr '\n' ' ')
check "every record is 10 fields wide" "${widths% }" "10"
if [[ "$records" != *$'\t\t'* ]]; then
    ok "no record holds an empty field (a run of tabs would collapse on read)"
else
    bad "an empty field is written blank" "$records"
fi

row_for() { printf '%s\n' "$records" | grep -F "	$1	" | head -n1; }

rec=$(row_for "feat/gate")
inbox_parse "$rec"
check "worktree"       "$f_worktree" "~/dev/proj.feat-gate"
check "session"        "$f_session"  "proj_feat-gate"
check "repo"           "$f_repo"     "proj"
check "branch"         "$f_branch"   "feat/gate"
check "state"          "$f_state"    "gate r1 orchestrator"
check "pr"             "$f_pr"       "https://github.com/acme/proj/pull/10"
check "pr-tag"         "$f_prtag"    "review-required"
check "thread-entries" "$f_entries"  "2"
check "headline is the first non-blank line of the LAST entry" \
    "$f_headline" "Plan digest ready — three steps, the gate is yours."

echo "── the join: a bare PR number matches inside its own repo"
inbox_parse "$(row_for "feat/ci")"
check "status.jsonl pr=11 picks up acme/proj#11's tag" "$f_prtag" "ci-red"
check "no thread log yet leaves thread-mtime empty" "$f_mtime" ""
check "no thread log yet leaves the headline empty" "$f_headline" ""
inbox_parse "$(row_for "feat/done")"
check "a merged PR tags the row merged" "$f_prtag" "merged"

echo "── a swept worktree keeps its thread"
inbox_parse "$(row_for "feat-swept")"
check "worktree is -"        "$f_worktree" ""
check "session is -"         "$f_session"  ""
check "state is -"           "$f_state"    ""
check "the log is still read" "$f_headline" "Shipped and swept; the log outlives the worktree."

echo "── inbox_bucket: each phase and each pr-tag"
check "gate"              "$(inbox_bucket 'gate r1 orchestrator' open false)"          "NEEDS YOU"
check "stalled"           "$(inbox_bucket 'stalled r4 orchestrator' '' false)"         "NEEDS YOU"
check "changes-requested" "$(inbox_bucket 'review r2 reviewer' changes-requested false)" "NEEDS YOU"
check "ci-red"            "$(inbox_bucket 'review r2 reviewer' ci-red false)"          "NEEDS YOU"
check "approved"          "$(inbox_bucket 'review r2 reviewer' approved false)"        "NEEDS YOU"
check "merge-conflict"    "$(inbox_bucket 'implement r1 implementer' merge-conflict false)" "NEEDS YOU"
check "done"              "$(inbox_bucket 'done r3 orchestrator' open false)"          "DONE"
check "merged"            "$(inbox_bucket 'implement r1 implementer' merged false)"    "DONE"
check "no pipelines row"  "$(inbox_bucket '' '' false)"                                "DONE"
check "implement"         "$(inbox_bucket 'implement r1 implementer' open false)"      "WORKING"
check "review-required"   "$(inbox_bucket 'review r2 reviewer' review-required false)" "WORKING"
check "archived wins over gate" "$(inbox_bucket 'gate r1 orchestrator' ci-red true)"   "ARCHIVED"

echo "── the archive mark goes stale on new activity"
check "nothing since the mark"     "$(inbox_archive_stale 1000 'done r1 x' 1000 'done r1 x')" "false"
check "the log was written since"  "$(inbox_archive_stale 1001 'done r1 x' 1000 'done r1 x')" "true"
check "the state moved on"         "$(inbox_archive_stale 1000 'gate r2 x' 1000 'done r1 x')" "true"
check "no log at all, state equal" "$(inbox_archive_stale '' 'done r1 x' 0 'done r1 x')"      "false"

echo "── unread"
check "never opened"        "$(inbox_unread 1000 '')"     "true"
check "written since seen"  "$(inbox_unread 1001 1000)"   "true"
check "seen at the last write" "$(inbox_unread 1000 1000)" "false"
check "no log to read"      "$(inbox_unread '' '')"       "false"

echo "── the age fallback parses status.jsonl's updated"
check "iso_to_epoch"          "$(iso_to_epoch 2026-09-21T18:00:00Z)" "1790013600"
check "iso_to_epoch epoch 0"  "$(iso_to_epoch 1970-01-01T00:00:00Z)" "0"
check "iso_to_epoch leap day" "$(iso_to_epoch 2024-02-29T12:00:00Z)" "1709208000"
check "iso_to_epoch rejects a non-timestamp" "$(iso_to_epoch 'not a time')" ""

echo "── the hub session g targets is the last entry's author"
check "author of the newest entry" "$(inbox_thread_author "$HQ_INBOX_DIR/proj/feat-gate.md")" "proj-hub"
check "a log with no entry"        "$(inbox_thread_author "$HQ_INBOX_DIR/_state/seen.tsv")"   ""

echo "── state files are replaced, never unlinked"
seen_file=$(inbox_state_file seen)
inbox_state_put "$seen_file" proj feat/gate 4242
check "put replaces the row"      "$(inbox_state_get "$seen_file" proj feat/gate)" "4242"
check "and leaves the others"     "$(inbox_state_get "$seen_file" proj feat/work)" "1789982940"
inbox_state_put "$seen_file" proj feat/gate
check "put with no value drops the row" "$(inbox_state_get "$seen_file" proj feat/gate)" ""
if [[ -f "$seen_file" ]]; then ok "the state file is still there"; else bad "the state file is gone" "$seen_file"; fi

echo "── a mark survives the sweep: both files key by the branch SLUG"
inbox_state_put "$seen_file" proj feat/x 5150
check "a mark made while the branch is feat/x" \
    "$(inbox_state_get "$seen_file" proj feat/x)"  "5150"
check "still matches once the row comes back as the slug feat-x" \
    "$(inbox_state_get "$seen_file" proj feat-x)"  "5150"
if grep -q "^proj$(printf '\t')feat-x$(printf '\t')5150$" "$seen_file"; then
    ok "and it is the slug that is on disk"
else
    bad "the mark is not keyed by the slug" "$(cat "$seen_file")"
fi
inbox_state_put "$seen_file" proj feat-x
check "and the slug drops the row the branch wrote" \
    "$(inbox_state_get "$seen_file" proj feat/x)"  ""

echo "── --dump renders the buckets over the fixtures"
dump=$(NO_COLOR=1 COLUMNS=120 "${BASH:-bash}" "$repo/bin/hq-inbox" --dump 2>"$work/dump.err")
if [[ -s "$work/dump.err" ]]; then bad "--dump wrote to stderr" "$(cat "$work/dump.err")"; fi
bucket_of() { printf '%s\n' "$dump" | awk -v pat="$1" '/^[A-Z]/{b=$0} $0 ~ pat {print b; exit}'; }
check "a gate run needs you"                "$(bucket_of 'proj/feat/gate')"  "NEEDS YOU"
check "a red-CI run needs you"              "$(bucket_of 'proj/feat/ci')"    "NEEDS YOU"
check "an implementing run is working"      "$(bucket_of 'proj/feat/work')"  "WORKING"
check "a slug-keyed mark holds a live slashed branch" "$(bucket_of 'proj/feat/done')" "ARCHIVED"
check "a log newer than its mark comes back" "$(bucket_of 'proj/feat-swept')" "DONE"
check "a mark newer than the log holds, with - read back as no state" \
    "$(bucket_of 'proj/feat-held')" "ARCHIVED"
check "a changed state brings it back live" "$(bucket_of 'lib/fix/stall')"   "NEEDS YOU"
if [[ "$dump" == *"Plan digest ready"* ]]; then
    ok "the headline reaches the row"
else
    bad "the headline is missing from the row" "$dump"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
