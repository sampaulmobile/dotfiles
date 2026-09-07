# Workplan: `/brainstorm` — Socratic design sessions that end in a design doc

## Goal

Add the missing tier above `/feature`: a skill for the fuzzy front end of a
meaty or greenfield piece of work. `/brainstorm <idea>` runs a one-question-
at-a-time requirements dialogue with the user, explores 2–3 architectures,
locks decisions, and writes a durable **design doc** (what + why, options
considered, decisions log). Workplans (how, per repo, per PR-sized chunk) are
derived from the design doc later, by the existing plan-mode → `workplans/`
→ `/feature` flow — this skill does not write workplans, create repos, or
invoke `/feature`.

v1 = one skill file + one doc template + hq scaffold glue. Deliberately small;
everything tunable (question areas and order, template, gates, flags) lives in
the skill file so the process can be iterated after real runs.

Decisions already made (do not re-open):
- Name is `/brainstorm` (`/design` is taken by the Claude Design canvas skill).
- Homegrown, not the Superpowers plugin: its SessionStart hook steers every
  session into its own plan/execute/TDD pipeline, which would fight `/feature`.
  We borrow only the interaction pattern (Socratic, one question at a time,
  hard gate before design).
- Strict one-question-at-a-time questioning, driven by `AskUserQuestion`.
- Design doc is a separate artifact from the workplan and does NOT replace
  it. Small single-repo features skip `/brainstorm` entirely.
- Two modes by cwd: **repo mode** (cwd is a repo hub) and **greenfield mode**
  (anywhere else, incl. hq) — greenfield is the primary use case right now.
- Council (parallel independent proposers) is an opt-in flag, not the default.
- Claude-only skill (needs `AskUserQuestion` and the Agent tool); not added to
  `dots/codex/shared-skills`.

## Design

### Invocation and modes

`/brainstorm <idea | path-to-existing-design-dir-or-design.md> [--council[=N]] [--no-recon]`

- Explicit invocation only (`disable-model-invocation: true`, same as `/hq`).
- **Mode detection**, first thing:
  - repo mode: `git rev-parse --is-inside-work-tree` succeeds AND `.git` at
    the toplevel is a directory (a hub, not a worktree). Design dir is
    `<repo>/docs/design/<slug>/` — unless the repo already has an obvious
    design/ADR directory, in which case match it.
  - greenfield mode: anything else. Design dir is `~/dev/hq/designs/<slug>/`.
    No hq repo → stop and say so (same behavior as `/hq` when `routing.md` is
    missing; `bin/hq-init` scaffolds `designs/`).
- Argument is a path → **resume**: read `design.md`, pick up from the
  `status` in its frontmatter. Otherwise derive a kebab-case slug from the
  idea and scaffold.
- A design is a **directory**, not a single file, so moving it (greenfield →
  new repo) is one `mv`:
  ```
  <slug>/
    design.md          # the doc; frontmatter status drives resume
    recon.md           # recon output (may be near-empty in greenfield)
    proposals/N.md     # only with --council: raw independent proposals
  ```

### Model

Questioning is interactive, so it MUST run in the invoking session (subagents
cannot talk to the user). The skill checks the model the session is running
on (the session knows it from its system prompt). If it is not the strongest
available (`fable` today), it asks via `AskUserQuestion` whether to continue
anyway or stop so the user can `/model fable` (or set `ANTHROPIC_MODEL`) and
re-run. Question quality is the product; never silently proceed on a weaker
model.

### Design doc template (`design.md`)

```markdown
---
status: understanding        # understanding | options | deciding | approved
slug: <slug>
mode: greenfield | repo
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
# <Title>

## Prompt
<the opening request, verbatim>

## Context
<summary of recon.md; "nothing relevant found" is a valid entry>

## Requirements
### Problem and audience
### Smallest useful version
### Constraints            (stack, hosting, budget, timeline, team)
### Integrations           (what it must talk to / live alongside)
### Non-goals
### Success criteria

## Q&A log
<every question and answer, verbatim, appended as they happen — this is the
 resume state and the tuning signal>

## Options
<2–3 approaches, each: summary, how it meets the requirements, tradeoffs>

## Decisions log
<one entry per decision point: chosen, rejected alternatives, why>

## Design
<chosen approach: components, data model sketch, key interfaces, risks>

## Assumptions
<every unverified premise, each VERIFIED (evidence) or ASSUMED — same
 convention as workplans>

## Open questions

## Next steps
<mode-specific, see Handoff>

## Retro
<two lines appended at the end of every session: what felt slow, what it
 wished it had asked>
```

The file is rewritten after **every** answer, not at the end — a killed
session loses at most one question.

### Steps

**1. Locate and scaffold.** Mode detection, slug, create the dir + `design.md`
skeleton with `status: understanding`, Prompt filled in. Print the path.

**2. Recon** (skip with `--no-recon`). One background subagent (`high`,
`model: fable`) writes `recon.md`: repo mode → relevant code, existing
docs/workplans, open PRs touching the area; greenfield → wiki pages
(`~/dev/wiki/wiki/_index/INDEX.md`), `~/dev/hq/state/backlog.md` mentions,
routing-table repos that look related. Hard budget: a few minutes; "nothing
relevant found" is a fine result. The main session summarizes it into
`## Context`. Questioning does not start until recon lands (the summary is what
makes question 1 informed).

**3. Understand** (`status: understanding`). Work through the six requirement
areas in the template's order. Rules, all in the skill file (this is the
tunable part):
- One `AskUserQuestion` call per question, one question per call.
- 2–4 options where the space is enumerable, the recommended one first and
  marked "(Recommended)"; free text is always possible via Other.
- Skip an area the Prompt or Context already answers; say so in the log.
- Follow-ups within an area are allowed when an answer is ambiguous;
  otherwise move on.
- After each answer: append to `## Q&A log`, update the relevant
  Requirements subsection, write the file.
- Budget guidance ~10–15 questions. The header of every question reminds the
  user they can answer "enough" to jump to the summary.
- **Gate:** present the Requirements summary; `AskUserQuestion` approve /
  correct. Corrections loop back into the relevant area. On approval set
  `status: options`.

**4. Explore options** (`status: options`).
- Default: the main session writes 2–3 architectures into `## Options`,
  each evaluated against the approved Requirements.
- `--council[=N]` (N defaults to 3): spawn N background agents (`xhigh`,
  `model: fable`), each given ONLY the Requirements + Context sections and
  told to write one complete proposal to `proposals/N.md` without seeing the
  others. When all land, the main session synthesizes them into `## Options`
  (merge duplicates, keep genuine disagreements as separate options, cite
  which proposal each came from). Proposers never interact with the user.
- Then `status: deciding`.

**5. Decide** (`status: deciding`). For each real decision point (which
option; then the sub-decisions it opens — datastore, sync vs async, etc.):
one `AskUserQuestion`, recommendation first, and a `## Decisions log` entry
recording chosen + rejected + why. Then write `## Design`, `## Assumptions`,
`## Open questions`. **Gate:** approve / revise. On approval set
`status: approved`.

**6. Handoff.** Fill `## Next steps` per mode; append `## Retro`; leave
everything UNCOMMITTED (the user commits, matching the workplan convention);
print the path and the next-steps list.
- greenfield: create the repo (name suggestion), add a routing row in
  `~/dev/hq/routing.md`, `mv` the design dir into the repo's design folder,
  then per milestone: plan mode → `workplans/<slug>-plan.md` → `/feature`.
- repo mode: the list of workplans to write (one per milestone/PR), first one
  named; then the usual plan mode → workplan → `/feature`.

## Files

- `dots/claude/skills/brainstorm/SKILL.md` — NEW. Frontmatter (`name`,
  `description`, `disable-model-invocation: true`), flags, mode detection,
  model check, the six steps, the question rules, the template inline (or in
  a sibling `TEMPLATE.md` the skill reads — sibling preferred so the template
  is editable without touching the protocol).
- `dots/claude/skills/brainstorm/TEMPLATE.md` — NEW. The design doc skeleton
  above.
- `templates/hq/CLAUDE.md` — Conventions bullet: greenfield design docs live
  in `designs/<slug>/` (written by `/brainstorm`), graduate to the repo once
  it exists.
- `templates/hq/gitignore` — nothing to add (`designs/` is tracked).
- `bin/hq-init` — `mkdir -p "$target/designs"` and a `designs/.gitkeep` so
  the dir survives the initial commit; add a line to the Next: message.
- `CLAUDE.md` (dotfiles) — Conventions bullet after the `/hq` one: what
  `/brainstorm` is, the two modes, that it stops short of workplans/repos/
  `/feature`, and that it is claude-only.
- `bin/symlink_files.sh` — no change expected (it links every dir under
  `dots/claude/skills/`); verify the new skill lands in `~/.claude/skills/`.

## Ordered steps

1. Write `TEMPLATE.md`.
2. Write `SKILL.md`: frontmatter → flags → mode detection → model check →
   resume rules → steps 1–6 with the question rules spelled out → handoff
   text per mode. Keep it in the same voice/density as `feature/SKILL.md`.
3. `bin/hq-init` + `templates/hq/CLAUDE.md` glue.
4. Dotfiles `CLAUDE.md` bullet.
5. `bin/symlink_files.sh --check` (via `bin/doctor`) shows the new skill as
   the only pending link; run `bin/symlink_files.sh`.
6. Dry run 1 (greenfield): from hq, `/brainstorm a twitter clone` — walk to
   at least the Requirements gate, then kill the session; `/brainstorm
   ~/dev/hq/designs/twitter-clone` must resume at the right step with the
   Q&A log intact. Finish to `approved`; inspect `design.md` against the
   template. Delete the dir afterwards (it's a test).
7. Dry run 2 (repo mode): from the dotfiles hub, `/brainstorm` something
   small and real; confirm `docs/design/<slug>/` placement and the repo-mode
   next-steps text. Delete afterwards unless it's worth keeping.
8. Dry run 3: `--council=2` on run 1's requirements; confirm proposals are
   independent (different structure/tradeoffs, not paraphrases) and the
   synthesis keeps disagreements visible.

## Assumptions

- `AskUserQuestion` is available to the main session in auto mode and blocks
  until the user answers — VERIFIED (this planning session used it
  implicitly through its tool list; auto mode governs permissions, not the
  question tool).
- Background subagents cannot use `AskUserQuestion` / talk to the user —
  VERIFIED (harness docs: subagents run detached and report back; hence
  questioning stays in the invoking session).
- The session can tell which model it is running on — VERIFIED (the system
  prompt states the model; `feature/SKILL.md` already relies on per-seat
  model names).
- An hq repo exists at `~/dev/hq` on this machine — VERIFIED (`ls ~/dev/hq`
  shows CLAUDE.md, routing.md, state/).
- `docs/design/` collides with no convention in the repos this will be used
  on — ASSUMED; the skill matches an existing design/ADR dir when present.
- Writing the design file after every answer is cheap enough not to be felt
  in the dialogue — ASSUMED (one small file write per turn).
- `bin/symlink_files.sh` links every skill dir under `dots/claude/skills/`
  without a per-skill list — VERIFIED (`layer_tracked_items` loops over the
  tracked dir; no per-skill list).

## Test plan

No bash lands in this change, so `tests/run.sh` gains nothing. Verification
is the three dry runs in Ordered steps 6–8, plus:
- `bin/doctor` before/after step 5 (new link reported, then clean).
- `bin/hq-init /tmp/hq-test` on a scratch path: `designs/.gitkeep` present,
  initial commit includes it, message mentions designs. Remove the scratch
  dir.
- Skill frontmatter parses: the skill appears in the session's skill list
  after `/reload` (or a fresh session) with its description.

## Out of scope (this pass)

- `/feature` consuming a design doc directly (today: design doc → plan mode →
  workplan → `/feature`). Natural follow-up once a few designs exist.
- `/triage` graduating a `project`-altitude backlog item into `/brainstorm`.
- Automatic repo creation, routing-row edits, or moving the design dir — all
  listed in Next steps for the user to do.
- Wiki write-back of the finished design (do by hand; automate later if the
  knowledge rule's write-back keeps getting skipped).
- Codex sharing (`AskUserQuestion` has no codex equivalent).
- Updating the LIVE `~/dev/hq` (private repo): the user adds `designs/` and
  the CLAUDE.md bullet there by hand after this lands; `hq-init` only affects
  new scaffolds.
- Any change to the popup/dashboard/attention layer.

## Public-repo caution

Skill, template, and hq-template text must stay generic: example idea is
"a twitter clone", paths are `~/dev/hq` / `~/dev/<repo>` placeholders, no
service or employer names. Dry-run design dirs (steps 6–8) are deleted or
stay in private repos; never commit one to dotfiles.
