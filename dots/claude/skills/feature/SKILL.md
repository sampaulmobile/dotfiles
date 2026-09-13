---
name: feature
description: End-to-end feature pipeline — spawn a worktree-isolated agent that plans, implements, runs an adversarial review/fix loop, and opens a PR. Hub-only and single-repo, for when the target is already known; anything else routes through /hq. Invoke ONLY on an explicit `/feature ...` request — typed by the user, or delivered by a cross-session dispatch (/hq); never self-initiate it for work merely described in conversation.
---

Run the end-to-end feature pipeline. The argument is either a short description of a feature/bug, or a path to an existing workplan doc, plus optional flags.

## Flags

**Per-seat model/effort** — value is `model` or `model:effort` (effort defaults to `high`). An explicit `--<seat>=` always wins over the convenience bundles below.
- `--orchestrator=<model[:effort]>` — planner / review-coordinator / shipper seat. Default `opus:high`.
- `--implementer=<model[:effort]>` — the coding seat. Default `sonnet:high`.
- `--reviewer=<model[:effort]>` — the review seat. Default `fable:high` for round 1; every later round and every prose-only round runs `opus` at the same effort. Passing this flag (or `--best`) pins one model for all rounds.
- `model` ∈ `opus|sonnet|fable|haiku`; `effort` ∈ `high|xhigh` (the presets that exist — see **Seat resolution**).

**Behavior**
- `--quick` — trivial task: skip the workplan doc, the plan gate and the review loop entirely (one implementer seat, no orchestrator/reviewer).
- `--go` — skip the plan gate: implement straight from the digest instead of waiting for the requester to approve it. Pass it only when the acceptance criteria name the specific change, not just the target — if the plan phase could conclude "nothing to change" or has to choose what to change, the gate stays on. Never skips the nothing-to-change stop in step 1.
- `--no-workplan` — keep the plan at `.feature/plan.md` instead of committing `workplans/<slug>-plan.md`; the review loop still runs (unlike `--quick`, which skips review entirely). Same effect as `[<repo>].workplans = false` in `~/.claude/repo-props.toml` for the target repo (see **Plan** in the full pipeline below).
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

> Implement the following in this worktree: <FEATURE>. First append to `.feature/status.jsonl` (mkdir `.feature`, add `.feature/` to `$(git rev-parse --git-common-dir)/info/exclude`) the line `{"repo","branch","pr":null,"phase":"implement","round":1,"seat":"implementer","task":"<one line>","last_commit":null,"pushed":false,"updated":<ISO-8601 UTC>,"started_by":"<user:/feature or hq:<session>>"}`, and append a fresh line on each commit and when you open the PR (`phase: done`, `pr` set) — never rewrite an existing line; a coordinator reads the last one to see where the pipeline is. Follow the repo's conventions and CLAUDE.md. Run the tests and linters relevant to what you touch and get them passing; name the surface the change's consumer meets and verify there, attaching the command and its output. Commit specific files only (never `git add -A`). When done and verified, invoke the `pr` skill to commit anything remaining, push, and open the PR. Report back ONLY: the PR URL and a 2-line summary.

When it reports back, relay the PR URL to the user. Done — the rest of this file does not apply to quick mode.

## Full pipeline

Spawn ONE background orchestrator agent (`subagent_type: "<ORCH_EFFORT>"`, `model: "<ORCH_MODEL>"` — resolved per `--orchestrator`, default `opus:high` — and `isolation: "worktree"`), using the prompt template below — fill in `<FEATURE>`, `<PLAN_PATH>` (if given), `<IMPL_MODEL>`/`<IMPL_EFFORT>` (default `sonnet:high`; `opus` with `--hard`), `<REVIEWER_MODEL>`/`<REVIEWER_EFFORT>` (default `fable:high`), `<MAX_ROUNDS>`, `<DEFAULT_BRANCH>`, `<SLUG>`, `<STRICT>` (true only with `--strict`), `<NO_WORKPLAN>` (true only with `--no-workplan`), `<GO>` (true only with `--go`), `<REVIEWER_PINNED>` (true only when `--reviewer=` or `--best` was given). Each seat's effort maps to its preset name and the model rides as an Agent `model:` override — see **Seat resolution**.

Multiple `/feature` invocations may run concurrently — each gets its own orchestrator and worktree.

Unless `--go`, the orchestrator's FIRST message back is the plan digest, and it then ends its turn with the one line `digest sent, awaiting go` as its result. Relay the digest verbatim — to the user, and to the dispatching session when a dispatch started this run — and stop. On a go, resume that orchestrator BY NAME with `SendMessage` ("go", plus any correction) — a new `/feature` would start over. Everything said about the plan goes back the same way.

This session never edits the pipeline's branch or PR by hand — not to fix a wrong result, not to finish a partial one. The loop's guarantee is that no code ships unreviewed, and a hand edit here is exactly that. A wrong or empty result is relayed as it is; the fix is a corrected brief and a new run, a resume of the orchestrator with the correction, or the human's own hands.

When the orchestrator reports back at the end, relay to the user: the PR URL, the summary, rounds used, any deferred non-blocking notes, and the Lessons block — or, if the loop escalated instead of shipping, the branch/worktree and open blockers awaiting a human decision. Apply the `wiki` and `backlog` lessons here after relaying them; the orchestrator is worktree-isolated and cannot commit in another tree. Keep the hub conversation clean — do not pull implementation details into it.

### Orchestrator prompt template

You are the orchestrator for one feature, working in an isolated git worktree. You do NOT write implementation code yourself — you plan, delegate, review, and ship. Every agent in this pipeline is ephemeral: all context that matters must live in files, so that a fresh agent with zero memory could pick up where any other left off.

Feature: <FEATURE>
Max review rounds: <MAX_ROUNDS>. Default branch: <DEFAULT_BRANCH>. Strict review: <STRICT>. No-workplan: <NO_WORKPLAN>. Skip the gate: <GO>.

**State files**
- `mkdir -p .feature` at the worktree root, and ensure it is ignored: append `.feature/` to `$(git rev-parse --git-common-dir)/info/exclude` if not already present. NEVER commit anything under `.feature/`.
- `.feature/NOTES.md` — running log. You and every subagent MUST append to it before finishing a step: decisions made and why, dead ends hit, gotchas, flaky tests. Write for a reader with zero memory of this session.
- `.feature/findings-round-<N>.md` — reviewer output per round.
- `.feature/status.jsonl` — the pipeline status contract, what a coordinator (hq) and `bin/worktrees` read to see where the pipeline is without a transcript. APPEND one JSON line per phase change and whenever the active seat or task changes; never rewrite or delete a line, so the file is also the run's history. The LAST line is the current state: `{"repo","branch","pr" (URL or null),"phase" (plan|gate|implement|review|review-fix|ship|done|stalled),"round","seat" (orchestrator|implementer|reviewer),"task" (one line),"last_commit","pushed" (bool),"updated" (ISO-8601 UTC),"started_by" ("user:/feature" or "hq:<session>" — whoever invoked the pipeline)}`. Tell every subagent to append a line with its `seat`/`task` when it starts and another with `last_commit` when it commits. Append `phase: done` in step 6, `phase: stalled` with the blockers in `task` when the loop stops without shipping.

**0. Branch**
- Rename this worktree's auto-generated branch to match the repo's convention (`git branch -m feature/<SLUG>` or `fix/<SLUG>`, or whatever CLAUDE.md prescribes). Never attempt to check out the default branch from inside the worktree — it is checked out at the hub and git will refuse.
- Check the base: `git merge-base HEAD <DEFAULT_BRANCH>` must equal `git rev-parse <DEFAULT_BRANCH>`. If it does not, the worktree was cut from a stale ref (the harness bases on `origin/<DEFAULT_BRANCH>`, which lags until a fetch): `git rebase <DEFAULT_BRANCH>` now, before any commit, and record it in NOTES.md.

**0b. Runtime files (only when a step needs them)**
- A fresh worktree does NOT carry the repo's gitignored files. If planning, implementing, or testing needs runtime files that live only in the hub checkout — secrets, TLS certs, `.env.*`, or caches like `.venv`/`node_modules` required to actually run or test — run `wt step copy-ignored` from inside this worktree to populate them before the step that needs them, and tell any subagent that will run/test the same. Skip it for pure code changes that don't execute anything requiring those files (it can copy gigabytes). Never hand-copy secrets or paste them into prompts.

**1. Plan**
- BEFORE reading any code, write the RESTATEMENT — Task (one sentence), Done means, Assuming — in your own words, from the request alone. A misread request is cheapest to catch here, and the restatement is what the digest below is checked against.
- Decide whether workplans are disabled for this repo: true if <NO_WORKPLAN> is true, or if `~/.claude/repo-props.toml` sets `[<key>].workplans` to `false` for `<key>` = the hub repo's directory basename. Resolve `<key>` and run the check with:
  ```
  REPO_KEY=$(basename "$(cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd)")
  python3 -c "
  import pathlib, sys
  key = sys.argv[1]
  path = pathlib.Path.home() / '.claude/repo-props.toml'
  try:
      import tomllib
      data = tomllib.load(open(path, 'rb'))
      print(str(bool(data.get(key, {}).get('workplans', True))).lower())
  except Exception:
      print('true')
  " "$REPO_KEY"
  ```
  (prints `true`/`false`; a missing or malformed properties file degrades to `true`, i.e. workplans allowed). `git rev-parse --git-common-dir` resolves through a worktree to the hub checkout's `.git`, so `<key>` names the hub repo even though this agent runs in a worktree.
- If a workplan path was provided (<PLAN_PATH>), read it — that plan is authoritative. If it lives outside this worktree (typically an uncommitted file at the hub), copy it here first: to `.feature/plan.md` when workplans are disabled, otherwise to `workplans/<basename>`; that copy is what gets committed below (skipped when workplans are disabled).
- Otherwise write one to `.feature/plan.md` (already untracked via the `.feature/` exclude — never commit it) when workplans are disabled, else to `workplans/<SLUG>-plan.md` (create the dir if the repo lacks it; if it exists, match the naming and style of the docs already in it). Spec it to handoff quality: goal, approach, files to touch, ordered steps, test plan, explicitly out of scope.
- The workplan MUST include an **Assumptions** section: every unverified premise the plan depends on, each marked VERIFIED (with the evidence) or ASSUMED. A claim that something is live/needed/consumed counts as verified only via consumer-side evidence (what reads it) — file existence, file counts, or mtimes never prove liveness.
- Never resolve a conflict between the task's explicit instruction and an assumption by silently doing MORE than instructed (e.g. preserving or migrating machinery the task said to remove). Either verify the assumption with direct evidence, or follow the literal instruction and record the judgment in Assumptions (it will reach the PR body), or report the single question back to the hub before implementing. Doing less as instructed is reviewable and reversible; silently adding machinery on an assumed premise is how rabbit holes start.
- If the brief forbids something this pipeline does by default (committing a workplan, opening a PR, the review loop) or its acceptance criteria presume a finding the plan did not make, that contradiction is the digest's Question and the gate is NOT skipped by `--go`: stop at step 1b and let the requester pick a side. Never resolve it by choosing.
- If planning concludes that no change is needed — the defect is not there, the feature already exists, the request is already satisfied — say so as the digest's Task line, append `phase: stalled` with `nothing to change` as the task to `.feature/status.jsonl`, commit nothing beyond the workplan, and report: no implementer, no PR, with or without `--go`. A pipeline never ships a change it could not find.
- With the plan written, revise the restatement into the DIGEST and put both at the top of the plan (restatement first, then the digest, then one line saying what reading the code changed — or "nothing"). The digest is: Task · Done means · Not doing · Assuming (only what is still ASSUMED, each with what would verify it) · Surface (where verification will run) · Touches (file count, key modules) · Question (zero or one — the single thing you would ask before building).
- Commit the workplan on its own before implementation starts — skip this when workplans are disabled; `.feature/plan.md` is never committed.

**1b. Gate** — skipped entirely when <GO> is true; go straight to step 2.
- Append a `phase: gate` line to `.feature/status.jsonl`, then `SendMessage` the digest verbatim to the session that spawned you (`to: "main"`) and END YOUR TURN — final text one line, `digest sent, awaiting go`, since that text reaches the same session as your result and the digest must not arrive twice. You cannot block mid-turn waiting for an answer, and with workplans disabled the plan is the uncommitted `.feature/plan.md` — the digest in that message is the copy the requester keeps.
- That session relays the digest and, on a go, resumes you by name. Resume at step 2. A correction arrives the same way: fold it into the workplan, commit the amendment, and only then implement. A correction that changes the goal means re-planning, not implementing around it.

**2. Implement (round N)**
Spawn a FRESH implementer subagent (`subagent_type: "<IMPL_EFFORT>"`, `model: "<IMPL_MODEL>"`, no extra isolation — it inherits this worktree). Its prompt must tell it to:
- Read the workplan (`workplans/<SLUG>-plan.md`, or `.feature/plan.md` when workplans are disabled per step 1), `.feature/NOTES.md`, and (round > 1) `.feature/findings-round-<N-1>.md`.
- Round 1: implement the plan. Later rounds: address every blocking finding, THEN rebase if the branch conflicts with <DEFAULT_BRANCH> — rebase first only when a conflict sits in code a finding touches.
- Follow repo conventions/CLAUDE.md; run the tests and linters relevant to what it touches and get them passing. If a test or run needs gitignored runtime files absent from the worktree (secrets/certs/`.env.*`/caches), run `wt step copy-ignored` first (see step 0b) — never hand-copy or inline secrets.
- When a cheap test path exists, write the failing test first, then the fix, then rerun.
- Verify on the surface, not just in the test suite: name the surface each change's consumer meets (test suite, local stack, CLI, dev warehouse, CI plan), verify there, and attach the observation — command plus output, row count, read-back of the stored value. Write "inconclusive" and why where it could not run.
- Commit as it goes — specific files only, never `git add -A`; clear messages in the repo's style.
- Append to `.feature/NOTES.md` before finishing. Do NOT push or open a PR.

**3. Review (round N)**
Before spawning, classify the round's delta. Round 1: DELTA is `git diff <DEFAULT_BRANCH>...HEAD`. Round N>1: DELTA is `git diff <reviewed-sha>..HEAD`, where `<reviewed-sha>` is the HEAD the previous review saw (step 4 records it in NOTES.md). PROSE-ONLY when every path in DELTA is markdown, skill, rule or doc text, or when the repo's prose-only tripwire (a `tests/check-prose-only.sh` or equivalent) passes on it.

Spawn a FRESH reviewer subagent (`subagent_type: "<REVIEWER_EFFORT>"`). Model: `<REVIEWER_MODEL>` in round 1; `opus` in every later round and in any prose-only round; `<REVIEWER_MODEL>` in every round when <REVIEWER_PINNED> is true. Give it the workplan path, the implementer's report (its NOTES.md entry), DELTA's base and head shas, and `.feature/findings-round-<N-1>.md` when N>1. Its prompt must include this severity bar verbatim (unless <STRICT> is true, in which case: any finding with a concrete failure scenario is blocking): "Mark a finding BLOCKING only if a senior human reviewer would request changes for it — a concrete correctness bug, security issue, missing test for new behavior, or an unintentional workplan deviation. Hardening suggestions, docs polish, and style preferences are non-blocking notes. Do not manufacture blockers to justify the round: on a small clean diff, CLEAN is the correct and expected verdict. An input that cannot occur given its trust boundary — operator-set config or an internal caller, not untrusted/network input — is a non-blocking note at most, never a blocking finding; do not require hardening against unrealizable inputs." And these rules, every round:
- Read-only on this checkout: never mutate the working tree, the index, HEAD or branch state. Inspect with `git diff`, `git show`, `git log` and by reading files.
- You do not dispatch subagents and you do not invoke review skills: do all of the review yourself. This process already provides every review seat the work gets; a reviewer you spawn duplicates one at full cost and its verdict counts for nothing. If the diff is too large for one pass, review it in passes yourself and say so.
- The implementer's report is unverified claims. Confirm it names the tests covering the change and shows their output, and verify its claims against the diff. Do not re-run the suite. Run one focused test only when reading the code raises a specific doubt no existing run answers.
- Do not crawl the codebase beyond DELTA and what it directly touches unless checking a named risk.
- Blast radius, only when DELTA adds or changes something destructive, network-facing or credential-adjacent (round 1), or touches such code (later rounds): name the ONE fact the change is safe because of and prove it by reading and by printing the path or target the code WOULD act on. Never execute a deletion as a probe, whatever the target is redirected to — the global deletion rule applies; a deletion that cannot be proven safe by reading is a finding that asks for a redesign. Unproven is reported as unproven, not as safe.
- Output: no preamble, no narration of what was checked. Every line is a verdict, a finding with file:line, or a check that was run.

Round 1 (FULL pass over the whole PR), two dimensions:
- Spec compliance against the workplan: Missing (a plan item skipped or half-done), Extra (unrequested features, over-engineering, scope creep), Misunderstood (the right item built wrong). Check `.feature/NOTES.md` before calling a deviation unintentional; a recorded, reasoned deviation is a note, not a blocker.
- Code quality: correctness bugs, unhandled edge cases, error handling, separation of concerns, DRY without premature abstraction, tests that verify real behavior rather than mocks, and conformance to the repo's CLAUDE.md and the global rules — comments, public-repo hygiene, deletion safety, tmux safety, CI/CD safety — with comment/prose noise as non-blocking notes and deletion of a load-bearing guard/why comment treated as a code change, not cleanup.

Round N>1 (SCOPED re-review): scope is the previous findings list and the fix diff, nothing else.
- Verdict every blocking finding from round N-1, in order: ADDRESSED or NOT ADDRESSED, with file:line evidence. "Attempted" is not addressed: the specific defect must no longer exist.
- New breakage in the fix diff: anything the fix itself broke or introduced.
- Out-of-scope observations: issues noticed outside the fix diff are listed as non-blocking and never extend the loop — except when the fix diff touches a destructive, network-facing or credential-adjacent path, in which case widen to that path, and say so on line 2.

Prose-only round (any N): no code review. Check contradictions between the changed files and the files they describe, stale file/flag/path references, public-repo leaks, comments-rule violations, and flag lists that match the flags the skill defines. Blocking only for a leak or a contradiction.

Findings file `.feature/findings-round-<N>.md`: line 1 the verdict, `CLEAN` or `FINDINGS`; line 2 the pass, `full`, `scoped`, `scoped→widened: <path>` or `prose`; then blocking findings (file:line, what is wrong, concrete failure scenario), then non-blocking notes (in a re-review: the per-finding verdicts, then new breakage, then out-of-scope observations), then the blast-radius line when one was required.

**4. Loop**
- `FINDINGS` → back to step 2 with the new findings file. A fix round is ALWAYS followed by another review round — never ship code the reviewer hasn't seen; the newest fix must not be the only unreviewed code.
- `CLEAN` → ship. (Non-blocking notes never hold up shipping; only blockers loop.)
- After every review, append `reviewed: <HEAD sha> round <N>` to `.feature/NOTES.md` — the next round's DELTA starts there.
- <MAX_ROUNDS> rounds used and the latest review still has BLOCKING findings → the loop is not converging: do NOT ship. Stop and report back instead — branch, worktree path, rounds used, and the open blockers verbatim — so a human decides (ship anyway, grant more rounds, or take over).

**5. Ship**
- Write the Lessons (below) FIRST, so a `repo` lesson's CLAUDE.md edit is in the diff the PR opens with and nothing is added to the branch after this step.
- Invoke the `pr` skill (it commits anything outstanding, pushes, opens the PR) and give it the body material in that skill's sections.
- "Open for the reviewer" carries what a human still has to judge: assumptions the run never verified, the deferred reviewer notes that matter, product decisions taken on the pipeline's own authority, and any surface that could not be verified. The remaining deferred notes go in the commit body, not the PR.

**6. Report**
Reply with ONLY: the PR URL (raw, on its own line), a 2-line summary of what was built, rounds used, count of unresolved findings, the worktree path, and the Lessons block below.

**Lessons** — at most three, each a FACT the run learned (a gotcha, a convention, a follow-up), never a preference about how the user wants work done. Written at step 5, before the push. Tag each `repo`, `wiki`, `backlog`, `dotfiles` or `none`:
- `repo` — write it into the repo's CLAUDE.md and name it under "Open for the reviewer": prose the human on the PR judges. Under `--local` there is no PR body, so name it in the report instead.
- `wiki` — report it; the hub session appends it to the repo's module page in the vault and commits, per the knowledge rule.
- `backlog` — report it; the hub session appends it to the hq backlog as an inbox item.
- `dotfiles` — propose it in the report only. Never apply it.
- `none` — worth saying once, worth writing nowhere.
