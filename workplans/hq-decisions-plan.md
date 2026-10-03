# Workplan: hq decision records

## Restatement

- Task: give hub/hq sessions a CLI that records an owner-decision (title,
  context, options, recommendation) as one JSON file, plus a read-only screen
  that lists every open decision across hubs, and replace the skills'
  inbox-append rule with "record the decision, quote its id".
- Done means: `bin/hq-decision` (add/update/answer/list, deduped, append-only)
  and `bin/hq-decisions` (cards, `--dump`) exist with tests passing under both
  bashes; the three skill/template files carry the new rule and no
  inbox-append rule; CLAUDE.md lists both scripts.
- Assuming: nothing else consumes the inbox thread logs' new entries (the
  inbox screen keeps reading whatever logs exist); `jq` is installed
  everywhere the hub runs.

## Digest

- Task: `bin/hq-decision` CLI (one JSON file per decision, dedupe on key,
  tmp+mv, removes nothing) + `bin/hq-decisions` screen (open cards, answered
  folded, `--dump`) + the record-a-decision rule replacing the inbox-append
  rule in the feature skill, hq skill and hq template.
- Done means: the five ACCEPTANCE lines of the brief; `tests/run.sh` green.
- Not doing: hq-inbox / dashboard / Ctrl+Y / tmux.conf / keybinding wiring,
  hooks, any snapshot source, a tmux session for the screen, editing
  `bin/hq-inbox` or its CLAUDE.md entry, private skill copies.
- Assuming: jq 1.6 is the floor (this machine's) — only 1.6 builtins.
- Surface: `tests/run.sh` (both bashes; here both are 3.2 — one pass);
  `hq-decision add/update/answer/list` and `hq-decisions --dump` against a
  scratch `HQ_DECISIONS_DIR` in the session scratchpad.
- Touches: 2 new bin scripts, 2 new test suites, `tests/run.sh`, CLAUDE.md,
  `dots/claude/skills/{feature,hq}/SKILL.md`, `templates/hq/CLAUDE.md`.
- Question: `templates/hq/CLAUDE.md` also has a READ rule ("read the inbox
  thread files under `~/.local/state/hq/inbox/` before `state/backlog.md`").
  With the append rule gone nothing new lands there, so I will replace it with
  "`hq-decision list --open` and `pipelines.tsv` before `state/backlog.md`".
  Say if you would rather leave that line untouched.

Reading the code changed: the inbox view loop blocks on `read -rsn1` with no
timeout, so "repaint on data change" needs an integer `read -t` idle tick
here (bash 3.2 rejects fractional timeouts).

## Approach

### `bin/hq-decision` (CLI, sourceable)

- Storage: `DECISIONS_DIR="${HQ_DECISIONS_DIR:-$HOME/.local/state/hq/decisions}"`,
  one file per decision at `<dir>/<repo>/<UTC-stamp>-<id>.json`, stamp
  `date -u +%Y%m%dT%H%M%SZ`. Id: 6 lowercase hex from `/dev/urandom`,
  regenerated if a file `*-<id>.json` already exists anywhere under the dir.
  Lookup by id: glob `<dir>/*/*-<id>.json`.
- Every write: `mkdir -p <dir>/<repo>`, write `<file>.tmp.$$`, `mv` over the
  target. A failed write leaves the tmp file; nothing is ever removed (no
  `rm`, `rmdir`, `unlink`, `find -delete` in the file — the test greps).
- Record (jq-built, never string-concatenated):
  `{id, key, repo, pr (number|null), branch (string|null), title, context,
  options:[{id,label,description}], recommend, session, created, updated,
  state:"open"|"answered", answer:null|{option,note,at}}`. Times are
  `date -u +%Y-%m-%dT%H:%M:%SZ`. `session` is the `--session` value, else
  `tmux display -p '#S'` when `$TMUX` is set, else `"-"`.
- `add`: required `--repo` (no `/`, not `.`/`..`), `--title`, 2+ `--option
  'id|label|description'` (split on the first two `|`; id and label
  non-empty; ids unique), `--recommend` naming one option id. `--pr` and
  `--branch` mutually exclusive, both optional. `--context` or
  `--context-file F` (`-` = stdin). Any violation → message on stderr naming
  the fix, exit 2, nothing written.
  - Key = `--key` or `<repo>:<pr-or-branch-or-->:<slug(title)>`; slug =
    lowercase, runs of non-alnum → `-`, trimmed.
  - DEDUPE: an OPEN record with the same key → print its id on stdout, a
    stderr note "already open as <id> — use update", exit 0, write nothing.
    ANSWERED records never match.
  - Then warn on stderr listing other OPEN records on the same repo and the
    same pr/branch (different key) — likely a reworded title.
  - Success prints the new id.
- `update <id> [--title] [--recommend] [--context|--context-file]
  [--option ...]`: open records only (answered → exit 1 with a message).
  Any `--option` replaces the whole list (2+ again). `--recommend` must
  still name an option after the update. Bumps `updated`. Unknown id → exit 1.
  The key is not recomputed on a title change (the id is the handle).
- `answer <id> <option-id> [note...]`: option must exist; sets state
  `answered`, `answer {option, note, at}`, bumps `updated`. Answering an
  already-answered record re-stamps the answer and notes so on stderr.
- `list [--open] [--repo R] [--json]`: table `ID STATE REPO PR/BRANCH AGE
  TITLE`, open first, newest first; `--json` prints the matching records as
  one JSON array.
- Record reading in ONE place: `decision_records [--open] [--repo R]`
  emits every record as a compact JSON line via ONE jq call over all files
  (not one per file); `list`, dedupe and the screen all consume it.
- Sourceable: a `BASH_SOURCE` guard runs the command line only when
  executed. Exit codes and flags in `--help`.

### `bin/hq-decisions` (screen, read-only)

- Sources `bin/hq-decision` for `decision_records` and the dir; no tmux
  calls at all; terminal size from `$COLUMNS/$LINES`, then `tput`.
- No arg → view loop in this terminal; `--dump` renders once and exits;
  `--help` is the column/key/format reference.
- `load_data`: one `decision_records` call, then one jq pass flattening each
  record into tab-separated fields (empty → `-`, the TSV invariant; context
  newlines and tabs escaped), into `r_*` arrays. Open sorted by `created`
  newest first, answered by `answer.at` newest first.
- `build_frame` (cached): header `DECISIONS  N open · M answered`; one card
  per OPEN decision, expanded by default:
  - line 1: `repo #pr` or `repo branch` · title · age · session
  - context word-wrapped to the width, indented
  - options, one per line, `id  label — description`, the recommended one
    marked `★ … (recommended)` and bold/colored; descriptions wrapped
  - collapsed card = line 1 only
  - ANSWERED section below (toggled by `a`, shown by default): one line
    each, `repo ref · title · → <option label> · age`; Enter expands to the
    note and the options.
  - zero decisions: `no decisions recorded`.
- `render`: cursor lands on cards; scroll keeps the cursor card's first line
  (and the section header) in view, as hq-inbox does; selected card's first
  line highlighted.
- Loop: `read -rsn1 -t 2`; on a key, act; on timeout compare a cheap
  signature (`ls -lnT` of the dir's json files — one fork) and reload on
  change; rebuild on resize or a 30s-old frame. Keys: j/k, Enter/space,
  a, q. Enter arrives as empty string, space as " ".
- Word wrap is a pure bash function (`wrap_text <text> <width>`), tested.

### Skill/template rule (one short paragraph, same words in each)

> A decision that is the owner's call never goes into chat without a record:
> run `~/dotfiles/bin/hq-decision add` first (flags in its `--help`), with
> the options and your recommendation, then tell the user and quote the id.
> Revisiting it means `update <id>` or `answer <id>`, never a second `add`;
> when the owner answers in chat, run `hq-decision answer <id> <option>`.
> Never ask it modally — the record and the chat line are the whole ask.

- `dots/claude/skills/feature/SKILL.md`, requester side: delete the
  inbox-entry paragraph and every "append" clause tied to it ("Append it,
  then relay", "gets appended", "nothing to relay or append", "append it,
  then relay to the user"); add the rule. The `backlog` lesson's "inbox
  item" is the hq backlog, unrelated, and stays.
- `dots/claude/skills/hq/SKILL.md` step 3: replace the inbox-log bullet with
  the rule.
- `templates/hq/CLAUDE.md`: add the rule; replace the inbox-thread READ line
  per the digest's Question.
- No origin story, no "supersedes" wording.

### Tests

- `tests/test-hq-decision.sh` (sources and executes the CLI against a
  `mktemp -d` `HQ_DECISIONS_DIR`, `TMUX` unset): add → one file, id printed,
  JSON fields right; second add same repo/pr/title → same id, stderr note,
  still one file; add same pr different title → new file + stderr warning
  naming the first id; missing `--recommend`, one option, recommend not an
  option → exit 2, no file; update changes the field in the same file (file
  count unchanged, no `.tmp.` left); answer sets state/answer; add after
  answer with same key → new file; `list --open` excludes answered; `--json`
  parses; the script contains no deletion.
- `tests/test-hq-decisions.sh`: fixtures written by `hq-decision add` into a
  temp dir, `NO_COLOR=1 COLUMNS=60 hq-decisions --dump`: open card shows ref,
  title, session, wrapped context (no line over 60 cols), the recommended
  option marked; answered rows folded one line each with the chosen label;
  empty dir → `no decisions recorded`; `wrap_text` unit cases; no tmux
  command in the screen (grep); no fractional `read -t`.
- Register both in `tests/run.sh`.

### CLAUDE.md

- Two bullets after `bin/hq-inbox` in the existing style: what each is, the
  invariants (one JSON file per decision, dedupe key, APPEND-ONLY,
  `decision_records` is the one reader, the screen is read-only and calls no
  tmux), flags/keys → `--help`. Extend the `tests/` sentence with the two
  suites.

## Assumptions

- VERIFIED: `jq` 1.6 on this machine (`jq --version`); `/bin/bash` and PATH
  bash are both 3.2.57 here, so `tests/run.sh` runs one pass.
- VERIFIED: the inbox-append rule lives in exactly three places —
  feature SKILL.md requester section (lines 90–96), hq SKILL.md step 3,
  and the template's read line (grep `inbox` over the three files).
- VERIFIED: `other/claude/skills/` does not exist in this worktree; the PR
  body will say private copies, if any on a machine, need the same edit.
- ASSUMED: leaving `bin/hq-inbox`'s CLAUDE.md entry ("the headline the hub
  last wrote") as is; with no new entries it shows older headlines or none.
  The inbox stitching slice will revisit it.

## Out of scope

- hq-inbox, Ctrl+G, Ctrl+Y, keybindings, tmux.conf, hooks, snapshot sources.
- Answering from the screen; it only displays.
- Pruning or archiving decision files.
