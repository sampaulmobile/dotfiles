# Workplan: hq-feed — per-pane last-exchange screen

## Restatement (from the request alone)

- **Task:** a new screen, `bin/hq-feed`, listing every live agent pane bucketed
  by what it needs from the owner (NEEDS YOU / DONE / WORKING / IDLE), each
  block showing the pane's last exchange — the owner's prompt, the agent's
  condensed reply, or what it is doing/asking now — fed by a new 5s `turns`
  snapshot source.
- **Done means:** `tests/run.sh` green under both bashes with a new
  `tests/test-hq-feed.sh`; `--dump` / `--dump --detail <pane>` render from a
  real `turns` snapshot with no terminal or tmux; `hq-snapshot tick` collects
  `turns` and re-parses nothing for an unchanged transcript; `--check` still
  passes; real-machine output (redacted) in NOTES.md.
- **Assuming:** the transcript, pane-scan and attention-flag data needed already
  exist and only need reading; `bin/hq-decisions` is a fit skeleton.

## Digest

- **Task:** `get_last_exchange` in `bin/tmux-claude-lib` (prompt via `grep -b`
  offset + one line read, reply/tool/pending via the 128 KB tail, tool
  rendering shared with `get_agent_snippet` through one jq `def`); a `turns`
  source in `bin/hq-snapshot` (5s, collected inline by `tick`, mtime-gated
  against the previous `turns` file itself — no new state); `bin/hq-feed`
  viewer on the hq-decisions skeleton; a `jump-to` verb in
  `bin/tmux-claude-attention` that `g` calls, so landing clears the flag
  through Ctrl+Y's own code.
- **Done means:** as the restatement; the mtime gate is proven by a test that
  stubs `get_last_exchange` with a call counter and runs the row builder
  twice over an unchanged fixture (0 parses on the second run), and on the
  machine by timing two consecutive `hq-snapshot turns`.
- **Not doing:** codex exchange lines (codex rows: status + age, `-` fields);
  a tmux.conf binding; any seen state or write by the viewer; session-end
  hooks; dashboard behaviour changes (its snippet keeps its output; only the
  shared jq `def` moves).
- **Assuming:** `"origin":{"kind":"human"}` marks every typed prompt
  (including slash commands) and `"origin":{"kind":"peer"}` with a `name`
  marks a cross-session message, in Claude Code 2.1.280 — VERIFIED on ten
  recent transcripts; an older claude writing no `origin` simply shows no
  `you ›` line.
- **Surface:** `tests/run.sh` (both bashes); `bin/hq-snapshot turns` +
  `bin/hq-feed --dump` on the live machine; `bin/hq-snapshot --check`.
- **Touches:** 7 files — new `bin/hq-feed`, `tests/test-hq-feed.sh`, fixtures
  under `tests/fixtures/feed/`; `bin/tmux-claude-lib`, `bin/hq-snapshot`,
  `bin/tmux-claude-attention`, `tests/run.sh`, CLAUDE.md.
- **Question:** none.

Reading the code changed: the brief's "plain-string, non-`isMeta` user record"
rule for `you ›` also matches harness-injected `<task-notification>` and
`<local-command-stdout>` records, and its `isMeta` rule for `msg ›` also
matches skill bodies, images, idle notices and subagent hand-backs; the
`origin.kind` marker (`human` / `peer` + `name`) separates them exactly and is
also what makes the `grep -b` cheap and unambiguous. And Ctrl+Y's switch-and-
clear is a closure inside `cmd_jump` with no "this pane" entry point, so `g`
needs a small verb added there rather than a copy.

## Goal

One screen that answers "what needs me, and what did each agent last say", so
the owner stops flipping tmux windows to find out.

## Approach

### 1. `bin/tmux-claude-lib` — `get_last_exchange <jsonl>`

- Move the tool-call rendering out of `get_agent_snippet`'s jq into one shared
  jq definition held in a lib variable (e.g. `_AGENT_TOOL_LINE_JQ`, a
  `def tool_line: …;` — field-name heuristic, first-line, path basenaming,
  `→ Name: arg` without the arrow so each caller prefixes its own). Both
  `get_agent_snippet` and `get_last_exchange` prepend it to their program.
  `tests/test-agent-snippet.sh` must pass unchanged — this is the proof the
  refactor is pure.
- `get_last_exchange <jsonl>` prints ONE tab-separated line, every field `-`
  when empty, every text field a JSON-encoded string (`tojson`), so the line
  carries no raw newline or tab:
  `kind  prompt  from  reply  tool  pending`
  - `kind`: `you` | `msg` | `-`.
  - Prompt side: one `grep -b -E '"origin":\{"kind":"(human|peer)"'` over the
    whole file, reduced in the same pipeline (awk) to the byte offset of the
    last `human` line and of the last `peer` line. Read the chosen line(s) by
    offset (`tail -c +$((off+1))` + first line) — never the whole file. When
    the last peer offset is greater than the last human offset AND that peer
    record carries `origin.name` (a subagent hand-back carries
    `senderTaskId` and no `name` — skip it), kind is `msg`, prompt is
    `origin.body` (fall back to the content), from is `origin.name`.
    Otherwise kind is `you` and prompt is the human record's
    `message.content` (string, or the text blocks joined when it is an array).
  - Prompt cleanup, in jq: `<command-name>X</command-name>` + `<command-args>Y`
    → `X Y`; each `<pasted_content …>…</pasted_content>` → `[pasted]`.
  - Assistant side from `tail -c 131072` parsed with `jq -R 'fromjson?'`:
    `reply` = the last non-empty assistant `text` block, capped at 32 KB
    inside jq; `tool` = `tool_line` of the last `tool_use`; `pending` = the
    last `tool_use` whose `id` has no `tool_result` with that `tool_use_id`
    in the window — `AskUserQuestion` renders as its first question's
    `question` text, anything else as `tool_line`.
  - A pipefail-safe read: the offset read must not abort under the
    collector's `set -o pipefail` when the reader closes early (SIGPIPE on
    `tail`); either avoid the early-closing stage or ignore that status.
  - Claude only. No caching inside the function: the gate lives in the
    collector.

### 2. `bin/hq-snapshot` — the `turns` source

- `SNAPSHOT_SOURCES` gains `turns:5`; `usage()` lists it.
- `collect_turns`: sources the lib, `build_cwd_session_map` (removing its own
  mktemp file when done — the one file it created), one jq over
  `$CLAUDE_SESSIONS_DIR/*.json` for pane → `name`, `get_claude_panes` (window
  index, agent, cwd) joined to `scan_agent_panes` (status) by pane id. One
  record per agent pane:
  `session pane window agent status name mtime jsonl kind prompt from reply tool pending cwd`
  (`-` for empty; `name` only when it differs from the session; `cwd` last as
  in `get_claude_panes`). The leading fields are never empty. Codex rows:
  `mtime`/`jsonl` from `codex_find_pane_jsonl` when it resolves, exchange
  fields `-`.
- The mtime gate: split the record builder into a pure function
  (`turns_rows <prev-snapshot-body>` over the pane/status lines, calling
  `get_last_exchange` only when the previous snapshot has no record for that
  pane with the same `jsonl` AND `mtime`; otherwise it copies the previous
  record's exchange fields). The previous `turns` file is the cache; nothing
  new is written anywhere.
- `tick` collects `turns` inline after `pipelines` (the tick already runs
  under its `lockf` lock, and the statusbar backgrounds the tick).
- `--check` covers it via the registry with no special case.

### 3. `bin/hq-feed` — the viewer

- Skeleton from `bin/hq-decisions`: UTF-8 locale forcing, `term_size`,
  `clip`/`pad` on plain text only, `count_lines`, the `decisions_split*`
  helpers (renamed `feed_split*`), `wrap_text`, `other_client`, the
  `load_data` → cached `build_frame` → `paint` loop on `read -rsn1 -t 2`,
  exit after 3 fast read failures, no `< <(…)` / `<<<` on the loop path.
- `load_data`: the `turns` snapshot (age + verdict via `snapshot_age` /
  `snapshot_verdict`), `pipeline_map_load` for the tag, the flag glob per pane
  (`$FLAG_DIR/<session>@<pane-sans-%>.done`, `FLAG_DIR` overridable for the
  test), and ONE jq pass over the snapshot that decodes the JSON fields and
  applies the markdown stripping (headings, `**`, backticks, fenced block →
  `[code]`, a run of `|` lines → `[table]`, `*`/`+` bullets → `- `). No
  per-pane fork and no bash `${var//…}` over a reply.
- `build_frame`: wrapping and the 6-line block budget in ONE awk pass (or the
  same jq) over all blocks at the current width, never per pane: a block is
  header + one prompt/`msg ›` line + reply section; the reply section gets 4
  lines, and when it does not fit shows 3 plus a right-aligned
  `(+N lines)`. WORKING shows `now →` (the `tool` field), NEEDS YOU shows
  `ask ›` (the `pending` field); `it ›` appears for every bucket that has a
  reply and room.
- Buckets, first match wins, newest transcript mtime first within each:
  NEEDS YOU (`permission`), DONE (flag exists), WORKING (`working`), IDLE
  (rest, hidden by default as a count line; `a` toggles).
- Labels: the session name, `session:N` when the pane's window index is not 1
  (the dashboard's rule), replaced by the `name` field when that is set.
- Header: counts per bucket and `updated Ns ago`, marked stale past three
  cadences. The viewer never recollects on its own; `r` reloads, and runs
  `bin/hq-snapshot turns` first.
- Keys: `j`/`k` by block, `⏎` DETAIL (full prompt + full stripped reply,
  scrollable, `q`/esc back), `g`, `a`, `r`, `q`.
- `g`: `other_client` for the tty, then
  `bin/tmux-claude-attention jump-to <tty> <session> <pane>`.
- Entry points as `bin/hq-inbox`: bare → own `hq-feed` session
  (`has-session`/`new-session -d`/`switch-client` own client, or
  `new-session -A` outside tmux); `--view`; `--dump`; `--dump --detail <pane>`;
  `--help` is the full user reference (keys, buckets, block format, glyphs).
- tmux subcommands in the file: `list-clients`, `display`, `has-session`,
  `new-session` (its own session), `switch-client` (own client only — the
  other-client move is in the attention script). Writes nothing.

### 4. `bin/tmux-claude-attention` — `jump-to <client-tty> <session> <pane>`

Hoist `cmd_jump`'s nested `do_switch` to a top-level function taking the
client flag, keep `cmd_jump`'s behaviour identical, and add the verb that
calls it for one named target. Header subcommand list and usage line gain it.

### 5. Tests — `tests/test-hq-feed.sh`, added to `tests/run.sh`

Fixture transcripts under `tests/fixtures/feed/` with generic names:
- an idle pane: typed prompt, text reply with headings/bold/code fence/table/
  bullets (condensing rules);
- a working pane: last block a `tool_use` with a path argument (basenamed);
- a permission pane: an `AskUserQuestion` tool_use with no result (pending =
  the question), and a Bash tool_use with no result;
- a peer message newer than the typed prompt (kind `msg`, from-name), plus a
  subagent hand-back that must NOT replace the prompt;
- a task-notification / local-command-stdout record after the prompt that
  must NOT replace it;
- the far-back prompt: generated at test time into a `mktemp -d` dir — a
  typed prompt followed by > 200 KB of tool_result lines, then a reply — and
  `get_last_exchange` must still return the prompt.
Assertions: `get_last_exchange` fields; `turns_rows` record format (field
count, `-` fill, one line per record) and the mtime gate (stub counter: N then
0 parses); bucket assignment and order; the condense budget and `(+N lines)`;
`--dump` and `--dump --detail` output against a fixture `turns` snapshot in a
temp `HQ_SNAPSHOT_DIR` with a fixture flag dir. No tmux server started.
`tests/test-agent-snippet.sh` unchanged and green.

### 6. CLAUDE.md

One `bin/hq-feed` entry in the `bin/` list (what operating or changing it
needs: the source it reads, the no-write rule, the tmux-safety list, the
skeleton it shares, `--help` as the reference) and `turns` in
`bin/hq-snapshot`'s cadence registry sentence; `bin/tmux-claude-attention`'s
`jump-to` mentioned where Ctrl+Y's script is described only if needed for a
session to change it safely.

## Steps

1. Shared `tool_line` jq def + `get_last_exchange`; snippet test green.
2. `turns_rows` / `collect_turns` / registry / tick.
3. `jump-to` verb.
4. `bin/hq-feed`.
5. Fixtures + `tests/test-hq-feed.sh` + `tests/run.sh`.
6. CLAUDE.md.
7. Real-machine run: `bin/hq-snapshot turns` twice (timed), `bin/hq-feed
   --dump`, `--dump --detail <pane>`, `bin/hq-snapshot --check`; output into
   `.feature/NOTES.md` with private names redacted.

## Test plan

`tests/run.sh` under both bashes; shellcheck on touched scripts; the
real-machine run in step 7.

## Assumptions

- `origin.kind` marks typed prompts (`human`) and peer messages (`peer`, with
  `name` for a cross-session message, `senderTaskId` for a subagent
  hand-back) — VERIFIED: ten most recent transcripts on 2026-10-12, Claude
  Code 2.1.280; task-notifications carry `kind: task-notification`, idle
  notices carry no `origin`.
- `grep -b` over the largest live transcript is cheap — VERIFIED: 40 ms on a
  4.8 MB file including the awk reduction.
- `~/.claude/sessions/*.json` carries `name` and `tmux` (`sess:@win.%pane`) —
  VERIFIED by reading two files.
- The statusbar backgrounds `hq-snapshot tick`, so an inline `turns`
  collection does not delay the status bar — VERIFIED
  (`bin/tmux-claude-statusbar` line 45, `&`).
- A pane's status from a second `scan_agent_panes` inside the tick costs
  roughly what the statusbar's own scan does (two tmux round trips) —
  ASSUMED; measured in step 7.

## Out of scope

Codex exchange extraction; a key binding; seen state; session-end/clear hooks;
dashboard behaviour.
