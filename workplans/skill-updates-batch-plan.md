# Skill updates batch — `--quick` without a PR, an enforced PR-body budget, a post-merge guard

## Restatement (written from the request, before reading the files)

**Task** — On one dotfiles topic branch, make `--quick` stop mandating a PR,
turn the PR-body line budget into something a run can check, add a post-merge
orphan-commit guard to the two skills that commit onto an existing branch, and
fold in the `feedback/deliverable-check-and-no-force-push` branch as-is.

**Done means** — `/hq --quick <anything>` ends in a PR when the run produced
commits and in an answer when it did not; `pr/SKILL.md` carries a countable
`<= 40` line cap that a requester's "document this" instruction cannot suspend;
`feature/` and `address-review/` both refuse to commit into a merged PR's
branch; the working-style rule is present unmodified.

**Assuming** — hq/SKILL.md already passes `--quick` through verbatim (to be
VERIFIED by reading it, not assumed); the one branch merges cleanly.

## Digest

- **Task** · Three prose changes across four skill files plus one branch merge.
- **Done means** · as above, plus nothing anywhere still assumes every
  dispatched run yields a PR URL.
- **Not doing** · the brainstorm skill (dropped by the requester mid-run), any
  `--task` flag or lane, any merge or checkout of this branch into `~/dotfiles`.
- **Assuming** · nothing still ASSUMED — the flag pass-through was read and
  confirmed at `dots/claude/skills/hq/SKILL.md:8-11`, which names `--quick`
  explicitly in the verbatim pass-through list.
- **Surface** · the skill files themselves; they are prose loaded into a
  prompt, so the surface is a full read-through for dangling step references
  and flag-list agreement. There is no test suite for skills.
- **Touches** · 4 files edited (`feature/`, `pr/`, `address-review/`, `hq/`
  SKILL.md) + 1 merge bringing `dots/claude/rules/working-style.md`.
- **Question** · none.

Reading the files changed one thing: the post-merge guard's natural home in
`address-review/SKILL.md` is the fix agent's prompt in step 2, not the skill's
own step 0/1 PR-resolution — steps 0 and 1 already read the PR's state, and the
failure being guarded is the PR merging *during* the run, after that read.

## Goal

One branch Sam can check out in `~/dotfiles` that makes every pending skill
change live at once.

## Approach

Prose edits only, each at the place a run actually reads rather than in a
preamble. No structural renumbering of any skill's steps, so no cross-reference
can dangle.

## Files to touch

- `dots/claude/skills/feature/SKILL.md` — changes (1) and (3), plus the
  requester-side relay wording.
- `dots/claude/skills/pr/SKILL.md` — change (2).
- `dots/claude/skills/address-review/SKILL.md` — change (3).
- `dots/claude/skills/hq/SKILL.md` — the step-3 relay clause only.
- `dots/claude/rules/working-style.md` — arrives by merge, unmodified.

## Ordered steps

1. Merge `feedback/deliverable-check-and-no-force-push` (one commit, +18 lines).
2. **Change (1)** in `feature/SKILL.md`: rewrite the `--quick` flag description
   (line 29) so it names both outcomes, and rewrite the Quick mode implementer
   prompt's tail (line 117) and the line after it (119) so the deliverable
   follows from whether the run produced commits. Say explicitly that a run
   that concludes no change is needed stops there — the stop step 1 has and
   Quick lacks.
3. **Change (2)** in `pr/SKILL.md`: replace the "aim at 40 lines" sentence
   (line 38) with the enforced budget — a `wc -l` check against a hard `<= 40`,
   the first-15-lines standalone rule, ~3 items each on Tradeoffs and
   Open-for-the-reviewer, `<details>` for the overflow, and the rule that a
   requester's instruction to document something does not suspend the budget.
   Keep the section set exactly as it is.
4. **Change (3)**: a post-merge guard near the commit/ship step of
   `feature/SKILL.md` (step 5) and in the fix agent's prompt in
   `address-review/SKILL.md` (step 2), beside the commit bullet.
5. **End-to-end (1)**: soften `feature/SKILL.md:94` and `hq/SKILL.md:111` so
   neither describes the end of a run as necessarily a PR URL. One clause each.
6. Read all four files end to end; grep for step references.

## Test plan

There is no test suite for skills — `tests/run.sh` covers `bin/` shell
functions only, and none of these files is executable. Verification is:

- `tests/check-prose-only.sh master` passes (the diff is prose; it fails if a
  changed `bin/`/`tests/` file differs once comments are stripped).
- A full read of each changed file, confirming frontmatter intact and no step
  reference dangling: `feature/SKILL.md` cross-references its own step numbers,
  and `pr/SKILL.md` is referenced from `feature/SKILL.md`'s ship step.
- `git log --oneline master..HEAD` shows the merged commit and
  `dots/claude/rules/working-style.md` carries its +18 lines.

## Assumptions

- **VERIFIED** — `hq/SKILL.md` passes `--quick` through verbatim: its lines
  8-11 list the flags passed "through verbatim to the dispatched invocation"
  and `--quick` is among them. Nothing in this change touches that list.
- **VERIFIED** — `feature/SKILL.md` has no numbered step whose number this
  change moves: every edit is inside an existing step's body.
- **ASSUMED** — the single merge is clean. Verified by performing it (step 1);
  a conflict is resolved trivially and named in the PR body.

## Out of scope

- The brainstorm skill and its branch — explicitly dropped by the requester
  mid-run; `feature/brainstorm-skill` is left untouched.
- The `--task` lane draft in the `~/dotfiles.feat-hq-task-lane` worktree —
  obsolete, superseded by change (1). Not merged, not recreated, not read.
- Merging this branch or checking it out in `~/dotfiles`. Sam does that.
