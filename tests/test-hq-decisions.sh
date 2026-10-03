#!/usr/bin/env bash
#
# bin/hq-decisions: the read-only screen over bin/hq-decision's records.
#
#   tests/test-hq-decisions.sh
#
# Fixtures are written by `hq-decision add`/`answer` into a throwaway
# mktemp -d tree (HQ_DECISIONS_DIR); --dump renders them with no terminal.
# Offline: no tmux server, no network. TZ=UTC so the fixtures' ages are
# predictable to the second they were just created.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-decisions-test.XXXXXX")
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
unset TMUX
export HQ_DECISIONS_DIR="$work/decisions"
HQD="$repo/bin/hq-decision"
HQDS="$repo/bin/hq-decisions"

# ── sourcing hands back wrap_text and starts no loop ──

# shellcheck source=/dev/null
source "$HQDS"

echo "── sourcing hands back the pure functions and starts no loop"
missing=""
for fn in wrap_text clip term_size card_age load_data build_frame; do
    declare -f "$fn" >/dev/null || missing+="$fn "
done
if [[ -z "$missing" ]]; then
    ok "the pure functions are defined by sourcing"
else
    bad "sourcing defines the functions" "missing: $missing"
fi
if [[ ! -e "$HQ_DECISIONS_DIR" ]]; then
    ok "sourcing creates no decisions directory"
else
    bad "sourcing created the decisions directory" "$HQ_DECISIONS_DIR exists"
fi

echo "── the screen is read-only and tmux-free"
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$HQDS"; then
    ok "the screen contains no deletion"
else
    bad "the screen contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$HQDS")"
fi
# Strip the usage() heredoc (prose, not code) and comment lines before
# looking for an actual invocation — "tmux" otherwise only appears in text
# describing its own absence.
code_only=$(awk '/<<.?EOF.?$/{skip=1; next} skip && /^EOF$/{skip=0; next} skip{next} {print}' "$HQDS")
tmux_calls=$(printf '%s\n' "$code_only" | grep -v '^[[:space:]]*#' | grep 'tmux')
if [[ -z "$tmux_calls" ]]; then
    ok "no tmux call anywhere in the screen"
else
    bad "a tmux call is present" "$tmux_calls"
fi
if ! grep -qE 'read .*-t *[0-9]*\.[0-9]' "$HQDS"; then
    ok "the key loop has no fractional read -t"
else
    bad "a fractional read -t is present" "$(grep -nE 'read .*-t *[0-9]*\.[0-9]' "$HQDS")"
fi

# ── wrap_text unit cases ──

echo "── wrap_text"
check "a short line is not wrapped" "$(wrap_text 'hello world' 20)" "hello world"
w=$(wrap_text 'one two three four five' 10)
check "wraps at a word boundary" "$w" "$(printf 'one two\nthree four\nfive')"
maxlen=0
while IFS= read -r l; do (( ${#l} > maxlen )) && maxlen=${#l}; done <<< "$w"
check "no wrapped line exceeds the width" "$maxlen" "10"
long=$(wrap_text 'abcdefghij' 4)
check "hard-splits a word longer than the width" "$long" "$(printf 'abcd\nefgh\nij')"
twopara=$(wrap_text $'first paragraph\nsecond paragraph' 100)
check "preserves an embedded newline as a paragraph break" "$twopara" "$(printf 'first paragraph\nsecond paragraph')"
check "empty text wraps to nothing" "$(wrap_text '' 20)" ""

# ── fixtures ──

"$HQD" add --repo proj --pr 7 --title "Pick a retry budget" \
    --option 'short|2 attempts|fails fast' \
    --option 'long|5 attempts|more resilient, slower to fail' \
    --recommend long --session proj-hub \
    --context "A longer context paragraph written to force word wrapping across more than one line when the terminal column count is narrow." \
    >/dev/null
answered_id=$("$HQD" add --repo proj --branch feat/y --title "Pick a log level" \
    --option 'debug|Debug' --option 'info|Info' --recommend info --session proj-hub)
"$HQD" answer "$answered_id" info "went with info" >/dev/null

echo "── --dump over the fixtures"
dump=$(NO_COLOR=1 COLUMNS=60 "$HQDS" --dump 2>"$work/dump.err")
if [[ -s "$work/dump.err" ]]; then bad "--dump wrote to stderr" "$(cat "$work/dump.err")"; fi
check "the header counts one open and one answered" \
    "$(printf '%s\n' "$dump" | head -1)" "DECISIONS  1 open · 1 answered"
check "the open card names its repo/pr and title" \
    "$(printf '%s\n' "$dump" | grep -c 'proj #7.*Pick a retry budget')" "1"
check "the open card shows its session" \
    "$(printf '%s\n' "$dump" | grep -c 'proj-hub')" "1"
check "the recommended option is starred" \
    "$(printf '%s\n' "$dump" | grep -c '★ long')" "1"
check "the recommended option is noted as such" \
    "$(printf '%s\n' "$dump" | grep -c '(recommended)')" "1"
check "the non-recommended option has no star" \
    "$(printf '%s\n' "$dump" | grep -cE '^ *short +2 attempts')" "1"
maxlen=0
while IFS= read -r l; do
    # The static key-hint footer is not wrapped to the terminal width, only
    # the cards above it; the footer's own line is exempt.
    [[ "$l" == *'q quit'* ]] && continue
    n=$(printf '%s' "$l" | wc -m)
    (( n > maxlen )) && maxlen=$n
done <<< "$dump"
if (( maxlen <= 60 )); then
    ok "no card line exceeds 60 columns [$maxlen]"
else
    bad "a card line exceeds 60 columns" "$maxlen"
fi
check "the answered section header appears" "$(printf '%s\n' "$dump" | grep -c '^ANSWERED$')" "1"
check "the answered row is folded to one line with the chosen label" \
    "$(printf '%s\n' "$dump" | grep -c 'proj feat/y.*Pick a log level.*→ Info')" "1"
check "the answered row does not show its note by default (collapsed)" \
    "$(printf '%s\n' "$dump" | grep -c 'went with info')" "0"

echo "── an empty decisions dir prints the empty message"
empty_dir="$work/empty"
dump_empty=$(HQ_DECISIONS_DIR="$empty_dir" NO_COLOR=1 COLUMNS=60 "$HQDS" --dump)
check "zero decisions" "$(printf '%s\n' "$dump_empty" | grep -c 'no decisions recorded')" "1"
check "the header still counts zero and zero" \
    "$(printf '%s\n' "$dump_empty" | head -1)" "DECISIONS  0 open · 0 answered"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
