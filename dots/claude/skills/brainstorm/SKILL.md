---
name: brainstorm
description: Socratic design session for the fuzzy front end of meaty or greenfield work — one-question-at-a-time requirements dialogue, 2–3 architectures explored, decisions locked, ends in a durable design doc. Stops short of workplans, repo creation, and /feature; those come later from the design doc. Invoke ONLY on an explicit `/brainstorm ...` request — never self-initiate it for work merely described in conversation.
disable-model-invocation: true
---

Run a Socratic design session that ends in a design doc. The argument is
either a short description of an idea, or a path to an existing design
directory or `design.md` (resume), plus optional flags. This skill does not
write workplans, create repos, or invoke `/feature` — it hands off to that
flow at the end.

`/brainstorm <idea | path-to-existing-design-dir-or-design.md> [--council[=N]] [--no-recon]`

## Flags

- `--council[=N]` — step 4 (Explore options) spawns N background proposer
  agents instead of the main session writing options directly. N defaults to
  3 when the flag is given without a value.
- `--no-recon` — skip step 2 (Recon) entirely; go straight to questioning
  with only the Prompt as context.

## Mode detection

Do this first, before scaffolding anything:

- **Repo mode**: `git rev-parse --is-inside-work-tree` succeeds AND `.git` at
  the toplevel is a directory (a hub, not a linked worktree). Design dir is
  `<repo>/docs/design/<slug>/` — unless the repo already has an obvious
  design/ADR directory (e.g. `docs/adr/`, `design/`), in which case match
  that instead.
- **Greenfield mode**: anything else (including an hq session). Design dir is
  `~/dev/hq/designs/<slug>/`. No hq repo at `~/dev/hq` → STOP and say so, the
  same way `/hq` stops when `routing.md` is missing — mention that
  `~/dotfiles/bin/hq-init` scaffolds `designs/` along with the rest of hq.

## Design is a directory

```
<slug>/
  design.md          # the doc; frontmatter status drives resume
  recon.md            # recon output (may be near-empty in greenfield)
  proposals/N.md       # only with --council: raw independent proposals
```

A directory, not a single file, so moving it later (greenfield → the repo
that gets created from it) is one `mv` of the whole thing. The template for
`design.md` lives in the sibling `TEMPLATE.md` next to this file — read it at
scaffold time rather than duplicating its structure here, so the template
stays editable without touching this protocol.

## Model check

Questioning is interactive and MUST run in the invoking session — background
subagents cannot use `AskUserQuestion` or otherwise talk to the user. Before
scaffolding, check which model THIS session is running on (the system prompt
states it). If it is not the strongest available (`fable` today), use
`AskUserQuestion` to offer continue-anyway vs stop so the user can `/model
fable` (or set `ANTHROPIC_MODEL`) and re-run. Question quality is the
product of this skill — never silently proceed on a weaker model.

## Resume rules

- Argument is a path (to a design dir or its `design.md`) → **resume**: read
  `design.md`, pick up at the step matching its frontmatter `status`
  (`understanding` → step 3, `options` → step 4, `deciding` → step 5,
  `approved` → step 6). The Q&A log and every other section already written
  are preserved verbatim; only continue forward from where `status` left off.
- Otherwise → **new session**: derive a kebab-case slug from the idea and
  scaffold fresh (step 1).

## Per-answer rewrite rule

`design.md` is rewritten after **every** answer during questioning (step 3)
and after every decision (step 5) — not batched to the end of the step. A
killed session then loses at most one question's worth of work, and resuming
picks up from a file that is always current.

## Step 1 — Locate and scaffold

Run mode detection. New session: derive the slug, create
`<design-dir>/<slug>/`, write `design.md` from `TEMPLATE.md` with
`status: understanding`, `slug`, `mode`, `created`/`updated` filled in, and
`## Prompt` filled in verbatim from the argument. Resume: just locate the
existing dir. Either way, print the design dir path.

## Step 2 — Recon (skip with `--no-recon`)

Spawn ONE background subagent (`subagent_type: "high"`, `model: "fable"`) to
write `recon.md`. What it looks at depends on mode:

- **Repo mode**: code relevant to the idea, existing docs/workplans that
  touch the area, open PRs in the same area.
- **Greenfield mode**: relevant pages under `~/dev/wiki/wiki/_index/INDEX.md`,
  mentions of the idea in `~/dev/hq/state/backlog.md`, routing-table repos
  (`~/dev/hq/routing.md`) that look related.

Hard budget: a few minutes. "Nothing relevant found" is a fine, valid result
— do not stretch the search to manufacture findings. When it lands, the main
session summarizes `recon.md` into `## Context` in `design.md`. Questioning
(step 3) does not start until this lands — the `## Context` summary is what
makes question 1 informed rather than generic.

## Step 3 — Understand (`status: understanding`)

Work through the six Requirements subsections in the template's order:
Problem and audience, Smallest useful version, Constraints, Integrations,
Non-goals, Success criteria. Question rules, all tunable here:

- One `AskUserQuestion` call per question, one question per call — never
  batch multiple questions into a single call.
- 2–4 options where the space is enumerable, the recommended one listed
  first and labeled "(Recommended)"; free text is always reachable via
  Other.
- Skip an area the Prompt or Context already answers — say so in the Q&A log
  instead of asking a question that would just restate known information.
- Follow-up questions within an area are fine when an answer is ambiguous;
  otherwise move on to the next area.
- After EVERY answer: append the question and answer verbatim to `## Q&A
  log`, update the relevant Requirements subsection, and write `design.md`
  (see Per-answer rewrite rule above).
- Budget guidance: ~10–15 questions total across all six areas. Every
  question's header reminds the user they can answer "enough" to jump
  straight to the summary gate below.

**Gate**: once the areas are covered (or the user jumps ahead), present the
full Requirements summary and use `AskUserQuestion` to ask approve vs
correct. A correction loops back into the relevant area (more questions,
then re-present the summary). On approval, set `status: options` and write
the file.

## Step 4 — Explore options (`status: options`)

- **Default**: the main session writes 2–3 architectures directly into
  `## Options`, each evaluated against the approved Requirements (summary,
  how it meets the requirements, tradeoffs).
- **`--council[=N]`**: spawn N background agents (`subagent_type: "xhigh"`,
  `model: "fable"`), each given ONLY the `## Requirements` and `## Context`
  sections (never the others, and never each other's output) and told to
  write one complete, independent proposal to `proposals/N.md`. Proposers
  never interact with the user. When all N land, the main session
  synthesizes them into `## Options`: merge duplicate proposals, keep
  genuine disagreements as separate options, and cite which proposal(s) each
  option came from.

Either way, once `## Options` is written, set `status: deciding` and write
the file.

## Step 5 — Decide (`status: deciding`)

For each real decision point — which option first, then the sub-decisions it
opens (datastore, sync vs async, etc.) — one `AskUserQuestion`, recommended
choice first. After each: append a `## Decisions log` entry recording what
was chosen, what was rejected, and why. When all decision points are
resolved, write `## Design` (chosen approach: components, data model sketch,
key interfaces, risks), `## Assumptions` (every unverified premise, each
VERIFIED with evidence or ASSUMED — same convention as workplans), and
`## Open questions`.

**Gate**: present the Design for approval vs revise via `AskUserQuestion`. A
revise loops back to the relevant decision point. On approval, set `status:
approved` and write the file.

## Step 6 — Handoff

Fill `## Next steps` per mode, append two lines to `## Retro` (what felt
slow, what it wished it had asked), write the file. Leave everything
UNCOMMITTED — the user commits, matching the workplan convention. Print the
design dir path and the next-steps list.

- **Greenfield**: `## Next steps` lists — a name suggestion for the new repo;
  add a routing row for it in `~/dev/hq/routing.md` once it exists; `mv` this
  design dir into the new repo's design folder; then, per milestone, the
  usual plan mode → `workplans/<slug>-plan.md` → `/feature` flow. All of
  this is for the user to do by hand — this skill does not create repos,
  edit the routing table, or move the directory itself.
- **Repo mode**: `## Next steps` lists the workplans to write, one per
  milestone/PR, with the first one named; then the usual plan mode →
  `workplans/<slug>-plan.md` → `/feature` flow.
