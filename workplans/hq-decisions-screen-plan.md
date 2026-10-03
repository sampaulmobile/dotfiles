# Workplan: hq-decisions LIST + DETAIL screen

## Restatement

- Task: replace `bin/hq-decisions`' wrapped cards with two views: a flat
  one-line-per-decision LIST, and a full-screen DETAIL of one decision. Also
  give `bin/hq-decision` an optional `--why` (the recommendation's rationale)
  that the DETAIL shows.
- Done means: the brief's ACCEPTANCE holds. `--dump` (LIST) and
  `--dump --detail <id>` render the fixture kinds the brief lists, and
  `tests/run.sh` passes.
- Assuming: the record reader, the seen stamp and the loop's read-timeout
  handling carry over unchanged. Only the rendering and the key handling are
  new.

## Digest

- Task: rewrite `bin/hq-decisions`' rendering and view loop into LIST
  (sections OPEN / AUTO-TAKEN / ANSWERED, one unwrapped line per decision,
  width-fitted columns, the title taking the slack, scrolling with a fixed
  header and footer) and DETAIL (state line, wrapped title, CONTEXT, OPTIONS
  with ★/●/✓ and `why`, a TO ANSWER / TO REVERSE bar, J/K, `o`, `g`). Add
  `hq-decision add|update --why TEXT`.
- Done means: the brief's ACCEPTANCE bullets. `tests/run.sh` is green. The
  manual `--dump` / `--dump --detail` output at 80 and 160 columns and one
  `script -q` run of the loop go in the PR body.
- Not doing: any edit to `bin/hq-inbox`, the dashboard, tmux.conf, skills or
  rules. No record field other than `why`. Not doing mockup E's "why it was
  taken for you" checklist (no record field holds it; the brief's text
  governs). No split view (mockup D). No rebase onto master.
- Assuming (choices the brief leaves open; ASSUMED, the requester's go
  verifies them):
  1. Counting: AUTO-TAKEN = answered with `by: auto`, and ANSWERED = answered
     with `by: owner`. An auto answer the owner reversed is therefore counted
     under ANSWERED.
  2. The header's "store's age" is `updated <age> ago`, taken from the newest
     `updated` across the records. It is omitted for an empty store, and
     dropped when the header does not fit the width.
  3. `--dump` mirrors the first screen, so answered rows are hidden. A new
     `--answered` flag shows them, the dump's stand-in for pressing `a`.
     Tests and the PR body use it.
  4. The LIST gets a 2-column cursor gutter (`›` on the cursor row, blank
     otherwise) on top of the colour highlight. Without it, the cursor is
     invisible under NO_COLOR. There is also a dim column-label row (AGE
     WHERE DECISION ASKED BY RECOMMENDS), as in mockup A.
  5. The DETAIL body scrolls with j/k when it is taller than the terminal.
     The bottom bar and the footer stay fixed, and `↑/↓ N more` shows when
     clipped. j/k is listed in `--help` only, so the footer stays as the
     brief's text.
  6. Esc returns to the LIST with the cursor on the decision DETAIL was last
     showing (after J/K, that is the stepped-to one). The cursor follows its
     decision id across a reload, not a row index.
  7. A record whose `session` is `-` shows `the hub` in the bottom bar, and
     `g` reports `no hub session`.
- Surface: `tests/run.sh` (one pass, since both bashes are 3.2 here).
  `--dump` / `--dump --detail` over a scratch store at COLUMNS=80/160. One
  `script -q` run of the interactive loop.
- Touches: 4 files plus docs. `bin/hq-decisions` (rewrite),
  `bin/hq-decision` (`--why`), `tests/test-hq-decisions.sh`,
  `tests/test-hq-decision.sh`, and CLAUDE.md (both entries and the tests
  line).
- Question: none. The seven choices above are the requester's to veto.

Reading the code changed: the brief's `decisions_records` is
`decision_records` (in `bin/hq-decision`). `printf '%-Ns'` in bash 3.2 pads
by BYTES (`★` is 3), and under a non-UTF-8 locale `${#x}` counts bytes too.
Column padding therefore has to be done by hand, and the script must ensure
a UTF-8 `LC_CTYPE`. `bin/hq-inbox` is not sourceable next to this script
because of name clashes, so `other_client` is copied (about 10 lines).

## Approach

### `bin/hq-decision` — `--why`

- `add --why TEXT` puts `why` into the record only when TEXT is non-empty.
  Old records and records added without it carry no `why` key.
- `update ID --why TEXT` sets it, built the same way as `has_title`.
- `--help`: the usage lines and a `why` line under Record fields. Nothing
  else changes. `decision_records` passes the field through untouched.

### `bin/hq-decisions` — kept

`decision_records` (sourced), `decisions_seen_file` /
`decisions_read_seen_cutoff` / `decisions_write_seen`, `wrap_text`, `clip`,
`card_age` (or a renamed `age_of`), `decisions_signature`, `term_size`
(including the `stty size </dev/tty` step), the BASH_SOURCE guard (sourcing
runs nothing, reads no dir and creates no dir), and the loop's
`read -rsn1 -t 2` together with its exact rc handling (bash 3.2 returns 1 on
timeout, which counts as the idle tick when stdin is a tty).

### Data

`load_data` keeps its single `decision_records` call and single `jq` → TSV
pass. It adds the fields `why` and `updated`, plus `label` of the
recommended and the answered option (resolved in the same jq call, so no
per-row jq at paint time). It keeps the TSV invariant: an empty field is
written as `-` and mapped back. Three ordered index arrays:
- `open_order`: open, newest `created` first.
- `auto_order`: answered `by=auto`. Unseen (answer.at > SEEN_CUTOFF_EPOCH)
  first, then seen, newest `answer.at` first within each group.
- `ans_order`: answered `by=owner`, newest `answer.at` first.

It also records the counts `n_open`, `n_auto`, `n_answered` and
`n_unseen_auto`, and the newest `updated` epoch. Options are still carried
per record as base64 JSON. DETAIL expands them, one jq per DETAIL build,
never per LIST paint.

Locale: near the top, if `LC_ALL`/`LC_CTYPE`/`LANG` don't resolve to UTF-8,
export `LC_CTYPE=en_US.UTF-8` (or `C.UTF-8` when that one is present). This
keeps `${#x}` and `${x:0:n}` character-based. Every pad goes through a
`pad <text> <width>` helper built on `${#}`, never `printf %-Ns`.

### LIST view

Layout, top to bottom. The header block and the footer block are fixed; the
body scrolls.

1. Header: `DECISIONS  <o> open · <a> auto-taken · <n> answered`, then
   `  ● <k> auto-taken since you last looked` (teal) when k > 0, then
   `updated <age> ago` right-aligned when it fits.
2. Blank line.
3. Column labels (dim): gutter, `AGE`, `WHERE`, `DECISION`, `ASKED BY`,
   `RECOMMENDS`, at the computed widths.
4. Body: sections in the order OPEN (`OPEN · needs you`), AUTO-TAKEN
   (`AUTO-TAKEN · taken for you, say so to reverse`), ANSWERED (only when
   shown). Section labels are dim, there is a blank line between sections,
   and a section with no rows is omitted. An empty store prints
   `no decisions recorded`.
5. Status line (`STATUS_NOTE`, blank when none).
6. Footer: `j/k move · ⏎ open · a show/hide answered · g jump to hub · q quit`.

Row: `<gutter 2><AGE right-aligned 4>  <WHERE>  <TITLE>  <ASKED BY>  <LAST>`.
- AGE is measured from `created` for open rows and from `answer.at` for the
  others. Amber (33) for open, teal (36) for auto, dim for answered.
- WHERE is `<repo> #<pr>` or `<repo> <branch>`, with the repo bold.
- TITLE is bold for open, normal for auto, dim for answered.
- ASKED BY is the session, dim.
- LAST: open → `★ <rec> · <rec label>` (amber); auto → `● <opt> · auto`
  (teal); answered → `✓ <opt> · you` (green 32). Answered rows are dim
  overall.
- Widths are recomputed at every build_frame from `term_w`. WHERE, ASKED BY
  and LAST each take the max content width of the rows on screen, capped at
  28, 18 and 32. TITLE gets everything left over. When TITLE would drop
  below 12, shrink LAST, then ASKED BY, then WHERE, each down to a floor of
  6. Every field is clipped with `clip` (…) to its width. INVARIANT: no
  rendered line's display width exceeds `term_w`, given `term_w` ≥ 40.
  Below 40 each line is clipped whole as plain text.
- Cursor row: `› ` in the gutter plus SEL background when colour is on.
  `--dump` has no cursor, so every gutter is blank.
- Scrolling: body height is `term_h` minus header rows (3) minus status and
  footer (2). `frame_top` adjusts so the cursor row is always within
  [top, top+body). `↑ N more · ↓ M more` replaces the status line when the
  body is clipped and there is no note.
- Cursor moves across all visible sections, skipping section labels and
  blanks. It is tracked by decision id (`selected_id`) so a reload or an `a`
  toggle keeps it on its decision. If its row is hidden (answered toggled
  off), the cursor falls to the nearest row.

### DETAIL view (⏎ on a row)

Fixed top:
1. `‹ esc  back to list` left; `decision <i> of <n> <section>` right
   (section ∈ `open` / `auto-taken` / `answered`).
2. State word (`OPEN` amber, `● AUTO-TAKEN` teal, `✓ ANSWERED` green) ·
   repo (bold) · `#pr` or branch · `asked <age> ago by <session>` (open) /
   `taken …` (auto) / `answered …` (owner) · id.

Scrolling body (j/k when taller than the screen):
3. Blank line, then the title in bold, wrapped to `term_w`.
4. `CONTEXT` (dim label), then the context wrapped at `min(term_w, 100)`.
   The section is omitted when the context is empty.
5. `OPTIONS` (dim label), then one block per option, with a blank line
   between blocks. Width is `min(term_w, 100)`.
   - Head: `<mark> <id>  <label><suffix>`. The mark column is 2 wide.
   - Description: wrapped, indented to align under the label.
   - Open: the recommended option has mark `★`, suffix ` · recommended`, and
     an amber + bold head (SEL background when colour is on). When the
     record has `why`, a `why: <text>` paragraph (wrapped, indented the same)
     follows its description.
   - Answered: the chosen option is marked `●` (auto, teal) or `✓` (owner,
     green), with suffix ` · was the recommendation` when it equals
     `recommend`, else ` · owner chose`. Under it come
     `note: <note>` (when non-empty) and `answered <age> ago` /
     `taken <age> ago`. When the chosen option is not the recommended one,
     the recommended option still shows `★ … · recommended`, and `why` stays
     with the recommended option.

Fixed bottom:
6. Bar (wrapped to `term_w`, label dim):
   - open → `TO ANSWER  tell <session> "go with <rec>" — it records: hq-decision answer <id> <rec>`
   - auto → `TO REVERSE  tell <session> "reverse <id>, <other> instead" — it re-records as yours: hq-decision answer <id> <other>`,
     where `<other>` is the first option id ≠ the chosen one.
   - answered → `answered by you <age> ago`.
   - `<session>` of `-` renders as `the hub`.
7. Status line.
8. Footer: `J/K next/prev decision · o open PR · g jump to <session> · q quit`.

Keys in DETAIL:
- J/K step to the next/previous decision of the SAME section order, staying
  in DETAIL and clamping at the ends.
- esc (`$'\e'`) or backspace (`$'\x7f'` / `$'\b'`) returns to the LIST.
  Arrow-key bytes that follow an esc land as unbound keys and are ignored.
- j/k scroll the body.
- `o`, `g`, `q` as below.

### `o` — open the PR

`decisions_repo_dir <repo>`: source `bin/project-dirs-lib`, call
`project_dirs`, and pick the first entry whose basename is `<repo>` and
whose `.git` is a directory. `git -C <dir> remote get-url origin`
(read-only). `decisions_pr_url <origin> <pr>` is a PURE function: it maps
`git@github.com:o/r(.git)`, `ssh://git@github.com/o/r(.git)` and
`https://github.com/o/r(.git)` to `https://github.com/o/r/pull/<pr>`, and
returns empty for anything else. Then `open <url>`. No pr, no dir, or no URL
→ `STATUS_NOTE="no PR"`. `o` also works from the LIST on the cursor row.

### `g` — jump to the hub

Copy `other_client` from `bin/hq-inbox` verbatim (one comment naming its
origin is not needed; a one-line purpose comment is). `go_to_hub <session>`:
`-`/empty → `no hub session`; `tmux has-session -t "=<s>"` fails →
`<s> is not running`; no other client → `no other client — the hub is <s>`;
else `tmux switch-client -c "$tty" -t "=<s>"` and
`STATUS_NOTE="sent <tty> to <s>"`. Works from both views. The only tmux
subcommands in the file: `display`, `list-clients`, `has-session`,
`switch-client -c`.

### Loop

Shape as before: `load_data` → cached `build_frame` (LIST or DETAIL,
depending on `view_mode`) → `paint`. A cursor move or a DETAIL scroll calls
`paint` only. `build_frame` reruns on a data change (signature), a resize, a
30s-old frame, an `a` toggle, entering or leaving DETAIL, and J/K. The
idle-tick branch stays character-for-character equivalent to the current
one. The seen stamp is still written once, right after the first paint, and
never by `--dump`. Status notes clear on the next key.

`paint` composes the screen into a variable (`screen_out`) and prints it
with the clear prefix, so a test can source the script and inspect
`screen_out` without a terminal.

### Entry

- `--dump [--answered]`: LIST at `${COLUMNS:-100}` (no tty probe), every
  body row, no cursor, no status line, footer included, no seen write.
- `--dump --detail <id>`: that DETAIL at `${COLUMNS:-100}`, the whole body
  unclipped. Unknown id → stderr `hq-decisions: no such decision '<id>'`,
  exit 1.
- No argument runs the loop. Anything else → usage, exit 2.

### Docs

- `--help` (usage) of both scripts: layout, columns, sections, keys for both
  views, the `--dump` flags, the seen cutoff (kept), `o`/`g`, and the tmux
  set.
- CLAUDE.md: rewrite the `bin/hq-decisions` entry. It is no longer
  tmux-free: name `g`'s subcommand set and `o`'s read-only git and project
  lookup, and keep the loop-shape sentence and the one-write invariant. Add
  `--why` to the `bin/hq-decision` entry, and update the tests line's
  hq-decisions clause. Follow the comments rule: no history, no
  justification. The file header follows the same rule.

## Ordered steps

1. `hq-decision --why` with its tests (add with and without it, update sets
   it, old record has no key). Commit.
2. hq-decisions data layer (load_data fields, three orders, counts, locale,
   `pad`), then the LIST frame and `--dump [--answered]`, with tests. Commit.
3. DETAIL frame and `--dump --detail`, with tests. Commit.
4. View loop: modes, keys, scroll, `o`, `g`, status line, and the
   `screen_out` scroll test. Commit.
5. `--help` and CLAUDE.md. Commit.
6. Manual VERIFY. Save the output under `.feature/verify/` for the PR body.

## Test plan

Extend `tests/test-hq-decisions.sh` (replace the card assertions, keep the
sourcing, seen-stamp, wrap_text and read-only assertions) and
`tests/test-hq-decision.sh`. Fixtures are written via `hq-decision add` /
`answer` into the mktemp store, plus one hand-written old record with
neither `why` nor `answer.by`:
- open with `why`, and open without `why`
- auto-taken (`answer --auto`)
- owner-answered on a non-recommended option
- the old record
- a 200-char title

Assertions:
- LIST at COLUMNS=80 and 160: every line's `wc -m` ≤ width. The 200-char
  title's row ends with `…` at both widths, and at 160 its title column is
  wider than at 80. Each decision is exactly one line (its id-unique title
  prefix appears once).
- Section order, headers and counts: header line text,
  `● 1 auto-taken since you last looked`, OPEN before AUTO-TAKEN, ANSWERED
  absent without `--answered` and present with it.
- LAST column text per kind: `★ <rec> · <label>`, `● <opt> · auto`,
  `✓ <opt> · you`. The old record shows `✓ … · you`.
- `--dump --detail`:
  - open with `why`: `★` + `· recommended`, and the `why:` text follows it.
  - open without `why`: no `why:` line.
  - auto: `● AUTO-TAKEN`, `· was the recommendation`, TO REVERSE naming the
    other option.
  - owner on non-rec: `✓ ANSWERED`, `· owner chose`, the note, and the ★ on
    the recommended option.
  - old record: renders as owner, no `why:`.
  - unknown id exits 1.
- Scrolling: source the script with a store of 30 open records, LINES=20,
  COLUMNS=100. Set the cursor to the last row, build and paint. `screen_out`
  has ≤ 20 lines, its first line is the header, its last is the footer, and
  the `›` line is the last record's. Then move the cursor to row 0 and
  repaint: the `›` line is the first record's.
- `decisions_pr_url` on the ssh, ssh://, https(.git) forms and a non-GitHub
  origin.
- The tmux grep: no tmux subcommand outside {display, list-clients,
  has-session, switch-client}, and every switch-client carries `-c`. The
  deletion grep is kept.
- `--dump` still writes no `_state/seen`.

## Out of scope

Mockups B and D; the auto-take checklist panel; any snapshot source;
wiring the screen to a key or session; editing `bin/hq-inbox`, skills,
rules or templates; any new record field but `why`.

## Assumptions

- VERIFIED: base is `feat/hq-decisions` at 3deefa1 (`git merge-base` =
  HEAD).
- VERIFIED: `decision_records` is the one reader and normalises a missing
  `answer.by` to owner (`bin/hq-decision:146`).
- VERIFIED: bash 3.2 `printf %-4s "★"` pads to 2 visible columns (pads by
  bytes), and under `LC_ALL=C` `${#"★●"}` is 6. So pads are manual and the
  locale is forced to UTF-8.
- VERIFIED: hq-inbox's `go_to_hub` / `other_client` shape
  (`bin/hq-inbox:495-527`), and that its file is not co-sourceable (it
  defines `load_data`, `build_frame`, `term_size`, `clip` and `usage`).
- ASSUMED: choices 1–7 in the digest, verified by the requester's go.
