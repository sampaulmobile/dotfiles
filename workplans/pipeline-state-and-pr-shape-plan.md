# Workplan: pipeline state, PR shape, hq brief, status column (step 1 of 2)

## Goal

Make one `/feature` run checkable before its expensive loop starts, provable on
the surface its change actually lands on, readable in a PR body a human
finishes, and reconstructible from files after any session is cleared. No
topology change: the orchestrator still runs as a background subagent of the
session that invoked `/feature`. Step 2 (`option-c-topology-plan.md`) moves
the loop into its own session and depends on the state files this step adds.

## Approach

Edit the tracked skills and one script. Every new artifact is a file with one
writer, so a session's conversation is never the only copy of anything.

### 1. `/feature` — `dots/claude/skills/feature/SKILL.md`

- **Restatement and digest.** Step 1 (Plan) opens with a restatement written
  before any code is read: Task (one sentence), Done means, Assuming. After
  the workplan is written, the orchestrator revises it into the digest at the
  top of the workplan: Task, Done means, Not doing, Assuming (only items still
  ASSUMED, each with what would verify it), Surface (where verification will
  run), Touches (file count, key modules), Question (zero or one). The
  restatement stays above the digest; a one-line note says what reading the
  code changed, or "nothing".
- **Gate.** After the digest and before the first implementer spawn, the
  orchestrator sends the digest to the requester and waits for a go. `--quick`
  skips the gate. A new `--go` flag (or the same passed through from a
  dispatch) means proceed without waiting. In the interactive case the
  requester is the invoking session's user; the orchestrator reports the
  digest as its interim message and the hub relays it.
- **Verification rule.** Add to both the implementer (step 2) and reviewer
  (step 3) prompts: name the surface the change's consumer meets (test suite,
  local stack, CLI, dev warehouse, CI plan); verify there; attach the
  observation (command plus output, row count, read-back of the stored
  value); write "inconclusive" when it could not run. Tests remain the first
  gate. A run that could not verify on its surface says so in the PR body
  rather than letting tests stand in.
- **Reviewer blast-radius line** (step 3): name the one fact the change is
  safe because of and prove it by running code; unproven is reported as
  unproven.
- **Implementer TDD line** (step 2): when a cheap test path exists, write the
  failing test first, then the fix, then rerun.
- **Review order for fix rounds** (step 2, round > 1): address findings,
  then rebase if the branch conflicts with the default branch, then push
  once. If a conflict sits in code a finding touches, rebase first.
- **`status.jsonl` replaces `status.json`.** Same fields, one line appended
  per phase or seat change, never rewritten. Current state is the last line.
  Update every mention in this skill, `/address-review` and `/hq`.
- **Lessons block** in step 6 (Report): at most three items, each tagged
  `repo`, `wiki`, `backlog`, `dotfiles` or `none`. `repo` items are written
  into the repo's CLAUDE.md in the same PR. `wiki` items are appended to the
  repo's module page in the vault and committed per the knowledge rule.
  `backlog` items are appended to the hq backlog as inbox items. `dotfiles`
  items are proposed in the report only, never applied. Lessons record
  facts (gotchas, conventions, follow-ups), never preferences about how the
  user wants work done.
- **PR body at ship** (step 5): use the new `/pr` format. Unverified
  assumptions, deferred reviewer notes that matter, and product decisions go
  under "Open for the reviewer"; the remaining deferred notes go to the
  commit body. Remove the separate `## Assumptions` and
  `## Deferred review notes` sections.

### 2. `/pr` — `dots/claude/skills/pr/SKILL.md`

- Body sections, in order, each dropped when empty: Why, Scope, Tradeoffs,
  Blast radius, Verification, Open for the reviewer. Target about 40 lines.
  No SHAs, no file-by-file lists, no test-name lists. Why is one or two
  short paragraphs with a link to the evidence. Scope names symbols and
  paths. Verification is one line per real run: command, outcome.
- Title: conventional `type: subject`, types matching this repo's branch
  prefixes plus `refactor`, `test`, `perf`.
- A repo CLAUDE.md that prescribes its own body format or PR mechanism wins.

### 3. `/hq` — `dots/claude/skills/hq/SKILL.md`

- Step 4 replaces the bullet list with the brief block, every field required:
  GOAL, SCOPE (repo, paths it may and may not touch), CONTEXT (pointers
  only), ACCEPTANCE (checkable lines), VERIFY (commands or surface),
  FORBIDDEN (beyond the global rules), FLAGS (`/feature` flags to pass
  through, including `--go`), REPORT (digest then PR URL, to the requester
  session by name). "A field you cannot fill is a task you have not scoped
  yet."
- Step 5 tracks in-flight work by reading the last line of every worktree's
  `.feature/status.jsonl` (enumerate worktrees with `bin/project-dirs-lib`),
  not from conversation. No separate dispatch ledger.
- `dots/claude/rules/delegation.md` gains one line pointing at the brief
  block as the shape of every delegated task.

### 4. `/address-review` — `dots/claude/skills/address-review/SKILL.md`

- Fix agent order: address every thread and change request, then rebase if
  the branch conflicts, then push once. Rebase first only when a conflict
  overlaps a thread's code.
- CI: classify a failure before acting. A failure in code the diff never
  touched means a stale base (`git merge-base --is-ancestor`); report it.
  Never retrigger a workflow (CI/CD safety rule).
- `status.jsonl` instead of `status.json`.

### 5. `bin/worktrees`

- New PIPELINE column from the last line of `<worktree>/.feature/status.jsonl`
  when present: `phase r<round> <seat>`. Blank otherwise. Header docs and
  `--help` updated.
- `sweep --apply` copies `.feature/` to
  `~/.local/state/hq/runs/<repo-basename>/<branch-slug>/<UTC-stamp>/` before
  removing a worktree that has one, so run history survives the sweep. The
  history is append-only: one stamp directory per sweep run, and the script
  deletes nothing outside a git worktree.
- Tests: extend `tests/test-worktrees.sh` (or the closest existing suite) with
  a fixture `status.jsonl` and assert the column renders from its last line
  and is blank when absent.

### 6. Profile pass (findings only)

- Add stage timestamps behind an env var (`WORKTREES_PROFILE=1`,
  `PRS_PROFILE=1`, and the dashboard's equivalent) that print elapsed time
  per stage to stderr. Run each once and record the numbers in this plan's
  Status section. Fix a per-worktree waste in `bin/worktrees` only if the fix
  is local and obvious; anything larger is a follow-up item for step 2's
  collector.

### 7. Private layer, alongside (not in this PR)

- The private `triage` skill drops its "3+ PRs awaiting review" dispatch cap;
  the queue count stays as information.

## Files to touch

- `dots/claude/skills/feature/SKILL.md`
- `dots/claude/skills/pr/SKILL.md`
- `dots/claude/skills/hq/SKILL.md`
- `dots/claude/skills/address-review/SKILL.md`
- `dots/claude/rules/delegation.md`
- `bin/worktrees`, `tests/` (worktrees suite + fixture)
- `bin/profile-lib` (new: the one stage timer the three scripts share)
- `bin/prs`, `bin/tmux-claude-dashboard` (profile timestamps only)
- `CLAUDE.md` (bin/worktrees description: PIPELINE column, sweep archive)

## Ordered steps

1. `/feature`: status.jsonl, restatement + digest + gate, verification /
   blast-radius / TDD lines, fix-round order, Lessons block, PR-body handoff.
2. `/pr`: new body format and title rule.
3. `/hq` step 4 brief block and step 5 status scan; `delegation.md` pointer.
4. `/address-review`: order, CI classification, status.jsonl.
5. `bin/worktrees`: PIPELINE column + tests; sweep archive + tests.
6. Profile timestamps; run once; record numbers.
7. `CLAUDE.md` updates; `bash -n` every touched script; `tests/run.sh`.

## Test plan

- `tests/run.sh` green under both bashes.
- `bin/worktrees --all --offline` shows the PIPELINE column against a
  worktree holding a hand-written `status.jsonl`; blank elsewhere.
- Dry-run `bin/worktrees sweep` on a MERGED worktree with a `.feature/` dir
  prints the archive destination; `--apply` (on a disposable worktree)
  produces the copy before removal.
- Skill edits: read each once end to end for contradictions with the other
  skills and the rules. The live test (one `/feature --quick` and one full
  `/feature` on a throwaway change, confirming the digest arrives before
  implementation and the PR body has the new shape) runs from the main
  checkout after the branch is checked out there — `~/.claude` symlinks
  resolve to the main checkout, so edited skills are not live from a
  worktree. The pipeline agent does not run it.

## Out of scope

- Any topology change (hub retirement, task sessions, launch helper, snapshot
  collector). Step 2.
- Per-repo verification pages. Repo work, separate PRs.
- The rest of pstack (cursor/plugins/pstack), compared 2026-09-11 and
  rejected with reasons, so it is not re-proposed without new evidence:
  - The 23 principle skills as a seat rubric: persona-grade text on current
    models; a recurring lesson becomes a rule line on its own evidence.
  - `/why`: no current pain; the wiki, the Explore agent and triage recon
    cover it. Build it when a recon stalls on a why-question.
  - Verification-skill generator and maintenance loop: sized for a
    weekly-changing UI. A hand-written per-repo page where a repo has a
    drivable surface instead.
  - Comment Sicko: deletes guard comments the comments rule keeps on
    purpose. Narrow revisit later: some guard comments may be better as tests.
  - Cross-vendor review panels: not possible in Claude Code; a Claude-only
    panel breaks proportional review outside `--best`.
  - Cloud agents over worktrees: CI already gives the isolated-machine
    property; the hub model is deliberate.
  - `watch-pr` and `orch` tooling: TypeScript duplicates of `bin/prs` and
    the state files.
  - Sticky mode and principle citations in every reply: Cursor mechanics
    and a per-turn token tax.
  - Per-role model config: `/feature` seat flags already do it.
  - A dispatch ledger in hq: `status.jsonl` carries `started_by`.
- SQLite or any derived store. JSONL only, until a question needs a join.

## Assumptions

- VERIFIED (2026-09-12, from inside a live `/feature` orchestrator subagent):
  both halves of the gate exist as harness primitives — `SendMessage` accepts
  `to: "main"`, documented as "the main conversation (background subagents
  only)", and `Agent` documents resuming a previously spawned agent by name
  with `SendMessage`, context intact. What does NOT exist is a blocking wait:
  a subagent cannot park mid-turn until a reply lands. So the skill text is
  written in the form that holds under either delivery behaviour —
  orchestrator sends the digest to the requester AND writes it to the workplan
  and `status.jsonl` (`phase: gate`), then ends its turn; the requester relays
  and on a go resumes the orchestrator by name. A reply that happens to arrive
  while the orchestrator is still mid-turn is picked up early; nothing depends
  on it doing so.
- VERIFIED: `.feature/` is excluded via `$(git rev-parse --git-common-dir)/info/exclude`
  (feature skill, state files section), so nothing under it can be committed.
- VERIFIED: `bin/worktrees` already enumerates every worktree and prefetches
  PR lists once per repo (`load_pr_cache`, `prefetch_pr_lists`); reading one
  extra small file per worktree adds no network call.
- VERIFIED: `status.tsv` has two readers (`bin/tmux-sessionizer`,
  `bin/tmux-claude-statusbar`); untouched in this step.
- VERIFIED (2026-09-12): `~/.local/state/hq/` does not exist on this machine
  (`~/.local/state` holds only `fnm_multishells`, `gh`, `lesshst`, `nvim`), so
  the sweep must create the whole tree. Nothing reads it until step 2. Still
  ASSUMED for other machines — `mkdir -p` makes that difference irrelevant.
- ASSUMED: the `<branch-slug>` in the sweep's archive path is the branch with
  `/` → `-`, worktrunk's sibling-directory sanitisation. It is NOT
  `bin/project-dirs-lib`'s session name, which also prefixes the repo and maps
  `.` → `_` (`release/1.2` on `proj`: session `proj_release-1_2`, archive
  `runs/proj/release-1.2/<UTC-stamp>`). Nothing reads the path back in this
  step, so a mismatch is invisible until step 2's collector, which takes the
  newest stamp directory under the slug.
- VERIFIED (2026-09-13, `tests/test-worktrees.sh`): the archive is append-only.
  `archive_feature_dir` copies into `<slug>/<stamp>.partial` and renames it, so
  a second sweep of the same repo and branch adds a directory and leaves the
  first byte-identical; a copy that fails leaves its `.partial` and no stamp
  directory.
- ASSUMED: step 6's profile numbers cannot all be collected from inside this
  pipeline. `bin/worktrees` and `bin/prs` are non-interactive and read-only, so
  their numbers are real measurements taken here. `bin/tmux-claude-dashboard`
  is a full-screen TUI that reads a key with `read -rsn1` and needs a tty; a
  pipeline agent has none, and the tmux-safety rule allows only read-only tmux
  commands. The env-var instrumentation is added to the dashboard all the same,
  and the Status section records the exact command a human runs to collect its
  number instead of a fabricated one. Deliberately doing less than "run each
  once", recorded here rather than silently skipped.
- ASSUMED: the `/feature` and `/address-review` skill text is the only writer
  of `status.json` today — there is no consumer script to migrate. Grep over
  the tracked tree finds `status.json` in exactly two skill files and nowhere
  in `bin/`, so renaming it to `status.jsonl` breaks no existing reader. Any
  `.feature/status.json` sitting in a live worktree right now is orphaned by
  the rename; `bin/worktrees` reads only `status.jsonl` and leaves such a row's
  PIPELINE column blank.

## Status

- 2026-09-12: drafted, uncommitted.
- 2026-09-12: implemented (steps 1–7). Profile numbers below.
- 2026-09-12: review round 3 (fix). The sweep's `.feature/` archive is staged
  beside its destination and swapped in only once the copy is whole, and both
  path components under `runs/` are guarded against `.`, `..` and empty, so
  the `rm -rf` no longer depends on git's output format. An archive failure is
  counted once, as FAILED. `sweep_row` sits above the sourcing guard, so both
  of the sweep's failure counters are unit-tested (suite: 95 cases, 7 new).
- 2026-09-13: archive made append-only (timestamp dir, no deletion).

### Profile pass (step 6)

Instrumentation is `bin/profile-lib`, sourced by all three scripts:
`prof_init <tag> "$<SCRIPT>_PROFILE"` once, `prof <stage>` at each boundary.
Unset, it is one string comparison per stage and no fork. Measured on bash
3.2 (no `EPOCHREALTIME`), so the clock is a `perl` fork per boundary and every
stage reads roughly 10ms long.

`WORKTREES_PROFILE=1 bin/worktrees --all --offline` — 21 worktrees, 5 repos:

| stage | elapsed |
|---|---|
| liveness (lsof) | 225ms |
| project dirs | 15ms |
| worktree lists | 491ms |
| pr prefetch | 14ms (skipped, offline) |
| rows | 3856ms |
| render | 333ms |
| **total** | **4934ms** |

Same run online (`--all`): pr prefetch 2018ms, rows 4203ms, total 7496ms.

`PRS_PROFILE=1 bin/prs --all`:

| stage | elapsed |
|---|---|
| searches launched | 23ms |
| local scope | 490ms |
| gh searches (wait) | 1939ms |
| render | 139ms |
| **total** | **2591ms** |

`bin/tmux-claude-dashboard` is a full-screen TUI blocking on `read -rsn1`; a
pipeline agent has no tty, so its number is NOT collected here. The command a
human runs (press `q` once it has drawn, then read the file):

```
DASHBOARD_PROFILE=1 bin/tmux-claude-dashboard 2>/tmp/dash.prof
```

Findings, for the step-2 collector rather than this PR:

- `rows` dominates `bin/worktrees` — ~3.9s over 21 worktrees, ~185ms each,
  all of it the several git forks per worktree in `derive_worktree_facts`
  (status, rev-parse, rev-list, reflog, merge-base, log). Batching those per
  repo is the fix, and it is neither local nor obvious. `pipeline_state` adds
  one subshell per worktree (the command substitution `report_row` calls it
  through) and no exec, no git, no gh.
- `pr prefetch` costs 2s online, one parallel `gh pr list` per repo already.
- In `bin/prs` the local scope enumeration (490ms) runs while the searches are
  in flight, so it is already free; the run is its two GitHub searches.
