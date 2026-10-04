#!/usr/bin/env bash
#
# bin/hq-decisions: read-only over bin/hq-decision's records; its one write
# is _state/seen, interactive viewer only. Two views: LIST (one line per
# decision) and DETAIL (⏎ on a row).
#
#   tests/test-hq-decisions.sh
#
# Fixtures are written by `hq-decision add`/`answer` into a throwaway
# mktemp -d tree (HQ_DECISIONS_DIR); --dump renders them with no terminal.
# Offline: no tmux server, no network.

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

unset TMUX
export HQ_DECISIONS_DIR="$work/decisions"
HQD="$repo/bin/hq-decision"
HQDS="$repo/bin/hq-decisions"

# ── sourcing hands back the pure functions and starts no loop ──

# shellcheck source=/dev/null
source "$HQDS"

echo "── sourcing hands back the pure functions and starts no loop"
missing=""
for fn in wrap_text clip pad term_size age_of load_data build_frame \
          decisions_pr_url decisions_locate_id; do
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

echo "── the screen is read-only over the records, and its only tmux calls are g's"
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$HQDS"; then
    ok "the screen contains no deletion"
else
    bad "the screen contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$HQDS")"
fi
# Strip the usage() heredoc (prose, not code) and comment lines before
# looking for an actual invocation — "tmux" otherwise also appears in text
# describing the feature.
code_only=$(awk '/<<.?EOF.?$/{skip=1; next} skip && /^EOF$/{skip=0; next} skip{next} {print}' "$HQDS")
tmux_calls=$(printf '%s\n' "$code_only" | grep -v '^[[:space:]]*#' | grep -oE 'tmux [a-z-]+')
bad_tmux=$(printf '%s\n' "$tmux_calls" | grep -vE '^tmux (display|list-clients|has-session|switch-client)$')
if [[ -z "$bad_tmux" ]]; then
    ok "every tmux call is in {display, list-clients, has-session, switch-client}"
else
    bad "a tmux call outside that set is present" "$bad_tmux"
fi
switch_calls=$(printf '%s\n' "$code_only" | grep 'tmux switch-client')
no_c_flag=$(printf '%s\n' "$switch_calls" | grep -v -- '-c ')
if [[ -z "$switch_calls" || -z "$no_c_flag" ]]; then
    ok "every switch-client carries -c"
else
    bad "a switch-client without -c is present" "$no_c_flag"
fi
if ! grep -qE 'read .*-t *[0-9]*\.[0-9]' "$HQDS"; then
    ok "the key loop has no fractional read -t"
else
    bad "a fractional read -t is present" "$(grep -nE 'read .*-t *[0-9]*\.[0-9]' "$HQDS")"
fi

# ── seen-stamp writer/reader round trip ──

echo "── decisions_write_seen/decisions_read_seen_cutoff round trip"
decisions_write_seen
seen_file="$HQ_DECISIONS_DIR/_state/seen"
check "the seen file exists with one ISO line" "$(grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$seen_file")" "1"
decisions_read_seen_cutoff
check "SEEN_CUTOFF_EPOCH is set from it" "$([[ "$SEEN_CUTOFF_EPOCH" -gt 0 ]] && echo yes || echo no)" "yes"
check "no .tmp. file is left behind" "$(find "$HQ_DECISIONS_DIR/_state" -type f -name '*.tmp.*' | wc -l | tr -d ' ')" "0"
rm -f "$seen_file"

# ── wrap_text / pad / decisions_pr_url unit cases ──

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
oldpwd=$(pwd)
cd "$work"
touch alpha.json beta.json
noglob_out=$(wrap_text 'see *.json for details' 60)
cd "$oldpwd"
check "wrap_text does not glob a '*' word" "$noglob_out" "see *.json for details"

echo "── pad"
check "pad left-pads by character count" "$(pad ab 5)" "ab   "
check "pad right-aligns" "$(pad ab 5 right)" "   ab"
check "pad never truncates" "$(pad abcdef 3)" "abcdef"

echo "── decisions_pr_url"
check "ssh form" "$(decisions_pr_url 'git@github.com:foo/bar.git' 5)" "https://github.com/foo/bar/pull/5"
check "ssh form, no .git" "$(decisions_pr_url 'git@github.com:foo/bar' 5)" "https://github.com/foo/bar/pull/5"
check "ssh:// form" "$(decisions_pr_url 'ssh://git@github.com/foo/bar.git' 5)" "https://github.com/foo/bar/pull/5"
check "https form" "$(decisions_pr_url 'https://github.com/foo/bar.git' 5)" "https://github.com/foo/bar/pull/5"
check "a non-github origin yields nothing" "$(decisions_pr_url 'https://gitlab.com/foo/bar' 5; echo rc=$?)" "rc=1"

# ── fixtures ──

open_why_id=$("$HQD" add --repo proj --pr 7 --title "Pick a retry budget" \
    --option 'short|2 attempts|fails fast' \
    --option 'long|5 attempts|more resilient, slower to fail' \
    --recommend long --session proj-hub \
    --why "fewer retries waste less time on a dead dependency" \
    --context "A longer context paragraph written to force word wrapping across more than one line when the terminal column count is narrow.")
open_nowhy_id=$("$HQD" add --repo proj --pr 9 --title "Pick a batch size" \
    --option 'small|10 items|conservative' \
    --option 'large|100 items|faster throughput' \
    --recommend small --session ctx-hub \
    --context "keep batches under the memory ceiling")
auto_id=$("$HQD" add --repo proj --pr 30 --title "Pick a cache ttl" \
    --option 'short|5m' --option 'long|1h' --recommend long --session proj-hub)
"$HQD" answer --auto "$auto_id" long >/dev/null
owner_id=$("$HQD" add --repo other --branch feat/y --title "Pick a log level" \
    --option 'debug|Debug' --option 'info|Info' --recommend info --session proj-hub)
"$HQD" answer "$owner_id" debug "went with debug despite the rec" >/dev/null

old_file="$HQ_DECISIONS_DIR/proj/19990101T000000Z-oldabc.json"
mkdir -p "$(dirname "$old_file")"
cat > "$old_file" <<'EOF'
{"id":"oldabc","key":"proj:-:old-decision","repo":"proj","pr":null,"branch":null,
 "title":"An old decision","context":"","options":[{"id":"a","label":"A","description":""},{"id":"b","label":"B","description":""}],
 "recommend":"a","session":"-","created":"1999-01-01T00:00:00Z","updated":"1999-01-01T00:00:00Z",
 "state":"answered","answer":{"option":"a","note":"","at":"1999-01-01T00:00:00Z"}}
EOF

longtitle=$(printf 'X%.0s' $(seq 1 200))
long_id=$("$HQD" add --repo proj --pr 99 --title "$longtitle" \
    --option 'a|A' --option 'b|B' --recommend a --session proj-hub)

# ── LIST: header, sections, counts ──

echo "── --dump: header counts and section order"
dump=$(NO_COLOR=1 COLUMNS=100 "$HQDS" --dump 2>"$work/dump.err")
if [[ -s "$work/dump.err" ]]; then bad "--dump wrote to stderr" "$(cat "$work/dump.err")"; fi
check "the header counts 3 open, 3 answered of which 1 auto" \
    "$(printf '%s\n' "$dump" | head -1 | grep -oE '^DECISIONS  [0-9]+ open · [0-9]+ answered \([0-9]+ auto\)')" \
    "DECISIONS  3 open · 3 answered (1 auto)"
check "the unseen-auto marker shows 1" \
    "$(printf '%s\n' "$dump" | head -1 | grep -c '  1 auto-taken since you last looked')" "1"
check "ANSWERED is hidden by default" "$(printf '%s\n' "$dump" | grep -c '^ANSWERED$')" "0"
check "hidden ANSWERED collapses to one line with its count and the new auto-takes" \
    "$(printf '%s\n' "$dump" | grep -c '^ANSWERED · 3 hidden (1 new auto-taken) — a to show$')" "1"
check "an answered row is not rendered while hidden" "$(printf '%s\n' "$dump" | grep -c 'Pick a log level')" "0"
check "NEEDS YOU heads the list" "$(printf '%s\n' "$dump" | grep -nE '^(NEEDS YOU|ANSWERED)' | head -1 | cut -d: -f2)" "NEEDS YOU"
check "each open decision appears exactly once" \
    "$(printf '%s\n' "$dump" | grep -c 'Pick a retry budget')" "1"

echo "── --dump --answered shows the ANSWERED section"
dumpa=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --answered)
check "ANSWERED section header appears" "$(printf '%s\n' "$dumpa" | grep -c '^ANSWERED$')" "1"
check "auto-taken rows live in ANSWERED, after its header" \
    "$(printf '%s\n' "$dumpa" | awk '/^ANSWERED$/ { a = 1 } /Pick a cache ttl/ { print (a ? "after" : "before") }')" "after"
check "no AUTO-TAKEN section any more" "$(printf '%s\n' "$dumpa" | grep -c '^AUTO-TAKEN')" "0"
hdr_line=$(printf '%s\n' "$dumpa" | grep '^ *AGE ')
row_line=$(printf '%s\n' "$dumpa" | grep 'Debug · overrode')
hdr_pre="${hdr_line%%OUTCOME*}"; row_pre="${row_line%%Debug · overrode*}"
check "the OUTCOME header sits over its rows' values" \
    "$(a=$(printf '%s' "$hdr_pre" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' '); b=$(printf '%s' "$row_pre" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')
       [[ -n "$row_line" && "$a" == "$b" ]] && echo aligned || echo "$a vs $b")" "aligned"
check "no placeholder once ANSWERED is shown" "$(printf '%s\n' "$dumpa" | grep -c 'hidden — a to show')" "0"
check "the owner-answered row is in it" "$(printf '%s\n' "$dumpa" | grep -c 'Pick a log level')" "1"
check "the old no-by record shows its label, no overrode" \
    "$(printf '%s\n' "$dumpa" | grep -c 'An old decision.*  A$')" "1"
check "a >=1000-day-old age clips to the 5-char AGE column rather than shifting the row" \
    "$(printf '%s\n' "$dumpa" | grep 'An old decision' | cut -c3-7)" "1013…"

echo "── an empty NEEDS YOU says so"
check "nothing-waiting line absent while decisions are open" \
    "$(printf '%s\n' "$dump" | grep -c 'nothing waiting on you')" "0"

# ── LIST: row content per kind, at two widths ──

for cols in 80 160; do
    echo "── --dump at COLUMNS=$cols: row content and width"
    d=$(NO_COLOR=1 COLUMNS=$cols "$HQDS" --dump --answered)
    check "[$cols] open row: session + where + title" \
        "$(printf '%s\n' "$d" | grep -c 'proj-hub.*proj #7.*Pick a retry budget')" "1"
    check "[$cols] open row OUTCOME: the recommendation's label" \
        "$(printf '%s\n' "$d" | grep -c 'Pick a retry budget.*rec: 5 attempts$')" "1"
    check "[$cols] auto row OUTCOME: the taken option's label, WAITED filled" \
        "$(printf '%s\n' "$d" | grep -cE 'Pick a cache ttl.* [0-9]+[smhd]  1h$')" "1"
    check "[$cols] owner row off the recommendation says overrode" \
        "$(printf '%s\n' "$d" | grep -c 'Pick a log level.*Debug · overrode$')" "1"
    check "[$cols] answered row WHERE is its own repo, not the previous row's" \
        "$(printf '%s\n' "$d" | grep -c 'other feat/y.*Pick a log level')" "1"
    check "[$cols] the 200-char title's row is clipped with …" \
        "$(printf '%s\n' "$d" | grep -c 'proj-hub.*XXXX.*…')" "1"
    maxlen=0
    while IFS= read -r l; do
        n=$(printf '%s' "$l" | wc -m)
        (( n > maxlen )) && maxlen=$n
    done <<< "$d"
    if (( maxlen <= cols )); then
        ok "[$cols] no line exceeds the terminal width [$maxlen]"
    else
        bad "[$cols] a line exceeds the terminal width" "$maxlen > $cols"
    fi
done

for cols in 40 50; do
    echo "── --dump --answered at COLUMNS=$cols: no line exceeds the width"
    d=$(NO_COLOR=1 COLUMNS=$cols "$HQDS" --dump --answered)
    maxlen=0
    while IFS= read -r l; do
        n=$(printf '%s' "$l" | wc -m)
        (( n > maxlen )) && maxlen=$n
    done <<< "$d"
    if (( maxlen <= cols )); then
        ok "[$cols] no line exceeds the terminal width [$maxlen]"
    else
        bad "[$cols] a line exceeds the terminal width" "$maxlen > $cols"
    fi
done

title_w_80=$(printf '%s\n' "$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --answered)" | grep -oE 'X+' | awk '{print length}')
title_w_160=$(printf '%s\n' "$(NO_COLOR=1 COLUMNS=160 "$HQDS" --dump --answered)" | grep -oE 'X+' | awk '{print length}')
if (( title_w_160 > title_w_80 )); then
    ok "the title column is wider at 160 than at 80 [$title_w_80 -> $title_w_160]"
else
    bad "the title column did not widen" "80:$title_w_80 160:$title_w_160"
fi

echo "── --dump still creates no _state/seen file"
check "no seen file after --dump" "$([[ -e "$HQ_DECISIONS_DIR/_state/seen" ]] && echo yes || echo no)" "no"

echo "── an empty decisions dir prints an empty NEEDS YOU"
empty_dir="$work/empty"
dump_empty=$(HQ_DECISIONS_DIR="$empty_dir" NO_COLOR=1 COLUMNS=60 "$HQDS" --dump)
check "zero decisions: an empty NEEDS YOU" "$(printf '%s\n' "$dump_empty" | grep -c 'nothing waiting on you')" "1"
check "the header still counts all zero" \
    "$(printf '%s\n' "$dump_empty" | head -1)" "DECISIONS  0 open · 0 answered (0 auto)"

# ── DETAIL ──

echo "── --dump --detail: open with why"
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail "$open_why_id")
check "state line shows OPEN" "$(printf '%s\n' "$d" | grep -c '^OPEN ·')" "1"
check "the recommended option is dotted and marked recommended" \
    "$(printf '%s\n' "$d" | grep -c '● long.*· recommended')" "1"
check "the why text follows the recommendation" \
    "$(printf '%s\n' "$d" | grep -c 'why: fewer retries waste less time')" "1"
check "the TO ANSWER bar names the recommended option and the answer command" \
    "$(printf '%s' "$d" | tr '\n' ' ' | grep -c 'TO ANSWER.*go with long.*hq-decision answer '"$open_why_id"' long')" "1"
check "the recommended option's head: 2-wide mark, id, two spaces, label, suffix" \
    "$(printf '%s\n' "$d" | grep -c '^● long  5 attempts · recommended$')" "1"
check "an unmarked option's head: blank mark column, id, two spaces, label" \
    "$(printf '%s\n' "$d" | grep -c '^  short  2 attempts$')" "1"
check "the TO ANSWER bar keeps two spaces after the label" \
    "$(printf '%s\n' "$d" | grep -c '^TO ANSWER  tell')" "1"

echo "── --dump --detail: open without why"
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail "$open_nowhy_id")
check "no why: line appears" "$(printf '%s\n' "$d" | grep -c '^    why:')" "0"

echo "── --dump --detail: auto-taken"
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail "$auto_id")
check "state line shows AUTO-TAKEN" "$(printf '%s\n' "$d" | grep -c '^AUTO-TAKEN ·')" "1"
check "the chosen option is marked as the recommendation" \
    "$(printf '%s\n' "$d" | grep -c '✓ long.*was the recommendation')" "1"
check "TO REVERSE names the other option" \
    "$(printf '%s' "$d" | tr '\n' ' ' | grep -c 'TO REVERSE.*reverse '"$auto_id"', short instead.*hq-decision answer '"$auto_id"' short')" "1"
check "the TO REVERSE bar keeps two spaces after the label" \
    "$(printf '%s\n' "$d" | grep -c '^TO REVERSE  tell')" "1"

echo "── --dump --detail: owner-answered on a non-recommended option"
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail "$owner_id")
check "state line shows ANSWERED" "$(printf '%s\n' "$d" | grep -c 'ANSWERED ·')" "1"
check "the chosen option is marked owner chose" \
    "$(printf '%s\n' "$d" | grep -c '✓ debug.*owner chose')" "1"
check "the note is shown" "$(printf '%s\n' "$d" | grep -c 'went with debug despite the rec')" "1"
check "the recommended option still shows its star" \
    "$(printf '%s\n' "$d" | grep -c '● info.*recommended')" "1"
check "the bottom bar says answered by you" "$(printf '%s\n' "$d" | grep -c '^answered by you')" "1"

echo "── --dump --detail: an old record with neither why nor answer.by renders as owner"
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail oldabc)
check "state line shows ANSWERED (owner)" "$(printf '%s\n' "$d" | grep -c 'ANSWERED ·')" "1"
check "no why: line appears" "$(printf '%s\n' "$d" | grep -c '^    why:')" "0"

echo "── --dump --detail: an unknown id exits 1"
"$HQDS" --dump --detail zzzzzz >/dev/null 2>"$work/e_unknown"
check "exit 1" "$?" "1"
check "stderr names the id" "$(grep -c "no such decision 'zzzzzz'" "$work/e_unknown")" "1"

echo "── --dump --detail: a branch+long-session record never exceeds the terminal width"
longsession_id=$("$HQD" add --repo proj \
    --branch feat/a-really-long-branch-name-for-width-testing-purposes \
    --title "Pick a session naming policy" \
    --option 'a|A' --option 'b|B' --recommend a \
    --session a-very-long-session-name-used-to-force-line-wrapping-in-detail-view)
d=$(NO_COLOR=1 COLUMNS=80 "$HQDS" --dump --detail "$longsession_id")
maxlen=0
while IFS= read -r l; do
    n=$(printf '%s' "$l" | wc -m)
    (( n > maxlen )) && maxlen=$n
done <<< "$d"
if (( maxlen <= 80 )); then
    ok "[detail] no line exceeds the terminal width [$maxlen]"
else
    bad "[detail] a line exceeds the terminal width" "$maxlen > 80"
fi

echo "── DETAIL reload: an answered record follows its id out of OPEN into ANSWERED"
reload_id=$("$HQD" add --repo proj --pr 55 --title "Pick a reload target" \
    --option 'a|A' --option 'b|B' --recommend a --session proj-hub)
decisions_read_seen_cutoff
load_data
show_answered=false
view_mode=list
decisions_locate_id "$reload_id"
decisions_enter_detail "$LOCATE_IDX"
"$HQD" answer "$reload_id" b "owner note" >/dev/null
load_data
build_frame
paint >/dev/null
check "the repaint shows ANSWERED" "$(printf '%s' "$screen_out" | grep -c 'ANSWERED ·')" "1"
check "the repaint's bar says answered by you" "$(printf '%s' "$screen_out" | grep -c 'answered by you')" "1"
check "the chosen option is marked owner chose" "$(printf '%s' "$screen_out" | grep -c '· owner chose')" "1"
check "no stale TO ANSWER bar remains" "$(printf '%s' "$screen_out" | grep -c 'TO ANSWER')" "0"

# ── fd hardening (Amendment) ──
#
# load_data/build_frame/paint and the wrap_text/decisions_split helpers they
# call must never grow the process's own fd count: bash 3.2 does not
# reliably close a `< <(…)` process substitution or a `<<<` here-string fd
# opened inside a function on a path that runs every tick, and a pane left
# open long enough hits "Too many open files" (the bug this Amendment
# fixes). 200 cycles under a tight ulimit, in a subshell so the limit and
# any exhaustion stay contained to this test.

echo "── fd hardening: 200 cycles of load_data/build_frame/paint leak no descriptors"
fd_open_id=$("$HQD" add --repo proj --pr 201 --title "FD hardening: open decision" \
    --option 'a|Option A|a description long enough to wrap across more than one physical line of the detail body width' \
    --option 'b|Option B|another description, also long enough to wrap onto a second physical line here' \
    --recommend a --session hub \
    --why "a recommendation rationale that is long enough to wrap across more than one physical line too" \
    --context "$(printf 'word%.0s ' $(seq 1 120))
$(printf 'word%.0s ' $(seq 1 120))")
fd_ans_id=$("$HQD" add --repo proj --pr 202 --title "FD hardening: answered decision" \
    --option 'a|A' --option 'b|Chosen option with a longer label to wrap' --recommend a --session hub)
"$HQD" answer "$fd_ans_id" b "a note long enough to force a wrap across more than one physical line in the detail body" >/dev/null

fd_err="$work/fd-hardening.err"
fd_report="$work/fd-hardening.out"
(
    ulimit -n 32
    decisions_read_seen_cutoff
    before=$(ls /dev/fd | wc -l | tr -d ' ')
    for n in $(seq 1 200); do
        load_data
        view_mode=list; selected_id=""; build_frame; paint >/dev/null
        view_mode=detail; detail_id="$fd_open_id"; build_frame; paint >/dev/null
        view_mode=detail; detail_id="$fd_ans_id"; build_frame; paint >/dev/null
        wrap_text "$(printf 'word%.0s ' $(seq 1 30))
$(printf 'word%.0s ' $(seq 1 30))" 24 >/dev/null
    done
    after=$(ls /dev/fd | wc -l | tr -d ' ')
    printf 'BEFORE=%s AFTER=%s\n' "$before" "$after"
) >"$fd_report" 2>"$fd_err"
fd_before=$(grep -oE 'BEFORE=[0-9]+' "$fd_report" | cut -d= -f2)
fd_after=$(grep -oE 'AFTER=[0-9]+' "$fd_report" | cut -d= -f2)
check "fd count is unchanged after 200 cycles under ulimit -n 32" "$fd_after" "$fd_before"
if grep -qi 'too many open files' "$fd_err"; then
    bad "no 'Too many open files' in stderr" "$(cat "$fd_err")"
else
    ok "no 'Too many open files' in stderr"
fi
view_mode=list

# ── scrolling (screen_out, no terminal) ──

echo "── scrolling: a store with 30 open records under LINES=20"
work2=$(mktemp -d "$work/hq-decisions-scroll.XXXXXX")
export HQ_DECISIONS_DIR="$work2/decisions"
# DECISIONS_DIR (bin/hq-decision's global) was fixed at the `source "$HQDS"`
# above; the sourced functions below need it repointed explicitly.
DECISIONS_DIR="$HQ_DECISIONS_DIR"
for i in $(seq 1 30); do
    "$HQD" add --repo proj --pr "$i" --title "Decision number $i" \
        --option 'a|A' --option 'b|B' --recommend a --session hub >/dev/null
done
decisions_read_seen_cutoff
load_data
check "30 open records loaded" "$n_open" "30"
COLUMNS=100
LINES=20
view_mode=list
selected_id=""
build_frame
check "cursor_map has one entry per record" "${#cursor_map[@]}" "30"
selected=$(( ${#cursor_map[@]} - 1 ))
entry="${cursor_map[$selected]}"; idx="${entry#*:}"; selected_id="${d_id[$idx]}"
last_title="${d_title[$idx]}"
build_frame
paint >/dev/null
nlines=$(printf '%s' "$screen_out" | grep -c '')
if (( nlines <= 20 )); then ok "screen_out has <= 20 lines [$nlines]"; else bad "screen_out exceeds LINES" "$nlines"; fi
check "the first line is the header" \
    "$(printf '%s' "$screen_out" | sed -n '1p' | grep -oE '^DECISIONS')" "DECISIONS"
check "the last line is the footer" \
    "$(printf '%s' "$screen_out" | sed -n "${nlines}p")" \
    "$(printf '%s' "$frame_foot" | sed -n '1p')"
cursor_line=$(printf '%s' "$screen_out" | grep '›')
check "the › line is the LAST record's row (cursor_map's last entry)" \
    "$(printf '%s' "$cursor_line" | grep -Fc -- "$last_title")" "1"

echo "── scrolling: moving the cursor to row 0 repaints with row 0 visible"
selected=0
entry="${cursor_map[$selected]}"; idx="${entry#*:}"; selected_id="${d_id[$idx]}"
first_title="${d_title[$idx]}"
build_frame
paint >/dev/null
first_cursor_line=$(printf '%s' "$screen_out" | grep '›')
check "the › line is the FIRST record's row (cursor_map's first entry)" \
    "$(printf '%s' "$first_cursor_line" | grep -Fc -- "$first_title")" "1"
if [[ "$cursor_line" != "$first_cursor_line" ]]; then
    ok "the cursor row changed after moving to row 0"
else
    bad "the cursor row did not change" "$cursor_line"
fi

echo "── j/k: list_move alone (no build_frame) moves the › on the next paint"
list_move 1
paint >/dev/null
moved_line=$(printf "%s" "$screen_out" | grep "›")
entry="${cursor_map[1]}"; idx="${entry#*:}"
check "after list_move 1 the › line is the SECOND record" \
    "$(printf "%s" "$moved_line" | grep -Fc -- "${d_title[$idx]}")" "1"
list_move -1
paint >/dev/null
check "after list_move -1 the › line is the FIRST record again" \
    "$(printf "%s" "$screen_out" | grep "›" | grep -Fc -- "$first_title")" "1"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
