#!/usr/bin/env bash
#
# The feed's three halves: bin/tmux-claude-lib's get_last_exchange, the
# turns record built by bin/hq-snapshot's turns_rows (mtime-gated — the
# ambient cost this test exists to prove), and bin/hq-feed's own buckets,
# condensing and --dump rendering. Fixtures live under tests/fixtures/feed/
# with generic names; the far-back-prompt transcript is generated at test
# time into its own mktemp -d, removed only by this test. Offline: no tmux
# server is started or touched.
#
#   tests/test-hq-feed.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
fx="$repo/tests/fixtures/feed"

work=$(mktemp -d "${TMPDIR:-/tmp}/hq-feed-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }
check() {
    local label="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then ok "$label [$got]"; else bad "$label" "got [$got] want [$want]"; fi
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not installed — skipping" >&2
    exit 0
fi

# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"
export HQ_SNAPSHOT_DIR="$work/snapshot"
# shellcheck source=/dev/null
source "$repo/bin/hq-snapshot"
export FLAG_DIR="$work/flags"
# shellcheck source=/dev/null
source "$repo/bin/hq-feed"

echo "── sourcing hands back the pure functions and starts no loop/collection"
missing=""
for fn in wrap_text clip pad term_size load_data build_frame feed_bucket feed_label turns_rows get_last_exchange; do
    declare -f "$fn" >/dev/null || missing+="$fn "
done
if [[ -z "$missing" ]]; then ok "the pure functions are defined by sourcing"; else bad "sourcing" "missing: $missing"; fi
if [[ ! -e "$HQ_SNAPSHOT_DIR" ]]; then ok "sourcing creates no snapshot directory"; else bad "sourcing created $HQ_SNAPSHOT_DIR" "-"; fi
if [[ ! -e "$FLAG_DIR" ]]; then ok "sourcing creates no flag directory"; else bad "sourcing created $FLAG_DIR" "-"; fi

echo "── the viewer writes nothing, and its only tmux calls are the allowed set"
if ! grep -qwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-feed"; then
    ok "the viewer contains no deletion"
else
    bad "the viewer contains a deletion" "$(grep -nwE '\brm\b|rmdir|unlink|-delete' "$repo/bin/hq-feed")"
fi
code_only=$(awk '/<<.?EOF.?$/{skip=1; next} skip && /^EOF$/{skip=0; next} skip{next} {print}' "$repo/bin/hq-feed")
tmux_calls=$(printf '%s\n' "$code_only" | grep -v '^[[:space:]]*#' | grep -oE 'tmux [a-z-]+')
bad_tmux=$(printf '%s\n' "$tmux_calls" | grep -vE '^tmux (display|list-clients|has-session|new-session|switch-client)$')
if [[ -z "$bad_tmux" ]]; then
    ok "every tmux call is in {display, list-clients, has-session, new-session, switch-client}"
else
    bad "a tmux call outside that set is present" "$bad_tmux"
fi
if ! grep -qE 'read .*-t *[0-9]*\.[0-9]' "$repo/bin/hq-feed"; then
    ok "the key loop has no fractional read -t"
else
    bad "a fractional read -t is present" "-"
fi
code_no_comments=$(printf '%s\n' "$code_only" | grep -v '^[[:space:]]*#')
if ! printf '%s\n' "$code_no_comments" | grep -qE '<<<|< <\('; then
    ok "no here-string or process substitution on the loop path"
else
    bad "a <<< or < <(…) is present" "$(printf '%s\n' "$code_no_comments" | grep -nE '<<<|< <\(')"
fi

echo "── get_last_exchange over the feed fixtures"
check "idle: kind" "$(get_last_exchange "$fx/idle.jsonl" | cut -f1)" "you"
check "idle: prompt" "$(get_last_exchange "$fx/idle.jsonl" | cut -f2)" '"summarize the outage"'
check "working: tool is the basenamed path" "$(get_last_exchange "$fx/working.jsonl" | cut -f5)" '"Bash: run.sh"'
check "working: pending equals tool (no result yet)" \
    "$(get_last_exchange "$fx/working.jsonl" | cut -f5)" "$(get_last_exchange "$fx/working.jsonl" | cut -f6)"
check "permission: pending is the AskUserQuestion's question" \
    "$(get_last_exchange "$fx/permission.jsonl" | cut -f6)" '"Deploy to staging or prod?"'
check "peer: a peer+name message wins, kind msg" "$(get_last_exchange "$fx/peer.jsonl" | cut -f1)" "msg"
check "peer: from is the sender's name" "$(get_last_exchange "$fx/peer.jsonl" | cut -f3)" '"beta-hub"'
check "peer: a senderTaskId hand-back is skipped, prompt is the migration ask" \
    "$(get_last_exchange "$fx/peer.jsonl" | cut -f2)" '"go ahead with the migration"'
check "peer: reply is still the assistant's last text" "$(get_last_exchange "$fx/peer.jsonl" | cut -f4)" '"starting now"'
check "tasknotif: a task-notification record is not shown as you ›" \
    "$(get_last_exchange "$fx/tasknotif.jsonl" | cut -f1)" "you"
check "tasknotif: the prompt is unaffected" "$(get_last_exchange "$fx/tasknotif.jsonl" | cut -f2)" '"check the build"'
check "slash command: name + args join regardless of tag order (command-message first, as Claude Code actually writes it)" \
    "$(get_last_exchange "$fx/slashcmd.jsonl" | cut -f2)" '"/feature add a widget"'

echo "── the far-back prompt: a typed prompt behind > 200 KB of tool results"
fb=$(mktemp -d "${TMPDIR:-/tmp}/hq-feed-farback.XXXXXX")
{
    printf '{"type":"user","message":{"role":"user","content":"find the regression"},"origin":{"kind":"human"}}\n'
    big=$(printf 'x%.0s' $(seq 1 1000))
    for i in $(seq 1 250); do
        printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t%d","content":"%s"}]}}\n' "$i" "$big"
    done
    printf '{"type":"assistant","message":{"content":[{"type":"text","text":"found it"}]}}\n'
} > "$fb/t.jsonl"
size=$(wc -c < "$fb/t.jsonl")
if (( size > 200000 )); then ok "far-back fixture is > 200 KB ($size bytes)"; else bad "far-back fixture size" "$size bytes"; fi
check "far-back: the prompt is still found" "$(get_last_exchange "$fb/t.jsonl" | cut -f2)" '"find the regression"'
check "far-back: the reply is unaffected" "$(get_last_exchange "$fb/t.jsonl" | cut -f4)" '"found it"'
rm -rf "$fb"

echo "── turns_rows: record format and the mtime gate"
pane_body="alpha	%1	1	claude	working"
pane_meta=$'\n'"%1	1	/home/user/proj"
name_map=$'\n'
prev_body=$'\n'
cp "$fx/working.jsonl" "$work/transcript.jsonl"
find_pane_jsonl() { printf '%s' "$work/transcript.jsonl"; }
countfile="$work/get_last_exchange.count"
: > "$countfile"
get_last_exchange() {
    printf x >> "$countfile"
    printf 'you\t"hi"\t-\t-\t-\t-'
}
rec1=$(turns_rows "$pane_body" "$pane_meta" "$name_map" "$prev_body")
n_fields=$(awk -F'\t' '{print NF}' <<< "$rec1")
check "one record, 15 tab-separated fields" "$n_fields" "15"
check "leading fields are never empty" "$(cut -f1-5 <<< "$rec1")" $'alpha\t%1\t1\tclaude\tworking'
calls_after_first=$(wc -c < "$countfile" | tr -d ' ')
check "first call parses once" "$calls_after_first" "1"
prev_body=$'\n'"$rec1"
rec2=$(turns_rows "$pane_body" "$pane_meta" "$name_map" "$prev_body")
calls_after_second=$(wc -c < "$countfile" | tr -d ' ')
check "an unchanged jsonl+mtime reuses the record (0 more parses)" "$calls_after_second" "1"
check "the reused record is byte-identical" "$rec2" "$rec1"
touch -t 203001010000.00 "$work/transcript.jsonl"
prev_body=$'\n'"$rec2"
turns_rows "$pane_body" "$pane_meta" "$name_map" "$prev_body" >/dev/null
calls_after_third=$(wc -c < "$countfile" | tr -d ' ')
check "a changed mtime on the same jsonl re-parses (1 more call)" "$calls_after_third" "2"
# unset -f cannot "undo" a shadow (bash's function table is flat, not
# stacked) — re-source to get the real find_pane_jsonl/get_last_exchange back.
unset -f find_pane_jsonl get_last_exchange
# shellcheck source=/dev/null
source "$repo/bin/tmux-claude-lib"

echo "── collect_turns never calls get_claude_panes (the amendment)"
# scan_agent_panes is still allowed as collect_turns' OWN fallback for a
# stale/missing panes snapshot; get_claude_panes (a ps per refresh) is not.
body=$(awk '/^collect_turns\(\)/{f=1} f{print} f && /^}/{exit}' "$repo/bin/hq-snapshot")
if ! printf '%s\n' "$body" | grep -q 'get_claude_panes'; then
    ok "collect_turns never calls get_claude_panes"
else
    bad "collect_turns calls get_claude_panes" "$body"
fi
if printf '%s\n' "$body" | grep -q 'tmux list-panes.*window_index'; then
    ok "window_index/cwd come from one tmux list-panes call, not get_claude_panes"
else
    bad "collect_turns' window_index/cwd join" "$body"
fi

echo "── feed_bucket / feed_label"
check "permission status -> NEEDS YOU" "$(feed_bucket permission false)" "NEEDS YOU"
check "a done flag outranks a working status -> DONE" "$(feed_bucket working true)" "DONE"
check "working status, no flag -> WORKING" "$(feed_bucket working false)" "WORKING"
check "idle status, no flag -> IDLE" "$(feed_bucket idle false)" "IDLE"
check "permission outranks a done flag too" "$(feed_bucket permission true)" "NEEDS YOU"
check "label: window 1, no name -> the session" "$(feed_label alpha 1 -)" "alpha"
check "label: window 3, no name -> session:3" "$(feed_label alpha 3 -)" "alpha:3"
check "label: a name replaces the computed label outright" "$(feed_label alpha 3 alpha-hub)" "alpha-hub"

echo "── feed_is_own_session (Ctrl+E popup vs the dedicated hq-feed session)"
if feed_is_own_session hq-feed; then ok "the dedicated hq-feed session is its own"; else bad "feed_is_own_session hq-feed" "false"; fi
if ! feed_is_own_session mysession; then ok "a Ctrl+E popup's host session is not its own"; else bad "feed_is_own_session mysession" "true"; fi
if ! feed_is_own_session ""; then ok "an unreadable session name is not its own"; else bad "feed_is_own_session ''" "true"; fi

echo "── feed_resolve_esc (a bare Esc vs. an arrow key's escape sequence)"
check "nothing follows 0x1b -> ESC" "$(feed_resolve_esc '')" "ESC"
check "an up-arrow sequence resolves to itself, unbound and so a no-op" "$(feed_resolve_esc '[A')" "[A"
check "a down-arrow sequence resolves to itself too" "$(feed_resolve_esc '[B')" "[B"

echo "── q/Esc dispatch in bin/hq-feed's view() key loop"
view_body=$(awk '/^view\(\) \{/{f=1} f{print} f && /^\}/{exit}' "$repo/bin/hq-feed")
if printf '%s\n' "$view_body" | grep -qE 'q\|ESC\)'; then
    ok "LIST's case statement has a q|ESC arm"
else
    bad "LIST q|ESC arm" "not found"
fi
if printf '%s\n' "$view_body" | grep -qE "q\|ESC\|\\\$'\\\\x7f'\\|\\\$'\\\\b'\\)"; then
    ok "DETAIL's back-to-LIST arm still includes q/ESC alongside backspace"
else
    bad "DETAIL q|ESC arm" "not found"
fi

echo "── IDLE defaults to expanded"
check "show_idle defaults to true" "$show_idle" "true"

echo "── condensing: strip_md and the 4-line budget with a (+N lines) marker"
idle_reply=$(get_last_exchange "$fx/idle.jsonl" | cut -f4 | jq -r '.')
stripped=$(printf '%s' "$idle_reply" | jq -Rs "$_FEED_STRIP_MD_JQ"'strip_md')
stripped=$(jq -r . <<< "$stripped")
case "$stripped" in
    '# '*) bad "heading marker stripped" "still present: $stripped" ;;
    *) ok "heading marker stripped" ;;
esac
if [[ "$stripped" != *'**'* ]]; then ok "bold markers stripped"; else bad "bold markers stripped" "$stripped"; fi
if [[ "$stripped" != *'`'* ]]; then ok "backtick markers stripped"; else bad "backtick markers stripped" "$stripped"; fi
if [[ "$stripped" == *$'\n''[code]'$'\n'* ]]; then ok "a fenced code block collapses to [code]"; else bad "[code] collapse" "$stripped"; fi
if [[ "$stripped" == *'[table]'* ]]; then ok "a run of | lines collapses to [table]"; else bad "[table] collapse" "$stripped"; fi
if [[ "$stripped" == *$'\n''- first bullet'* && "$stripped" == *$'\n''- second bullet'* ]]; then
    ok "* and + bullets both normalize to \"- \""
else
    bad "bullet normalization" "$stripped"
fi

long_reply_lines=()
for i in $(seq 1 10); do long_reply_lines+=("paragraph number $i with enough words to wrap across more than one line at a narrow width"); done
long_reply=$(printf '%s\n\n' "${long_reply_lines[@]}")
mkdir -p "$work/snapshot" "$work/flags"
mtime_now=$(date +%s)
long_reply_json=$(jq -Rn --arg t "$long_reply" '$t | tojson')
printf '%s\t%%9\t1\tclaude\tidle\t-\t%s\t-\tyou\t"long reply pane"\t-\t%s\t-\t-\t/home/user/long\n' \
    "longpane" "$mtime_now" "$long_reply_json" > "$work/snapshot/turns.tsv.body"
{ printf '# generated 2026-01-01T00:00:00Z\n'; cat "$work/snapshot/turns.tsv.body"; } > "$work/snapshot/turns.tsv"
load_data
idx=-1
for i in "${!p_session[@]}"; do [[ "${p_session[$i]}" == longpane ]] && idx="$i"; done
if (( idx >= 0 )); then
    frame_rows=()
    append_block_body "$idx" 40 false
    it_lines=0
    marker_seen=false
    for l in "${frame_rows[@]}"; do
        [[ "$l" == *'it  ›'* || ( "$it_lines" -gt 0 && "$l" == '       '* ) ]] && it_lines=$(( it_lines + 1 ))
        [[ "$l" == *'(+'*'lines)'* ]] && marker_seen=true
    done
    check "the it › reply section is capped at 4 lines" "$it_lines" "4"
    if [[ "$marker_seen" == true ]]; then ok "overflow shows a (+N lines) marker"; else bad "(+N lines) marker" "not found"; fi
else
    bad "long-reply fixture pane not loaded" "-"
fi

echo "── buckets and their order"
mkdir -p "$work/flags"
mtime_a=$(( mtime_now - 10 ))
mtime_b=$(( mtime_now - 20 ))
mtime_c=$(( mtime_now - 5 ))
{
    printf '# generated 2026-01-01T00:00:00Z\n'
    printf 'needsyou\t%%1\t1\tclaude\tpermission\t-\t%s\t-\tyou\t"-"\t-\t-\t-\t"-"\t-\n' "$mtime_a"
    printf 'doneflag\t%%2\t1\tclaude\tidle\t-\t%s\t-\tyou\t"-"\t-\t-\t-\t-\t-\n' "$mtime_b"
    printf 'working1\t%%3\t1\tclaude\tworking\t-\t%s\t-\t-\t-\t-\t-\t-\t-\t-\n' "$mtime_c"
    printf 'idlepane\t%%4\t1\tclaude\tidle\t-\t%s\t-\t-\t-\t-\t-\t-\t-\t-\n' "$mtime_now"
} > "$work/snapshot/turns.tsv"
touch "$work/flags/doneflag@2.done"
load_data
want_buckets="NEEDS YOU DONE WORKING IDLE"
got_buckets=""
for i in ${order[@]+"${order[@]}"}; do got_buckets+="${p_bucket[$i]} "; done
check "bucket order: NEEDS YOU, DONE, WORKING, IDLE" "$got_buckets" "NEEDS YOU DONE WORKING IDLE "
check "counts: 1 needs you" "$n_needs" "1"
check "counts: 1 done" "$n_done" "1"
check "counts: 1 working" "$n_working" "1"
check "counts: 1 idle" "$n_idle" "1"

echo "── cursor highlight covers the whole block, not just the headline"
COLUMNS=100 LINES=40 build_frame
if (( ${#cursor_map[@]} >= 1 )); then
    # needsyou (the first block) carries a "you › -" body row, so a correct
    # highlight must span 2 rows: the headline and that body line.
    selected=0
    selected_idx="${cursor_map[0]}"
    frame_cursor_line="${frame_row_line[0]}"
    SEL="<<SEL>>"; RST="<<RST>>"
    painted=$(COLUMNS=100 LINES=40 paint)
    SEL=""; RST=""
    hl_lines=$(grep -c '<<SEL>>' <<< "$painted")
    check "a block with a body row highlights headline + body (2 rows)" "$hl_lines" "2"
    if [[ "$painted" == *'<<SEL>>  you › -'$'\033[K''<<RST>>'* ]]; then
        ok "the body row itself is inside the highlight, not just the headline"
    else
        bad "body row highlight" "$painted"
    fi
    if [[ "$painted" != *'<<SEL>>'*'DONE'*'<<RST>>'* ]]; then
        ok "the highlight stops before the next bucket's section label"
    else
        bad "highlight bled into the next section label" "$painted"
    fi

    # The last block overall (idlepane) has no body row: a 1-row highlight.
    selected=$(( ${#cursor_map[@]} - 1 ))
    selected_idx="${cursor_map[$selected]}"
    frame_cursor_line="${frame_row_line[$selected]}"
    SEL="<<SEL>>"; RST="<<RST>>"
    painted_last=$(COLUMNS=100 LINES=40 paint)
    SEL=""; RST=""
    hl_lines_last=$(grep -c '<<SEL>>' <<< "$painted_last")
    check "a block with no body row highlights only its headline (1 row)" "$hl_lines_last" "1"
else
    bad "cursor_map empty, cannot test the cursor highlight" "-"
fi

rm -f "$work/flags/doneflag@2.done"

echo "── --dump and --dump --detail"
dump_out=$("$repo/bin/hq-feed" --dump 2>&1)
if [[ "$dump_out" == *'NEEDS YOU'* ]]; then ok "--dump renders the NEEDS YOU section"; else bad "--dump output" "$dump_out"; fi
if [[ "$dump_out" == *'needsyou'* ]]; then ok "--dump shows the needs-you pane"; else bad "--dump pane" "$dump_out"; fi
if [[ "$dump_out" == *'IDLE'* ]]; then ok "--dump shows IDLE expanded by default"; else bad "--dump IDLE section" "$dump_out"; fi
if [[ "$dump_out" == *'idlepane'* ]]; then ok "--dump shows the idle pane itself, not just a count"; else bad "--dump idle pane" "$dump_out"; fi
if [[ "$dump_out" != *'hidden — a to show'* ]]; then ok "--dump does not collapse IDLE to a count line"; else bad "--dump IDLE collapsed" "$dump_out"; fi
detail_out=$("$repo/bin/hq-feed" --dump --detail %4 2>&1)
if [[ "$detail_out" == *'idlepane'* ]]; then ok "--dump --detail renders the named pane"; else bad "--dump --detail" "$detail_out"; fi
bad_detail=$("$repo/bin/hq-feed" --dump --detail %999 2>&1; echo "rc=$?")
if [[ "$bad_detail" == *'rc=1'* ]]; then ok "--dump --detail on an unknown pane exits 1"; else bad "unknown pane" "$bad_detail"; fi

echo "── LIST caps a long multi-line prompt instead of bash \${var//} over it"
biglines=()
for i in $(seq 1 700); do
    biglines+=("$(printf 'line %04d of a padded prompt line to add length' "$i")")
done
bigprompt=$(printf '%s\n' "${biglines[@]}")
bigsize=${#bigprompt}
if (( bigsize >= 30000 )); then
    ok "long-prompt fixture is >= 30 KB ($bigsize bytes)"
else
    bad "long-prompt fixture size" "$bigsize bytes"
fi
big_json=$(jq -Rnr --arg t "$bigprompt" '$t | tojson')
{
    printf '# generated 2026-01-01T00:00:00Z\n'
    printf '%s\t%%8\t1\tclaude\tworking\t-\t%s\t-\tyou\t%s\t-\t-\t-\t-\t/home/user/big\n' \
        "bigpromptpane" "$mtime_now" "$big_json"
} > "$work/snapshot/turns.tsv"
t0=$SECONDS
load_data
elapsed_load=$(( SECONDS - t0 ))
idx=-1
for i in "${!p_session[@]}"; do [[ "${p_session[$i]}" == bigpromptpane ]] && idx="$i"; done
if (( idx >= 0 )); then
    nl_file="$work/bigprompt.raw"
    printf '%s' "${p_prompt[$idx]}" > "$nl_file"
    nl_count=$(tr -dc '\n' < "$nl_file" | wc -c)
    nl_count="${nl_count//[[:space:]]/}"
    if (( nl_count > 500 )); then
        ok "load_data decodes real newlines into p_prompt, not literal \\n ($nl_count newlines)"
    else
        bad "p_prompt newline count" "$nl_count"
    fi

    frame_rows=()
    t0=$SECONDS
    append_block_body "$idx" 80 false
    elapsed_block=$(( SECONDS - t0 ))
    you_lines=0
    for l in "${frame_rows[@]}"; do [[ "$l" == *'you ›'* ]] && you_lines=$(( you_lines + 1 )); done
    check "a >=30KB multi-line prompt renders as exactly one you › line in LIST" "$you_lines" "1"
    if (( ${#frame_rows[0]} < 200 )); then
        ok "the LIST line is clipped, not the raw 30+ KB prompt (${#frame_rows[0]} chars)"
    else
        bad "LIST line length" "${#frame_rows[0]} chars"
    fi
    if (( elapsed_block <= 2 )); then
        ok "append_block_body over the long prompt completes in <=2s (was ~28s/29KB pre-fix)"
    else
        bad "append_block_body elapsed" "${elapsed_block}s"
    fi
else
    bad "long-prompt fixture pane not loaded" "-"
fi
# The pre-fix bug ran bash's quadratic ${var//$'\n'/ } over the UNCAPPED
# prompt on every LIST repaint: 29 KB measured at 28.3s. 5s is generous
# slack for a correct, jq-capped pass over 30+ KB.
if (( elapsed_load <= 5 )); then
    ok "load_data over the long prompt completes in <=5s"
else
    bad "load_data elapsed" "${elapsed_load}s"
fi

t0=$SECONDS
dump_big=$("$repo/bin/hq-feed" --dump 2>&1)
elapsed_dump=$(( SECONDS - t0 ))
if [[ "$dump_big" == *'bigpromptpane'* ]]; then
    ok "--dump renders the long-prompt pane"
else
    bad "--dump long-prompt pane" "$dump_big"
fi
if (( elapsed_dump <= 5 )); then
    ok "--dump over the long-prompt snapshot completes in <=5s"
else
    bad "--dump elapsed" "${elapsed_dump}s"
fi

echo "── the highlight fills edge-to-edge: SEL survives a row's own resets"
# A row's own color resets (a DIM label, an OSC 8 link's reset) each clear
# SEL's background partway through the line unless every reset reopens it.
# This needs REAL escape codes, not the sentinel strings the earlier cursor
# tests use — set before build_frame so they're baked into frame_rows the
# way a real terminal would. Last in the file: it overwrites turns.tsv and
# nothing after it depends on the shared fixture.
link_json=$(jq -Rn --arg t 'see https://github.com/acme/widgets/pull/42 for details' '$t | tojson')
{
    printf '# generated 2026-01-01T00:00:00Z\n'
    printf 'linkpane\t%%5\t1\tclaude\tidle\t-\t%s\t-\tyou\t"-"\t-\t%s\t-\t-\t-\n' "$mtime_now" "$link_json"
} > "$work/snapshot/turns.tsv"
RST=$'\033[0m'; SEL=$'\033[48;5;236m'; DIM=$'\033[2m'
LINK=$'\033[34;4m'; LINKS=true
C_NEEDS=$'\033[33m'; C_DONE=$'\033[32m'; C_WORKING=$'\033[34m'
load_data
COLUMNS=60 LINES=40 build_frame
if (( ${#cursor_map[@]} >= 1 )); then
    selected=0
    selected_idx="${cursor_map[0]}"
    frame_cursor_line="${frame_row_line[0]}"
    painted=$(COLUMNS=60 LINES=40 paint)

    # A correctly-filled highlighted line is SEL, then the row text with
    # every internal reset immediately reopening SEL, then erase-to-EOL,
    # then the one reset that's allowed to stay bare (the final close).
    check_hl_edge_to_edge() {
        local line="$1" label="$2" body stripped
        if [[ "$line" == *$'\033[K'"$RST" ]]; then
            ok "$label ends with erase-to-EOL then the final reset"
        else
            bad "$label suffix" "$(cat -v <<< "$line")"
        fi
        body="${line%$'\033[K'"$RST"}"
        body="${body#"$SEL"}"
        stripped="${body//"$RST$SEL"/}"
        if [[ "$stripped" != *"$RST"* ]]; then
            ok "$label has no internal reset left unfilled"
        else
            bad "$label leaves a bare reset (background drops mid-line)" "$(cat -v <<< "$line")"
        fi
    }

    body_line=$(grep -F "${DIM}you" <<< "$painted")
    if [[ -n "$body_line" ]]; then
        check_hl_edge_to_edge "$body_line" "the DIM you › body row"
    else
        bad "no DIM you › row found in the painted frame" "$(cat -v <<< "$painted")"
    fi

    link_line=$(grep -F '#42' <<< "$painted")
    if [[ -n "$link_line" ]]; then
        check_hl_edge_to_edge "$link_line" "the it › row with a PR link"
    else
        bad "no PR link row found in the painted frame" "$(cat -v <<< "$painted")"
    fi
else
    bad "cursor_map empty, cannot test edge-to-edge fill" "-"
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
