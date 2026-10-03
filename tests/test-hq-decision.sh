#!/usr/bin/env bash
#
# bin/hq-decision: one JSON file per decision, dedupe on key, tmp+mv,
# removes nothing.
#
#   tests/test-hq-decision.sh
#
# Offline: HQ_DECISIONS_DIR points at a throwaway mktemp -d tree for every
# case, TMUX is unset so `session` always falls back to "-", and nothing
# outside that tree is read or written. No tmux server, no network.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-decision-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }
check() {
    local label="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then ok "$label [$got]"; else bad "$label" "got [$got] want [$want]"; fi
}

unset TMUX
export HQ_DECISIONS_DIR="$work/decisions"
HQD="$repo/bin/hq-decision"

# ── sourcing hands back the decisions and starts no command ──

# shellcheck source=/dev/null
source "$HQD"

echo "── sourcing hands back the decisions and starts no view"
missing=""
for fn in decision_records decision_find_open_key decision_siblings \
          decision_find_file decision_write decision_new_id decision_slug \
          decision_epoch decision_fmt_secs; do
    declare -f "$fn" >/dev/null || missing+="$fn "
done
if [[ -z "$missing" ]]; then
    ok "the decisions are defined by sourcing"
else
    bad "sourcing defines the decisions" "missing: $missing"
fi
if [[ ! -e "$HQ_DECISIONS_DIR" ]]; then
    ok "sourcing creates no decisions directory"
else
    bad "sourcing created the decisions directory" "$HQ_DECISIONS_DIR exists"
fi
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$HQD"; then
    ok "the CLI contains no deletion"
else
    bad "the CLI contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$HQD")"
fi
# FORBIDDEN: any tmux subcommand beyond the read-only session-name probe.
dangerous_tmux=$(grep -nE 'tmux (list-clients|new-session|switch-client|has-session|list-sessions|set-option|send-keys|kill-session|kill-server|source-file|set-hook)' "$HQD")
if [[ -z "$dangerous_tmux" ]]; then
    ok "no tmux subcommand beyond the session-name probe"
else
    bad "a tmux subcommand beyond the probe is present" "$dangerous_tmux"
fi

# ── add: one file, id printed, fields right ──

echo "── add"
id1=$("$HQD" add --repo proj --pr 10 --title "Pick a cache TTL" \
    --option 'short|5 minutes|refresh often' \
    --option 'long|1 hour|fewer refreshes' \
    --recommend long --context "owner call" --session test-hub 2>"$work/err1")
rc=$?
check "add exits 0" "$rc" "0"
check "add prints a 6-hex id" "$(printf '%s' "$id1" | grep -cE '^[0-9a-f]{6}$')" "1"
files=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json')
check "exactly one file written" "$(printf '%s\n' "$files" | grep -c .)" "1"
f1=$(printf '%s' "$files")
check "id field"         "$(jq -r '.id' "$f1")"         "$id1"
check "key field"        "$(jq -r '.key' "$f1")"        "proj:10:pick-a-cache-ttl"
check "repo field"       "$(jq -r '.repo' "$f1")"       "proj"
check "pr field"         "$(jq -r '.pr' "$f1")"         "10"
check "branch field"     "$(jq -r '.branch' "$f1")"     "null"
check "title field"      "$(jq -r '.title' "$f1")"      "Pick a cache TTL"
check "context field"    "$(jq -r '.context' "$f1")"    "owner call"
check "recommend field"  "$(jq -r '.recommend' "$f1")"  "long"
check "session field"    "$(jq -r '.session' "$f1")"    "test-hub"
check "state is open"    "$(jq -r '.state' "$f1")"      "open"
check "answer is null"   "$(jq -r '.answer' "$f1")"     "null"
check "two options recorded" "$(jq '.options | length' "$f1")" "2"
check "first option id"  "$(jq -r '.options[0].id' "$f1")" "short"
check "first option label" "$(jq -r '.options[0].label' "$f1")" "5 minutes"
check "first option description" "$(jq -r '.options[0].description' "$f1")" "refresh often"

echo "── a second add with the same repo/pr/title dedupes"
id2=$("$HQD" add --repo proj --pr 10 --title "Pick a cache TTL" \
    --option 'short|5 minutes' --option 'long|1 hour' --recommend long 2>"$work/err2")
check "dedupe prints the existing id" "$id2" "$id1"
check "dedupe writes a stderr note" "$(grep -c 'already open' "$work/err2")" "1"
files=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json')
check "still exactly one file" "$(printf '%s\n' "$files" | grep -c .)" "1"

echo "── a reworded title on the same pr: new file + stderr warning naming the first id"
id3=$("$HQD" add --repo proj --pr 10 --title "Choose a cache TTL value" \
    --option 'short|5 minutes' --option 'long|1 hour' --recommend long 2>"$work/err3")
if [[ "$id3" != "$id1" ]]; then ok "a different id is minted [$id3]"; else bad "a different id is minted" "$id3 == $id1"; fi
check "the sibling warning names the first id" "$(grep -c "$id1" "$work/err3")" "1"
files=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json')
check "now two files" "$(printf '%s\n' "$files" | grep -c .)" "2"

echo "── validation failures write nothing and exit 2"
before=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json' | wc -l | tr -d ' ')
"$HQD" add --repo proj --title x --option 'a|A' --option 'b|B' >/dev/null 2>"$work/e_norecommend"
check "missing --recommend exits 2" "$?" "2"
"$HQD" add --repo proj --title x --option 'a|A' --recommend a >/dev/null 2>"$work/e_oneopt"
check "one --option exits 2" "$?" "2"
"$HQD" add --repo proj --title x --option 'a|A' --option 'b|B' --recommend z >/dev/null 2>"$work/e_badrec"
check "--recommend not an option id exits 2" "$?" "2"
after=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json' | wc -l | tr -d ' ')
check "no file was written by any failed add" "$after" "$before"

# ── update ──

echo "── update revises the same file in place"
"$HQD" update "$id1" --context "revised context" --recommend short >/dev/null 2>"$work/e_upd"
rc=$?
check "update exits 0" "$rc" "0"
check "context updated"    "$(jq -r '.context' "$f1")"   "revised context"
check "recommend updated"  "$(jq -r '.recommend' "$f1")" "short"
files=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json')
check "file count unchanged after update" "$(printf '%s\n' "$files" | grep -c .)" "2"
tmp_left=$(find "$HQ_DECISIONS_DIR" -type f -name '*.tmp.*')
check "no .tmp. file left behind" "${tmp_left:-none}" "none"

echo "── update refuses an unknown id"
"$HQD" update zzzzzz --title y >/dev/null 2>"$work/e_updunknown"
check "update on an unknown id exits 1" "$?" "1"

# ── answer ──

echo "── answer sets state and answer"
"$HQD" answer "$id1" short "picked the short TTL" >/dev/null 2>"$work/e_ans"
rc=$?
check "answer exits 0" "$rc" "0"
check "state is answered"   "$(jq -r '.state' "$f1")"          "answered"
check "answer.option"       "$(jq -r '.answer.option' "$f1")"  "short"
check "answer.note"         "$(jq -r '.answer.note' "$f1")"    "picked the short TTL"
check "answer.at is set"    "$(jq -r '.answer.at | length > 0' "$f1")" "true"

echo "── answer on an unknown option id fails"
"$HQD" answer "$id1" nosuchopt note >/dev/null 2>"$work/e_ansbad"
check "unknown option id exits 2" "$?" "2"

echo "── answer on an unknown decision id fails"
"$HQD" answer zzzzzz short note >/dev/null 2>"$work/e_ansunknown"
check "answer on an unknown id exits 1" "$?" "1"

echo "── update refuses an answered record"
"$HQD" update "$id1" --title "changed" >/dev/null 2>"$work/e_updanswered"
check "update on an answered record exits 1" "$?" "1"
check "the title was not changed" "$(jq -r '.title' "$f1")" "Pick a cache TTL"

echo "── add after answer with the same key starts a fresh card"
id4=$("$HQD" add --repo proj --pr 10 --title "Pick a cache TTL" \
    --option 'short|5 minutes' --option 'long|1 hour' --recommend long 2>"$work/err4")
if [[ "$id4" != "$id1" ]]; then ok "a new id is minted (the answered record does not block it) [$id4]"; else bad "a new id is minted" "$id4 == $id1"; fi
files=$(find "$HQ_DECISIONS_DIR" -type f -name '*.json')
check "now three files" "$(printf '%s\n' "$files" | grep -c .)" "3"

# ── list ──

echo "── list --open excludes answered"
open_ids=$("$HQD" list --open --json | jq -r '.[].id' | sort)
want_open=$(printf '%s\n%s\n' "$id3" "$id4" | sort)
check "open ids are exactly the two still-open records" "$open_ids" "$want_open"

echo "── list --json parses as an array of the matching records"
count=$("$HQD" list --json | jq 'length')
check "list --json returns all records" "$count" "3"
count_repo=$("$HQD" list --repo proj --json | jq 'length')
check "list --repo filters to that repo" "$count_repo" "3"

echo "── list's table prints the open state and the answered one"
table=$("$HQD" list)
check "the answered row is in the table" "$(printf '%s\n' "$table" | grep -c "$id1")" "1"
check "an open row is in the table" "$(printf '%s\n' "$table" | grep -c "$id3")" "1"

# ── answer --auto ──

echo "── answer --auto writes answer.by=auto, only for the recommended option"
id5=$("$HQD" add --repo proj --pr 20 --title "Pick a log format" \
    --option 'json|JSON' --option 'text|Text' --recommend json)
f5=$(find "$HQ_DECISIONS_DIR" -type f -name "*-$id5.json")
"$HQD" answer --auto "$id5" json >/dev/null 2>"$work/e_auto"
check "answer --auto exits 0" "$?" "0"
check "answer.by is auto" "$(jq -r '.answer.by' "$f5")" "auto"
check "answer.option is still the chosen one" "$(jq -r '.answer.option' "$f5")" "json"

id6=$("$HQD" add --repo proj --pr 21 --title "Pick a port" \
    --option 'a|8080' --option 'b|8081' --recommend a)
f6=$(find "$HQ_DECISIONS_DIR" -type f -name "*-$id6.json")
before_json=$(cat "$f6")
"$HQD" answer --auto "$id6" b >/dev/null 2>"$work/e_autobad"
check "answer --auto on a non-recommended option exits 2" "$?" "2"
check "the file is unchanged" "$(cat "$f6")" "$before_json"

echo "── answer --auto on an already-answered record refuses"
before_json5=$(cat "$f5")
"$HQD" answer --auto "$id5" json >/dev/null 2>"$work/e_autoanswered"
check "answer --auto on an already-answered record exits 1" "$?" "1"
check "the file is unchanged" "$(cat "$f5")" "$before_json5"

echo "── a plain answer writes answer.by=owner, and --auto is also accepted after OPTION-ID"
id7=$("$HQD" add --repo proj --pr 22 --title "Pick a timeout" \
    --option 'a|5s' --option 'b|10s' --recommend a)
f7=$(find "$HQ_DECISIONS_DIR" -type f -name "*-$id7.json")
"$HQD" answer "$id7" a "owner's own call" >/dev/null 2>"$work/e_owner"
check "plain answer.by is owner" "$(jq -r '.answer.by' "$f7")" "owner"

id8=$("$HQD" add --repo proj --pr 23 --title "Pick a worker count" \
    --option 'a|2' --option 'b|4' --recommend b)
f8=$(find "$HQ_DECISIONS_DIR" -type f -name "*-$id8.json")
"$HQD" answer "$id8" b --auto "auto note after the option" >/dev/null 2>"$work/e_autoafter"
check "--auto right after OPTION-ID also writes by=auto" "$(jq -r '.answer.by' "$f8")" "auto"

echo "── an old record with no answer.by field reads as owner"
old_file="$HQ_DECISIONS_DIR/proj/19990101T000000Z-oldabc.json"
mkdir -p "$(dirname "$old_file")"
cat > "$old_file" <<'EOF'
{"id":"oldabc","key":"proj:-:old-decision","repo":"proj","pr":null,"branch":null,
 "title":"An old decision","context":"","options":[{"id":"a","label":"A","description":""},{"id":"b","label":"B","description":""}],
 "recommend":"a","session":"-","created":"1999-01-01T00:00:00Z","updated":"1999-01-01T00:00:00Z",
 "state":"answered","answer":{"option":"a","note":"","at":"1999-01-01T00:00:00Z"}}
EOF
check "list --json normalises the missing by to owner" \
    "$("$HQD" list --json | jq -r '.[] | select(.id == "oldabc") | .answer.by')" "owner"
check "the BY column shows owner for the old record" \
    "$("$HQD" list | grep oldabc | awk '{print $3}')" "owner"
check "the BY column shows auto for an auto-answered record" \
    "$("$HQD" list | grep "$id5" | awk '{print $3}')" "auto"
check "the BY column shows - for an open record" \
    "$("$HQD" list | grep "$id3" | awk '{print $3}')" "-"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
