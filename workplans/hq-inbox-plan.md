# Workplan: hq inbox

## Goal

One screen that answers "which threads need me, and what do they need" without
scrolling a hub or hq transcript. A thread is a worktree with a pipeline run
(`/feature`, `/address-review`), the same unit Ctrl+G and `bin/worktrees`
already show. The hub or hq session that receives a run's digest or result
writes what it tells the user into a per-thread log; a viewer in its own
Ghostty window lists threads by what they wait on and opens a thread's log on
demand. Replying stays a conversation in the hub or hq shell; the inbox never
composes or sends.

Rows come from files the pipelines already write (`status.jsonl` via the
`pipelines` snapshot, PR tags via the `prs` snapshot), so a thread appears as
Working or Needs you before, and regardless of whether, its hub has written an
entry. The entry bodies are prose the hub decides on; nothing scripted
summarises a run.

## Approach

### Thread logs (written by hubs and hq)

- One file per thread: `~/.local/state/hq/inbox/<repo>/<branch-slug>.md`,
  `<branch-slug>` = the branch with `/` → `-` (worktrunk's sanitisation, the
  same rule `session_name_for_branch` applies). Created with `mkdir -p` on
  first write, appended to, never rewritten or removed.
- Entry = one header line, a blank line, a body:
  ```
  ## 2026-09-21 10:02 EDT · hq

  PR #38 plan digest: ...
  ```
  Header time is local, 24-hour, zone abbreviation from `date '+%Y-%m-%d %H:%M %Z'`
  (never typed from memory). Author is the writing session's tmux name. The
  body's first line is the headline the inbox shows; the body is what the
  session says to the user about that thread, in full: the relayed digest or
  result plus the session's own commentary, and on a go, the go with any
  corrections as sent to the task session.
- Writers are the requester-side rules only. Runs, seats and `status.jsonl`
  are untouched.
  - `dots/claude/skills/feature/SKILL.md`, "After a Launch, on the
    requester's side": before relaying a digest, a result, a stalled notice
    or a `--quick` run's findings to the user, append it as an entry; on a
    go, append the go. This section is the format's one home.
  - `dots/claude/skills/hq/SKILL.md`, step 3 "Track and relay": the same
    rule, pointing at the feature skill's section for the format.
  - `dots/claude/skills/feature/SKILL.md`, Launch: the launching session
    names ITSELF `--requester=` whenever its name answers in `ListAgents`,
    hub or hq alike, so a digest reaches the shell the human is talking to
    instead of the task session's own terminal. Today only dispatchers do
    this; a human-typed `/feature` in a hub prints the digest in the task
    session, which is the one case the inbox would otherwise miss.
  - `templates/hq/CLAUDE.md` status-and-pickup paragraph: read the inbox
    threads before the backlog. The live `~/dev/hq/CLAUDE.md` is a separate
    repo and gets the same edit by hand.

### `inbox` snapshot source (`bin/hq-snapshot`)

- `SNAPSHOT_SOURCES` gains `inbox:5`. `collect_inbox` joins, per
  `pipelines.tsv` row: the thread file's mtime (epoch), entry count (`^## `
  lines) and headline (first non-blank line after the last header); and the
  PR's `bin/prs` tag from `prs.tsv`, matched on PR URL. It reads the two
  sibling snapshots, never `gh` or the worktrees, so it costs a few stats.
- Columns: worktree · session · repo · branch · state (`<phase> r<round>
  <seat>`, as `pipelines.tsv` has it) · pr · pr-tag · thread-mtime ·
  thread-entries · headline. TSV invariant: any empty field writes `-`, the
  reader maps it back; headline last since it may contain spaces, tabs in it
  replaced by spaces.
- A thread file with no pipelines row (worktree swept) still produces a row,
  with worktree/session/state `-`, so a swept thread stays reachable until
  archived.

### Viewer (`bin/hq-inbox`)

- Ctrl+G's shape (`bin/tmux-claude-dashboard`): `load_data` → cached
  `build_frame` → `render`; repaint on data change, resize or a 30s-old
  frame; cursor moves repaint the cache; nothing forks per keypress. Reads the
  `inbox` snapshot with `snapshot_verdict`; with none or a stale one, runs
  `collect_inbox` itself and says so in the footer.
- Sections, first match wins, decided by one testable function `inbox_bucket
  <state> <pr-tag> <archived?>`:
  - ARCHIVED — archive mark present and nothing newer than it (below).
  - NEEDS YOU — phase `gate` or `stalled`; or pr-tag `changes-requested`,
    `ci-red`, `approved`, `merge-conflict`.
  - DONE — phase `done`, or pr-tag `merged`.
  - WORKING — everything else with a pipelines row.
- Row: repo/branch · session · state · age (from thread-mtime, else the
  state's `updated`) · headline. Colours from `bin/worktrees`' palette by
  bucket; unread rows bold; no glyphs.
- Keys: `j`/`k` move · `⏎` opens the thread file in `${PAGER:-less}` and
  marks it seen · `a` archives or unarchives · `g` switches the OTHER tmux
  client to the row's hub session · `r` recollects · `q`.
- `g`: target client = most recently active attached client whose tty is not
  this one (`tmux list-clients -F '#{client_activity} #{client_tty}'`);
  `tmux switch-client -c <tty> -t =<session>`, the call
  `bin/tmux-claude-attention jump` already makes. With no other client, print
  the session name in the footer and switch nothing. Hub session = the
  author of the latest entry, falling back to the row's `session` column
  (the task session) when there is no entry.
- Entry: `hq-inbox` from a shell inside tmux creates the `hq-inbox` session
  detached if missing (`new-session -d -s hq-inbox "$0 --view"`) and
  `switch-client -t =hq-inbox` on the caller's own client; outside tmux,
  `new-session -A -s hq-inbox "$0 --view"`. Creation and own-client switch
  only (tmux-safety). Daily flow: new Ghostty window, type `hq-inbox`.
- State under `~/.local/state/hq/inbox/_state/`: `archived.tsv`
  (`repo\tbranch\tmtime-at-archive\tstate-at-archive`) and `seen.tsv`
  (`repo\tbranch\tmtime-seen`), each rewritten `<file>.tmp.$$` then `mv`.
  Un-archive is automatic: a thread mtime newer than the archive mark, or a
  state string different from the one archived, drops the row back into its
  live bucket; `a` on a live row that carries a stale mark refreshes the mark.
  Unread = thread-mtime newer than seen mtime (or no seen row). Nothing under
  `~/.local/state/hq/` is ever removed.

## Files to touch

- new `bin/hq-inbox`; new `tests/test-hq-inbox.sh` + fixtures under
  `tests/fixtures/` (a `pipelines.tsv`, a `prs.tsv`, two or three thread files,
  `archived.tsv`/`seen.tsv`); `tests/run.sh` suites list
- `bin/hq-snapshot` (`inbox` source, `collect_inbox`, usage)
- `dots/claude/skills/feature/SKILL.md` (Launch requester rule; requester-side
  append rule and the entry format)
- `dots/claude/skills/hq/SKILL.md` (step 3 append rule, pointer to the format)
- `templates/hq/CLAUDE.md` (sitrep reads inbox threads first)
- `CLAUDE.md` (bullets for `bin/hq-inbox` and the `inbox` source; the inbox
  dir joins the append-only sentence)

## Ordered steps

PR 1 — writers (threads start accumulating while PR 2 is built):
1. Feature skill: Launch names the launching session as requester; requester
   side appends entries; format documented there.
2. hq skill step 3 and `templates/hq/CLAUDE.md`.

PR 2 — collector and viewer:
3. `collect_inbox` + `inbox:5` in `bin/hq-snapshot`; fixture test for the
   record: width, `-` mapping, headline extraction, swept-thread row.
4. `bin/hq-inbox --view`: load, bucket, frame, keys `j k ⏎ a q r`; tests
   for `inbox_bucket`, the un-archive and unread decisions.
5. `g` and the `hq-inbox` session entry.
6. `CLAUDE.md`; `tests/run.sh` green under both bashes.

## Test plan

- `tests/run.sh` green under `/bin/bash` 3.2 and the default bash; no tmux
  server started or touched; fixtures stand in for snapshots and threads,
  `HQ_SNAPSHOT_DIR` and a new `HQ_INBOX_DIR` point both at a temp dir the
  suite creates under `mktemp -d`.
- Record test: every fixture row is 10 fields wide; a thread with no
  pipelines row renders with `-` in the worktree, session and state fields;
  headline is the first non-blank body line of the LAST entry.
- Bucket test: each phase and each pr-tag lands in the documented section;
  archive mark with a newer mtime or a changed state → live bucket.
- Human check after PR 2: a run at `gate` shows under NEEDS YOU with the hub's
  headline; `⏎` shows the thread; `a` moves it to ARCHIVED; the next hub
  entry brings it back; `g` from a second Ghostty window lands the first on
  the hub session.

## Out of scope

- Composing or sending replies from the inbox.
- Task sessions or seats writing anything new; `status.jsonl` unchanged.
- Rows for hq-internal subagent work with no worktree.
- Headline or thread state in Ctrl+G or `bin/worktrees` (one home).
- A web or desktop rendering; the files are the contract if one comes later.

## Decisions

- Prose over scripted bodies: the hub decides what an entry says. Rows do
  not depend on the hub having written one.
- Thread files live under `~/.local/state/hq/inbox/`, not in the worktree's
  `.feature/`: the hub writes them, not the run, and they outlive a sweep.
- Header time is human-facing (local, 24h, zone abbreviation); ages come from
  file mtimes, so nothing parses the header.
- Explicit archive with automatic un-archive on new activity, like mail.
- Viewer in its own Ghostty window as a plain tmux session; no popup, no
  Ghostty config, no new hotkey.

## Status

- 2026-09-21: drafted from the discussion in the dotfiles hub, uncommitted.
- 2026-09-21: PR 1 (the writers) on branch `feat/hq-inbox-writers`.
