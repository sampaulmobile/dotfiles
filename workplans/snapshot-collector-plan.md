# Workplan: snapshot collector and screens (step 2b)

## Restatement (before reading the code)

- Task: make status something deterministic screens READ from files rather
  than recompute at the keypress — a background collector writes one TSV per
  source under `~/.local/state/hq/snapshot/`, and `bin/worktrees`, `bin/prs`,
  Ctrl+G and `/hq` read those files and print the snapshot's age.
- Done means: `derive_worktree_facts` in `bin/worktrees` is batched per repo
  (report byte-identical, `rows` stage measurably faster under
  `WORKTREES_PROFILE=1`); a new `bin/hq-snapshot` collector writes
  `sessions.tsv`, `pipelines.tsv`, `worktrees.tsv` and `prs.tsv` atomically
  (`<file>.tmp.$$` then `mv`) and deletes nothing; the statusbar's
  `status.tsv` moves to `sessions.tsv` with every existing reader following;
  Ctrl+G gains a PIPELINE field and `/hq` reads `pipelines.tsv` instead of
  looping over worktrees; `bin/worktrees` and `bin/prs` read the snapshot,
  print its age, accept `--fresh`, and fall back to live when no snapshot
  exists; CLAUDE.md and `bin/doctor` cover the new dir; `tests/run.sh` green.
- Assuming: the plan's Decisions section is authoritative about what is
  precomputed vs fixed in the script; the step-1 profile numbers it cites are
  correct; no test may run the statusbar tick against the live tmux server;
  deletion-safety forbids removing anything under `~/.local/state/hq/`.

## Digest

- **Task** — Batch `bin/worktrees`' per-worktree git forks, add a
  `bin/hq-snapshot` collector that writes four TSV snapshots under
  `~/.local/state/hq/snapshot/`, and make the four status screens read the
  snapshot with its age instead of computing at the keypress.
- **Done means** — `derive_worktree_facts` costs a bounded number of git
  processes per repo instead of six per worktree, with
  `NO_COLOR=1 bin/worktrees --all --offline` byte-identical to the
  pre-change script and the `rows` stage measurably down under
  `WORKTREES_PROFILE=1`; `bin/hq-snapshot` has one subcommand per source plus
  `all` and the statusbar's tick entry, every write `<file>.tmp.$$` then `mv`,
  nothing under `~/.local/state/hq/` ever removed; the statusbar writes
  `snapshot/sessions.tsv` and the sessionizer reads it there; `pipelines.tsv`
  feeds a dashboard PIPELINE field and `/hq`'s in-flight check; `worktrees.tsv`
  and `prs.tsv` back `bin/worktrees` and `bin/prs`, each printing the age,
  accepting `--fresh`, and falling back to live computation with a said-so line
  when no snapshot exists; `CLAUDE.md` and `bin/doctor` cover the new dir;
  `tests/run.sh` green with fixture-backed collector tests and no tmux server.
- **Not doing** — step 2a (already on this branch); replacing TSV/JSONL with a
  database; any change to the pipeline's own state files or to how seats are
  spawned; the dashboard's own timings (634ms end to end, the plan's "not worth
  touching"); `bin/prs`' local scope.
- **Assuming**
  - gh quota is not a constraint at a 30s cadence (~2 searches plus one list
    per repo with worktrees per tick, well under 5,000/hour). Verified by:
    `gh api rate_limit` after a day of ticking.
  - The statusbar's 5s tick absorbs sessions + pipelines collection without
    visible lag. Verified by: the existing profile env vars on the real
    machine, which only the human can run.
- **Surface** — `tests/run.sh` under `/bin/bash` 3.2 (and the default bash
  where one exists); a byte-for-byte `diff` of `NO_COLOR=1 bin/worktrees --all
  --offline` between the pre-change script and HEAD; `WORKTREES_PROFILE=1`
  stage timings before and after; fixture-backed collector parsing with no
  tmux server and no `gh`.
- **Touches** — 10 files: `bin/hq-snapshot` (new), `tests/test-hq-snapshot.sh`
  (new) + fixtures, `bin/worktrees`, `bin/prs`, `bin/tmux-claude-statusbar`,
  `bin/tmux-sessionizer`, `bin/tmux-claude-dashboard`,
  `dots/claude/skills/hq/SKILL.md`, `bin/doctor`, `CLAUDE.md`, `tests/run.sh`.
- **Question** — none blocking. Two judgment calls with sensible defaults are
  recorded as DECIDED in Assumptions (no dual-write transition shim for
  `status.tsv`; no cleanup of the collector's own `.tmp.$$` files).

Reading the code changed: `status.tsv` has exactly ONE reader today, the
sessionizer — the dashboard never reads it, so the sessions.tsv move is a
two-file change and the dashboard is touched only for the PIPELINE field.
`~/.local/state/hq/` already exists as the sweep archive with an append-only
invariant stated in `bin/worktrees`' header, so `snapshot/` joins an existing
rule rather than inventing one.

## Goal

Status is read from files by deterministic screens, not asked of a model and
not recomputed at the keypress. A background tick writes one snapshot per
source under `~/.local/state/hq/snapshot/`; `bin/worktrees`, `bin/prs`, Ctrl+G
and `/hq` read the snapshot and print its age. Depends on step 1 (merged
2026-09-13: `status.jsonl`, PIPELINE column, profile timings) and shares
tmux-session naming with step 2a (`option-c-topology-plan.md`); it does not
otherwise depend on 2a landing first.

## Approach

### Collector and snapshot files

- Snapshot dir `~/.local/state/hq/snapshot/`, one TSV per source, each with
  a first-line `# generated <ISO time>` header:
  - `sessions.tsv` — the statusbar's existing `status.tsv`, moved here
    (writer: `bin/tmux-claude-statusbar` tick; readers: `bin/tmux-sessionizer`,
    `bin/tmux-claude-dashboard`).
  - `pipelines.tsv` — last line of every worktree's `status.jsonl`, keyed by
    worktree path.
  - `worktrees.tsv` — `bin/worktrees` classification for every project.
  - `prs.tsv` — `bin/prs` rows.
- Cadence: sessions and pipelines on the 5s statusbar tick; worktrees on the
  same tick or every 15s; prs and the per-repo PR lists every 30s. All
  incremental where the input allows (mtime/size on transcripts and jsonl).
- Screens read only the snapshot and print its age: `bin/worktrees`,
  `bin/prs`, Ctrl+G (adds a PIPELINE field per row from `pipelines.tsv`).
  `--fresh` runs the collector for that source first, then renders. One code
  path: the on-demand computation lives in the collector, never in a screen.
- Which parts of the collector to build is decided by step 1's profile
  numbers: inherently slow inputs (gh, transcript parsing) are precomputed;
  script-local waste is fixed in the script instead.


### Decisions the step-1 profile numbers settle

From `pipeline-state-and-pr-shape-plan.md` (Status → Profile pass), measured
2026-09-13 on 21 worktrees / 5 repos:

- Precomputed by the collector (inherently slow, network): `bin/prs`'s two
  GitHub searches (~2.0s) and `bin/worktrees`' per-repo `gh pr list`
  prefetch (~2.8s online).
- Fixed in the script, not hidden behind the snapshot (script-local waste):
  `bin/worktrees`' `rows` stage, ~3.9s = up to eight git forks per worktree in
  `derive_worktree_facts` (status, rev-parse, rev-list, reflog, merge-base,
  log). Batch per repo — one `git for-each-ref` with the needed fields and
  one `git status --porcelain` per worktree at most — so the collector's
  worktrees tick is cheap too. Keep the report byte-identical (the existing
  master-vs-branch `NO_COLOR=1 --all --offline` comparison is the check).
  Landed at 1.8s on the same 21 worktrees, not the sub-second target: the
  floor is one `git status` per worktree plus the `is_live` lsof check, the
  guard `sweep --apply` relies on, neither of which batches. The report
  itself renders from the snapshot in 0.45s, so the target is met where a
  keypress pays for it and the live floor is the collector's cost.
- Not worth touching: the dashboard (634ms end to end), `bin/prs`' local
  scope (runs while the searches are in flight).

### Writing rules

- Every snapshot write is `<file>.tmp.$$` then `mv` over `<file>` — atomic
  for readers, and no snapshot is ever removed (`dots/claude/rules/
  deletion-safety.md`). The collector creates `snapshot/` with `mkdir -p`
  and deletes nothing under `~/.local/state/hq/`.
- A reader that finds no snapshot, or one older than its source's cadence
  times three, says so on its age line and, for `bin/worktrees`/`bin/prs`,
  falls back to computing live (today's path) so a fresh machine still
  works before the first tick.

## Files to touch

- new `bin/hq-snapshot` (the collector; one subcommand per source, `all`,
  and the tick entry the statusbar calls) + `tests/test-hq-snapshot.sh`
  with fixtures under `tests/fixtures/`
- `bin/tmux-claude-statusbar` (tick calls the collector; `status.tsv` moves)
- `bin/tmux-sessionizer`, `bin/tmux-claude-dashboard` (read `sessions.tsv`
  from the new dir; dashboard adds the PIPELINE field)
- `bin/worktrees` (batched git facts; snapshot read + age + `--fresh`),
  `bin/prs` (snapshot read + age + `--fresh`)
- `dots/claude/skills/hq/SKILL.md` (in-flight state from `pipelines.tsv`
  instead of the per-worktree loop)
- `CLAUDE.md`, `bin/doctor` (snapshot dir present and fresh)

## Ordered steps

1. Batch `derive_worktree_facts` in `bin/worktrees`; report byte-identical;
   `WORKTREES_PROFILE=1` shows the `rows` stage drop.
2. Collector skeleton + `sessions.tsv` move (statusbar, sessionizer,
   dashboard follow the path); `tests/run.sh` green.
3. `pipelines.tsv`; dashboard PIPELINE field; `/hq` reads it.
4. `worktrees.tsv` and `prs.tsv`; screens read snapshot + age; `--fresh`.
5. `CLAUDE.md`, `bin/doctor`.

## Test plan

- `tests/run.sh` green under both bashes; collector parsers covered by
  fixtures (no tmux server, no gh: fixtures stand in for both).
- `bin/worktrees --all` before/after step 1: identical output modulo ages;
  `rows` stage under 1s on the same 21 worktrees.
- Screens: `bin/worktrees` and `bin/prs` render in under one second from a
  fresh snapshot and print its age; `--fresh` matches a pre-change run.
- Missing snapshot dir: both screens fall back to live and say so.
- Ctrl+G shows a PIPELINE field on a row whose worktree has a
  `status.jsonl`.

## Out of scope

- Replacing JSONL/TSV with a database.
- Any change to the pipeline's own state files or to how seats are spawned.
- The launch helper and skill split (step 2a).

## Assumptions

- ASSUMED: gh quota is not a constraint at a 30s cadence (about 2 searches
  plus one list per repo with worktrees per tick, well under 5,000/hour).
- ASSUMED: the statusbar's 5s tick can absorb the sessions + pipelines
  collection without visible lag; worktrees/prs run on their own slower
  cadence. Measure with the existing profile env vars.
- VERIFIED (2026-09-13): the profile numbers above; `pipeline_state` costs one
  subshell per worktree and no exec.
- VERIFIED: `status.tsv` has exactly ONE reader today —
  `bin/tmux-sessionizer:112`. `bin/tmux-claude-dashboard` does NOT read it; its
  only `~/.cache/claude-attention` read is the per-pane `.done` flag
  (`bin/tmux-claude-dashboard:431`). This plan's sessions.tsv bullet names the
  dashboard as a reader and is wrong there. The move is therefore
  writer + one reader; the dashboard is touched for the PIPELINE field (step 3)
  and for nothing else. Adding a sessions.tsv read to the dashboard would be
  machinery built on a false premise.
- VERIFIED: `~/.local/state/hq/` already exists as the sweep archive root
  (`runs/`, `bin/worktrees:884`), and `bin/worktrees`' header states the
  invariant: "the archive under ~/.local/state/hq is append-only".
  `snapshot/` joins that existing rule rather than inventing one.
- VERIFIED (corrected during implementation: up to EIGHT, not six — the
  reflog's own rev-list and a HEAD-age log were missed on the first read):
  `derive_worktree_facts` (`bin/worktrees`) forked per worktree — `status
  --porcelain`, `rev-parse --verify refs/remotes/origin/<branch>`,
  `rev-list --count`, `reflog show` plus its rev-list, `log -1` for the age,
  `rev-parse <default_ref>` and `merge-base --is-ancestor`. `<default_ref>`'s
  sha is a per-REPO constant recomputed per worktree; that and the ref
  existence check are the cheapest part of the batching win.
- DECIDED (default taken, gate skipped): no transition shim dual-writing
  `~/.cache/claude-attention/status.tsv`. tmux re-executes the statusbar
  script every ~5s, so the new writer and the new reader take effect together
  on the next tick; a dual-write would be a second home for one fact that
  nothing would ever remove.
- DECIDED (default taken, gate skipped): the collector does not remove its own
  `<file>.tmp.$$` files on a failure path. The deletion-safety rule and the
  task's explicit instruction forbid deletion under `~/.local/state/hq/`; a
  failed write leaves the tmp file and the previous snapshot stands, which is
  the safe outcome. `$$` bounds the set by the pid space and each name is
  overwritten on pid reuse. If the leftovers ever matter, the fix is a command
  printed for the user, never an `rm` in the script.

## Status

- 2026-09-13: split out of `option-c-topology-plan.md`, uncommitted.
- 2026-09-13: planned for implementation on `feat/option-c-topology` after 2a
  (base cca562a). Gate skipped by explicit instruction; restatement, digest and
  the code-read Assumptions added.
- 2026-09-13: implemented on `feat/option-c-topology`. Deviation: the `rows`
  stage landed at 1.8s, not under 1s (see Decisions); the report reads the
  snapshot in 0.45s.
