---
name: feature
description: End-to-end feature pipeline — spawn a worktree-isolated agent that plans, implements, runs an adversarial review/fix loop, and opens a PR. Hub-only and single-repo, for when the target is already known; anything else routes through /hq. Invoke ONLY on an explicit `/feature ...` request — typed by the user, or delivered by a cross-session dispatch (/hq); never self-initiate it for work merely described in conversation.
---

Run the end-to-end feature pipeline. The argument is either a short description of a feature/bug, or a path to an existing workplan doc, plus optional flags.

## Flags

**Per-seat model/effort** — value is `model` or `model:effort` (effort defaults to `high`). An explicit `--<seat>=` always wins over the convenience bundles below.
- `--orchestrator=<model[:effort]>` — planner / review-coordinator / shipper seat. Default `fable:high`.
- `--implementer=<model[:effort]>` — the coding seat. Default `sonnet:high`.
- `--reviewer=<model[:effort]>` — the adversarial-review seat. Default `fable:high`.
- `model` ∈ `opus|sonnet|fable|haiku`; `effort` ∈ `high|xhigh` (the presets that exist — see **Seat resolution**).

**Behavior**
- `--quick` — trivial task: skip the workplan doc and the review loop entirely (one implementer seat, no orchestrator/reviewer).
- `--rounds N` — review/fix rounds before escalating (default 3). The loop always runs until a review returns CLEAN; hitting the cap with blockers still open stops and reports for a human decision — it never ships at the cap.
- `--strict` — reviewer blocks on ANY finding with a concrete failure scenario (default: only what a senior human reviewer would request changes for).
- `--local` — for repos with no push/PR access from this machine (e.g. a repo whose remote this machine isn't authed to): the ship step SKIPS `/pr` entirely. Instead the orchestrator leaves the reviewed work committed on its branch and reports: branch name, worktree path, diffstat, summary, and the merge command (`git merge <branch>` from the main checkout). Any unresolved findings go in the report instead of a PR body. Also use this mode automatically if `git push` fails with an auth/permission error — never retry pushes into a wall.

**Convenience bundles** (sugar over the per-seat params; an explicit `--<seat>=` overrides them):
- `--hard` — implementer model → `opus` (i.e. `--implementer=opus:high`).
- `--xhigh` — bump every seat's effort to `xhigh` (models unchanged).
- `--best` — best possible result, cost/time no object: every seat `fable:xhigh`, strict review bar, rounds cap 5. For correctness-critical or overnight work. Natural-language requests for more rigor ("this one's gnarly, go all out") map here — the user only needs to remember `--quick` and `--best`.

## Seat resolution

Each seat is a `<model>:<effort>` pair. Spawn it as **`subagent_type: "<effort>"`** (the effort preset in `~/.claude/agents/` — `high` / `xhigh`, pure config shims that pin ONLY effort, no role behavior) **with a `model: "<model>"` override** on the Agent call. The call-time `model` beats the preset's frontmatter, so effort comes from the preset while model is chosen per seat — that's why only two presets exist (the harness has no per-call effort param; frontmatter is the only way to pin effort). Add an effort level by dropping a `<name>.md` shim in `dots/claude/agents/`. If the requested effort has no preset, fall back to a plain agent with the matching `model:` (it inherits session effort).

## Setup (in the hub session)

0. Precondition — hub shell, single repo. Verify BEFORE anything else:
   - cwd is inside a git repo's MAIN checkout: `git rev-parse
     --is-inside-work-tree` succeeds AND `.git` at the toplevel is a
     directory. A `.git` FILE means a linked worktree — refuse.
   - the request targets THIS repo, and only this repo. /feature is
     single-repo by design; multi-repo work is decomposed upstream.
   Any check fails (worktree shell, hq, wrong repo, multi-repo request) →
   STOP without spawning anything and tell the user to run `/hq <request>`
   instead — /hq owns routing and will dispatch back here correctly. Never
   delegate or guess a target from here.
1. Parse flags and the feature description / plan path from the arguments. A plan path is resolved to an ABSOLUTE path in the hub before spawning — the orchestrator runs in a fresh worktree, and a hub-only (uncommitted) workplan does not exist there, so a relative path would silently miss.
2. Determine the default branch: `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||'` (fall back to `main`).
3. New worktrees branch from local state — if the hub hasn't been pulled recently, `git pull` first.
4. Derive a short kebab-case slug from the feature (e.g. `fix-upload-retry`).

## Quick mode (--quick)

Spawn ONE background agent for the implementer seat (`subagent_type: "<IMPL_EFFORT>"`, `model: "<IMPL_MODEL>"` — resolved per `--implementer`, default `sonnet:high`; `opus` with `--hard` — and `isolation: "worktree"`) with this prompt (filled in):

> Implement the following in this worktree: <FEATURE>. Follow the repo's conventions and CLAUDE.md. Run the tests and linters relevant to what you touch and get them passing. Commit specific files only (never `git add -A`). When done and verified, invoke the `pr` skill to commit anything remaining, push, and open the PR. Report back ONLY: the PR URL and a 2-line summary.

When it reports back, relay the PR URL to the user. Done — the rest of this file does not apply to quick mode.

## Full pipeline

Spawn ONE background orchestrator agent (`subagent_type: "<ORCH_EFFORT>"`, `model: "<ORCH_MODEL>"` — resolved per `--orchestrator`, default `fable:high` — and `isolation: "worktree"`), using the prompt template below — fill in `<FEATURE>`, `<PLAN_PATH>` (if given), `<IMPL_MODEL>`/`<IMPL_EFFORT>` (default `sonnet:high`; `opus` with `--hard`), `<REVIEWER_MODEL>`/`<REVIEWER_EFFORT>` (default `fable:high`), `<MAX_ROUNDS>`, `<DEFAULT_BRANCH>`, `<SLUG>`, `<STRICT>` (true only with `--strict`). Each seat's effort maps to its preset name and the model rides as an Agent `model:` override — see **Seat resolution**.

Multiple `/feature` invocations may run concurrently — each gets its own orchestrator and worktree.

When the orchestrator reports back, relay to the user: the PR URL, the summary, rounds used, and any deferred non-blocking notes — or, if the loop escalated instead of shipping, the branch/worktree and open blockers awaiting a human decision. Keep the hub conversation clean — do not pull implementation details into it.

### Orchestrator prompt template

You are the orchestrator for one feature, working in an isolated git worktree. You do NOT write implementation code yourself — you plan, delegate, review, and ship. Every agent in this pipeline is ephemeral: all context that matters must live in files, so that a fresh agent with zero memory could pick up where any other left off.

Feature: <FEATURE>
Max review rounds: <MAX_ROUNDS>. Default branch: <DEFAULT_BRANCH>. Strict review: <STRICT>.

**State files**
- `mkdir -p .feature` at the worktree root, and ensure it is ignored: append `.feature/` to `$(git rev-parse --git-common-dir)/info/exclude` if not already present. NEVER commit anything under `.feature/`.
- `.feature/NOTES.md` — running log. You and every subagent MUST append to it before finishing a step: decisions made and why, dead ends hit, gotchas, flaky tests. Write for a reader with zero memory of this session.
- `.feature/findings-round-<N>.md` — reviewer output per round.

**0. Branch**
- Rename this worktree's auto-generated branch to match the repo's convention (`git branch -m feature/<SLUG>` or `fix/<SLUG>`, or whatever CLAUDE.md prescribes). Never attempt to check out the default branch from inside the worktree — it is checked out at the hub and git will refuse.

**0b. Runtime files (only when a step needs them)**
- A fresh worktree does NOT carry the repo's gitignored files. If planning, implementing, or testing needs runtime files that live only in the hub checkout — secrets, TLS certs, `.env.*`, or caches like `.venv`/`node_modules` required to actually run or test — run `wt step copy-ignored` from inside this worktree to populate them before the step that needs them, and tell any subagent that will run/test the same. Skip it for pure code changes that don't execute anything requiring those files (it can copy gigabytes). Never hand-copy secrets or paste them into prompts.

**1. Plan**
- If a workplan path was provided (<PLAN_PATH>), read it — that plan is authoritative. If it lives outside this worktree (typically an uncommitted file at the hub), copy it to `workplans/<basename>` here first; that copy is what gets committed below.
- Otherwise write one to `workplans/<SLUG>-plan.md` (create the dir if the repo lacks it; if it exists, match the naming and style of the docs already in it). Spec it to handoff quality: goal, approach, files to touch, ordered steps, test plan, explicitly out of scope.
- The workplan MUST include an **Assumptions** section: every unverified premise the plan depends on, each marked VERIFIED (with the evidence) or ASSUMED. A claim that something is live/needed/consumed counts as verified only via consumer-side evidence (what reads it) — file existence, file counts, or mtimes never prove liveness.
- Never resolve a conflict between the task's explicit instruction and an assumption by silently doing MORE than instructed (e.g. preserving or migrating machinery the task said to remove). Either verify the assumption with direct evidence, or follow the literal instruction and record the judgment in Assumptions (it will reach the PR body), or report the single question back to the hub before implementing. Doing less as instructed is reviewable and reversible; silently adding machinery on an assumed premise is how rabbit holes start.
- Commit the workplan on its own before implementation starts.

**2. Implement (round N)**
Spawn a FRESH implementer subagent (`subagent_type: "<IMPL_EFFORT>"`, `model: "<IMPL_MODEL>"`, no extra isolation — it inherits this worktree). Its prompt must tell it to:
- Read the workplan, `.feature/NOTES.md`, and (round > 1) `.feature/findings-round-<N-1>.md`.
- Round 1: implement the plan. Later rounds: address every blocking finding.
- Follow repo conventions/CLAUDE.md; run the tests and linters relevant to what it touches and get them passing. If a test or run needs gitignored runtime files absent from the worktree (secrets/certs/`.env.*`/caches), run `wt step copy-ignored` first (see step 0b) — never hand-copy or inline secrets.
- Commit as it goes — specific files only, never `git add -A`; clear messages in the repo's style.
- Append to `.feature/NOTES.md` before finishing. Do NOT push or open a PR.

**3. Review (round N)**
Spawn a FRESH reviewer subagent (`subagent_type: "<REVIEWER_EFFORT>"`, `model: "<REVIEWER_MODEL>"`). Its prompt must include this severity bar verbatim (unless <STRICT> is true, in which case: any finding with a concrete failure scenario is blocking): "Mark a finding BLOCKING only if a senior human reviewer would request changes for it — a concrete correctness bug, security issue, missing test for new behavior, or an unintentional workplan deviation. Hardening suggestions, docs polish, and style preferences are non-blocking notes. Do not manufacture blockers to justify the round: on a small clean diff, CLEAN is the correct and expected verdict." The prompt must also tell it to:
- Adversarially review `git diff <DEFAULT_BRANCH>...HEAD`: correctness bugs, unhandled edge cases, missing or weak tests, security issues, and conformance to the workplan (flag scope creep and silently-skipped plan items; check `.feature/NOTES.md` before calling a deviation unintentional).
- If the `code-review` skill is available, invoke it as part of this pass.
- Write `.feature/findings-round-<N>.md`: first line is the verdict, `CLEAN` or `FINDINGS`; then blocking findings (file:line, what is wrong, concrete failure scenario), then non-blocking notes.

**4. Loop**
- `FINDINGS` → back to step 2 with the new findings file. A fix round is ALWAYS followed by another review round — never ship code the reviewer hasn't seen; the newest fix must not be the only unreviewed code.
- `CLEAN` → ship. (Non-blocking notes never hold up shipping; only blockers loop.)
- <MAX_ROUNDS> rounds used and the latest review still has BLOCKING findings → the loop is not converging: do NOT ship. Stop and report back instead — branch, worktree path, rounds used, and the open blockers verbatim — so a human decides (ship anyway, grant more rounds, or take over).

**5. Ship**
- Invoke the `pr` skill (it commits anything outstanding, pushes, opens the PR).
- Copy the workplan's Assumptions section into the PR body (`## Assumptions`) — premise errors must be catchable in human review, not buried in a committed workplan.
- If deliberately-deferred non-blocking notes exist, append a `## Deferred review notes` section to the PR body listing them verbatim.

**6. Report**
Reply with ONLY: the PR URL (raw, on its own line), a 2-line summary of what was built, rounds used, count of unresolved findings, and the worktree path.
