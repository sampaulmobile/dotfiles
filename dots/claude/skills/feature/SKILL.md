---
name: feature
description: End-to-end feature pipeline. Launch (from a repo's main checkout) creates the branch's worktree and its tmux task session; the claude in that session Runs the pipeline — plans, implements, runs an adversarial review/fix loop, and opens a PR. Single-repo, for when the target is already known; anything else routes through /hq. Invoke ONLY on an explicit `/feature ...` request — typed by the user, or delivered by a cross-session dispatch (/hq); never self-initiate it for work merely described in conversation.
---

Run the end-to-end feature pipeline. The argument is either a short description of a feature/bug, or a path to an existing workplan doc, plus optional flags.

Two entry points live in this file, selected by `--run`:

- **Launch** (no `--run`) — from a repo's MAIN checkout. Creates the branch's worktree and its tmux task session and types the Run invocation into it, then reports the session name and is done. It plans nothing and writes no code.
- **Run** (`--run`) — inside that worktree, as the task session's own claude. This session IS the orchestrator: it plans, delegates to implementer and reviewer subagents, and ships.

Every run therefore lives in its own worktree and its own tmux session, as a peer of whoever launched it. Any session can be cleared at any time without losing or hiding a run in flight; `.feature/status.jsonl` in the worktree is where its state lives.

## Flags

**Per-seat model/effort** — value is `model` or `model:effort` (effort defaults to `high`). An explicit `--<seat>=` always wins over the convenience bundles below.
- `--orchestrator=<model[:effort]>` — planner / review-coordinator / shipper seat. Default `opus:high`.
- `--implementer=<model[:effort]>` — the coding seat. Default `sonnet:high`.
- `--reviewer=<model[:effort]>` — the review seat. Default `fable:high` for round 1; every later round and every prose-only round runs `opus` at the same effort. Passing this flag (or `--best`) pins one model for all rounds.
- `model` ∈ `opus|sonnet|fable|haiku`; `effort` ∈ `high|xhigh` (the presets that exist — see **Seat resolution**).

**Entry point and addressing**
- `--run` — execute the pipeline in the worktree this session is in. Its absence means Launch.
- `--repo=<path>` — the main checkout to launch from. Default: the repo the cwd is in.
- `--requester=<session>` — the session Run reports the digest and the final result to, by `SendMessage`. Set it only to a session name that answers in `ListAgents` (a dispatcher such as hq names itself here). Omitted, Run reports in its own terminal, where the human reads it.

**Behavior**
- `--quick` — small task: skip the workplan doc, the plan gate and the review loop entirely (one implementer seat, no review). The deliverable follows the work — a PR when the run produced commits, the findings themselves when it produced none.
- `--go` — skip the plan gate: implement straight from the digest instead of waiting for the requester to approve it. Pass it only when the acceptance criteria name the specific change, not just the target — if the plan phase could conclude "nothing to change" or has to choose what to change, the gate stays on. Never skips the nothing-to-change stop in step 1.
- `--no-workplan` — keep the plan at `.feature/plan.md` instead of committing `workplans/<slug>-plan.md`; the review loop still runs (unlike `--quick`, which skips review entirely). Same effect as `[<repo>].workplans = false` in `~/.claude/repo-props.toml` for the target repo (see **Plan** in the Run pipeline below).
- `--rounds N` — review/fix rounds before escalating (default 3). The loop always runs until a review returns CLEAN; hitting the cap with blockers still open stops and reports for a human decision — it never ships at the cap.
- `--strict` — reviewer blocks on ANY finding with a concrete failure scenario (default: only what a senior human reviewer would request changes for).
- `--local` — for repos with no push/PR access from this machine (e.g. a repo whose remote this machine isn't authed to): the ship step SKIPS `/pr` entirely. Instead Run leaves the reviewed work committed on its branch and reports: branch name, worktree path, diffstat, summary, and the merge command (`git merge <branch>` from the main checkout). Any unresolved findings go in the report instead of a PR body. Also use this mode automatically if `git push` fails with an auth/permission error — never retry pushes into a wall.

**Convenience bundles** (sugar over the per-seat params; an explicit `--<seat>=` overrides them):
- `--hard` — implementer model → `opus` (i.e. `--implementer=opus:high`).
- `--xhigh` — bump every seat's effort to `xhigh` (models unchanged).
- `--best` — best possible result, cost/time no object: every seat `fable:xhigh`, strict review bar, rounds cap 5. For correctness-critical or overnight work. Natural-language requests for more rigor ("this one's gnarly, go all out") map here — the user only needs to remember `--quick` and `--best`.

## Seat resolution

Each seat is a `<model>:<effort>` pair. Spawn it as **`subagent_type: "<effort>"`** (the effort preset in `~/.claude/agents/` — `high` / `xhigh`, pure config shims that pin ONLY effort, no role behavior) **with a `model: "<model>"` override** on the Agent call. The call-time `model` beats the preset's frontmatter, so effort comes from the preset while model is chosen per seat (the harness has no per-call effort param; frontmatter is the only way to pin effort). Add an effort level by dropping a `<name>.md` shim in `dots/claude/agents/`. If the requested effort has no preset, fall back to a plain agent with the matching `model:` (it inherits session effort).

The orchestrator seat is the exception: it is not a spawned agent but the task session's own claude, so `--orchestrator=<model[:effort]>` becomes `--model <model>` AND `--effort <effort>` on the claude command line Launch types. Both ride there explicitly; the seat is never left to the machine's `settings.json` `effortLevel`.

## Launch

**0. Precondition — main checkout, single repo.** Verify BEFORE anything else:
- the target (`--repo=<path>`, default the cwd's repo via `git rev-parse --show-toplevel`) is a git repo's MAIN checkout: `.git` at its toplevel is a directory. A `.git` FILE means a linked worktree — refuse.
- the request targets THAT repo, and only that repo. /feature is single-repo by design; multi-repo work is decomposed upstream.

Any check fails (a worktree target, wrong repo, multi-repo request) → STOP without creating anything and tell the user to run `/hq <request>` instead — /hq owns routing and will dispatch back correctly. Never delegate or guess a target from here.

**1. Parse** flags and the feature description / plan path from the arguments. A plan path is resolved to an ABSOLUTE path here — Run works in a different directory, and a relative path would silently miss. An uncommitted plan sitting in the main checkout stays readable from the worktree by that absolute path.

**2. Default branch:** `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||'` (fall back to `main`).

**3. Pull.** New worktrees branch from local state, so `git -C <repo> pull` first.

**4. Branch name:** derive a short kebab-case slug from the feature and name the branch by the repo's convention (`feat/<slug>`, `fix/<slug>`, or whatever its CLAUDE.md prescribes).

**5. Worktree:** `cd <repo> && wt switch -c <branch>` — worktrunk lands the `<repo-dir>.<branch-slug>` sibling; never raw `git worktree add`. From an agent shell no tmux session is built (that is step 6's job). Resolve the path it created:

```
WT=$(git -C <repo> worktree list --porcelain | awk -v b="refs/heads/<branch>" '/^worktree /{p=$2} $0=="branch "b{print p}')
```

**6. Task session.** Write the Run invocation to a scratch file, then hand it to the launcher:

```
cat > /tmp/feature-launch-<SLUG>.md <<'LAUNCH_EOF'
/feature --run --requester=<REQUESTER> <PASSTHROUGH FLAGS>

Plan: <ABSOLUTE plan path>

<FEATURE / the brief, verbatim>
LAUNCH_EOF
~/dotfiles/bin/tmux-task-session --model <ORCH_MODEL> --effort <ORCH_EFFORT> "$WT" "$(cat /tmp/feature-launch-<SLUG>.md)"
```

The quoted heredoc delimiter and the `"$(cat ...)"` are what make this exact: the task, the flags and the requester reach Run through a file, never through a string a model retyped. `<PASSTHROUGH FLAGS>` is every flag this Launch received except `--repo=` and `--orchestrator=`, whose seat is already on the claude command line above. Drop `--requester=` entirely when no session should be reported to, and the `Plan:` line when no workplan was given.

`tmux-task-session` prints the session name. It is creation-only: it never switches a client, so the caller's screen does not move, and it leaves an existing session of that name alone.

**7. Report** the session name, the worktree path and the branch, and stop. Launch is done here.

### After a Launch, on the requester's side

When this Launch named this session as `--requester=`, the task session's FIRST message back is the plan digest (unless `--go`), and nothing else arrives until it is answered. Relay the digest verbatim — to the user, and onward to the session that dispatched this run when one did — and stop. On a go, `SendMessage` the task session BY NAME with "go" plus any correction; a second `/feature` would start over. Everything said about the plan goes back the same way. With no requester named, the digest appears in the task session's own terminal instead: tell the user the session name to visit (Ctrl+F) and there is nothing to relay.

This session never edits the pipeline's branch or PR by hand — not to fix a wrong result, not to finish a partial one. The loop's guarantee is that no code ships unreviewed, and a hand edit here is exactly that. A wrong or empty result is relayed as it is; the fix is a corrected brief and a new run, a resume of the task session with the correction, or the human's own hands.

When the task session reports back at the end, relay to the user: the PR URL (the findings themselves when a `--quick` run produced no commits), the summary, rounds used, any deferred non-blocking notes, and the Lessons block — or, if the loop escalated instead of shipping, the branch/worktree and open blockers awaiting a human decision. Apply the `wiki` and `backlog` lessons here after relaying them; the task session works in the feature's worktree and must not commit in another repo. Keep this conversation clean — do not pull implementation details into it.

Multiple `/feature` runs may be in flight at once — each has its own worktree and its own session.

## Run

**Precondition:** the cwd is a LINKED worktree — `.git` at the toplevel is a FILE. A directory means a main checkout: refuse, and say to launch instead (`/feature <task>` with no `--run`).

You are the orchestrator for one feature, working in this worktree. You do NOT write implementation code yourself — you plan, delegate, review, and ship. Every subagent in this pipeline is ephemeral: all context that matters must live in files, so that a fresh agent with zero memory could pick up where any other left off.

Feature, flags and requester come from the invocation you were started with, which `.feature/launch-prompt.md` holds verbatim; a `Plan:` line in it names an existing workplan. The default branch is `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||'` (fall back to `main`); the slug is this worktree's branch name after its `<type>/` prefix.

**State files**
- `mkdir -p .feature` at the worktree root, and ensure it is ignored: append `.feature/` to `$(git rev-parse --git-common-dir)/info/exclude` if not already present. NEVER commit anything under `.feature/`.
- `.feature/launch-prompt.md` — what Launch asked for, written before this session started. It is the brief of record; re-read it after a `/clear`.
- `.feature/NOTES.md` — running log. You and every subagent MUST append to it before finishing a step: decisions made and why, dead ends hit, gotchas, flaky tests. Write for a reader with zero memory of this session.
- `.feature/findings-round-<N>.md` — reviewer output per round.
- `.feature/status.jsonl` — the pipeline status contract, what a coordinator (hq) and `bin/worktrees` read to see where the pipeline is without a transcript. APPEND one JSON line per phase change and whenever the active seat or task changes; never rewrite or delete a line, so the file is also the run's history. The LAST line is the current state: `{"repo","branch","pr" (URL or null),"phase" (plan|gate|implement|review|review-fix|ship|done|stalled),"round","seat" (orchestrator|implementer|reviewer),"task" (one line),"last_commit","pushed" (bool),"updated" (the OUTPUT of `date -u +%Y-%m-%dT%H:%M:%SZ`, never typed from memory — screens publish it as the run's age),"started_by" ("user:/feature" or "hq:<session>" — whoever invoked the pipeline)}`. Tell every subagent to append a line with its `seat`/`task` when it starts and another with `last_commit` when it commits. Append `phase: done` in step 6, `phase: stalled` with the blockers in `task` when the loop stops without shipping.

### Quick mode (--quick)

Spawn ONE background agent for the implementer seat (`subagent_type: "<IMPL_EFFORT>"`, `model: "<IMPL_MODEL>"` — resolved per `--implementer`, default `sonnet:high`; `opus` with `--hard`). No `isolation: "worktree"`: this session is already in the feature's worktree and the seat inherits it. Prompt (filled in):

> Implement the following in this worktree: <FEATURE>. First append to `.feature/status.jsonl` (mkdir `.feature`, add `.feature/` to `$(git rev-parse --git-common-dir)/info/exclude`) the line `{"repo","branch","pr":null,"phase":"implement","round":1,"seat":"implementer","task":"<one line>","last_commit":null,"pushed":false,"updated":<ISO-8601 UTC>,"started_by":"<user:/feature or hq:<session>>"}`, and append a fresh line on each commit and when you open the PR (`phase: done`, `pr` set) — never rewrite an existing line; a coordinator reads the last one to see where the pipeline is. Follow the repo's conventions and CLAUDE.md. Run the tests and linters relevant to what you touch and get them passing; add a test only where behaviour could silently regress, keep it proportionate to the change and prefer extending an existing test file to adding a new one; name the surface the change's consumer meets and verify there, attaching the command and its output. Commit specific files only (never `git add -A`). When done and verified: if the work produced commits, invoke the `pr` skill to commit anything remaining, push, and open the PR, and report back ONLY the PR URL and a 2-line summary. If it produced none — an investigation, a question, or a task that turned out to need no change — push nothing, open nothing, create no branch state, and report back the FINDINGS instead: the answer, with the evidence for it.

When it reports back, report per step 6 — the PR URL when the run committed, otherwise its findings. A quick run that concludes no change is needed says so and stops there: no commit, no PR. Done — the rest of this file does not apply to quick mode.

### Full pipeline

**0. Branch**
- Launch already named this worktree's branch by the repo's convention. Never attempt to check out the default branch from inside the worktree — it is checked out at the main checkout and git will refuse.
- Check the base: `git merge-base HEAD <DEFAULT_BRANCH>` must equal `git rev-parse <DEFAULT_BRANCH>`. If it does not, the worktree was cut from a stale ref: `git rebase <DEFAULT_BRANCH>` now, before any commit, and record it in NOTES.md.

**0b. Runtime files (only when a step needs them)**
- worktrunk's `pre-start` hook copies the repo's gitignored ENV/secrets/config into a new worktree but EXCLUDES the fat regenerable caches (`.venv`, `node_modules`, build dirs). So `.env.*`, certs and config are here already; a step that has to RUN the stack regenerates the caches inside this worktree (`uv sync` / `npm i` / `flutter pub get`), or runs a full `wt step copy-ignored` when it deliberately wants them copied. Tell any subagent that will run or test the same. Never hand-copy secrets or paste them into prompts.

**1. Plan**
- FIRST, append a `phase: plan` line to `.feature/status.jsonl` (`round: 1`, `seat: orchestrator`, `task` = the request in one line, `pr: null`, `started_by` set; Launch already made the dir and excluded it). Until this line exists the run is invisible to `bin/worktrees`, Ctrl+G and hq, and a `/clear` on the requester loses track of it.
- BEFORE reading any code, write the RESTATEMENT — Task (one sentence), Done means, Assuming — in your own words, from the request alone. A misread request is cheapest to catch here, and the restatement is what the digest below is checked against.
- Decide whether workplans are disabled for this repo: true if `--no-workplan` was passed, or if `~/.claude/repo-props.toml` sets `[<key>].workplans` to `false` for `<key>` = the repo's main-checkout directory basename. Resolve `<key>` and run the check with:
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
  (prints `true`/`false`; a missing or malformed properties file degrades to `true`, i.e. workplans allowed). `git rev-parse --git-common-dir` resolves through a worktree to the main checkout's `.git`, so `<key>` names the repo even though this session runs in a worktree.
- If a workplan path was provided, read it — that plan is authoritative. If it lives outside this worktree (typically an uncommitted file in the main checkout), copy it here first: to `.feature/plan.md` when workplans are disabled, otherwise to `workplans/<basename>`; that copy is what gets committed below (skipped when workplans are disabled).
- Otherwise write one to `.feature/plan.md` (already untracked via the `.feature/` exclude — never commit it) when workplans are disabled, else to `workplans/<SLUG>-plan.md` (create the dir if the repo lacks it; if it exists, match the naming and style of the docs already in it). Spec it to handoff quality: goal, approach, files to touch, ordered steps, test plan, explicitly out of scope.
- The workplan MUST include an **Assumptions** section: every unverified premise the plan depends on, each marked VERIFIED (with the evidence) or ASSUMED. A claim that something is live/needed/consumed counts as verified only via consumer-side evidence (what reads it) — file existence, file counts, or mtimes never prove liveness.
- Never resolve a conflict between the task's explicit instruction and an assumption by silently doing MORE than instructed (e.g. preserving or migrating machinery the task said to remove). Either verify the assumption with direct evidence, or follow the literal instruction and record the judgment in Assumptions (it will reach the PR body), or report the single question back to the requester before implementing. Doing less as instructed is reviewable and reversible; silently adding machinery on an assumed premise is how rabbit holes start.
- If the brief forbids something this pipeline does by default (committing a workplan, opening a PR, the review loop) or its acceptance criteria presume a finding the plan did not make, that contradiction is the digest's Question and the gate is NOT skipped by `--go`: stop at step 1b and let the requester pick a side. Never resolve it by choosing.
- If planning concludes that no change is needed — the defect is not there, the feature already exists, the request is already satisfied — say so as the digest's Task line, append `phase: stalled` with `nothing to change` as the task to `.feature/status.jsonl`, commit nothing beyond the workplan, and report: no implementer, no PR, with or without `--go`. A pipeline never ships a change it could not find.
- With the plan written, revise the restatement into the DIGEST and put both at the top of the plan (restatement first, then the digest, then one line saying what reading the code changed — or "nothing"). The digest is: Task · Done means · Not doing · Assuming (only what is still ASSUMED, each with what would verify it) · Surface (where verification will run) · Touches (file count, key modules) · Question (zero or one — the single thing you would ask before building).
- Commit the workplan on its own before implementation starts — skip this when workplans are disabled; `.feature/plan.md` is never committed.

**1b. Gate** — skipped entirely when `--go` was passed; go straight to step 2.
- Append a `phase: gate` line to `.feature/status.jsonl`, then `SendMessage` the digest verbatim to `<REQUESTER>` and END YOUR TURN — final text one line, `digest sent, awaiting go`, since the digest must not arrive twice at the same session. With no requester named, print the digest here as your whole turn instead and stop. You cannot block mid-turn waiting for an answer, and with workplans disabled the plan is the uncommitted `.feature/plan.md` — the digest in that message is the copy the requester keeps.
- The go comes back as a message to this session, or as the human typing it here. Resume at step 2. A correction arrives the same way: fold it into the workplan, commit the amendment, and only then implement. A correction that changes the goal means re-planning, not implementing around it.

**2. Implement (round N)**
Spawn a FRESH implementer subagent (`subagent_type: "<IMPL_EFFORT>"`, `model: "<IMPL_MODEL>"`, no extra isolation — it inherits this worktree). Its prompt must tell it to:
- Read the workplan (`workplans/<SLUG>-plan.md`, or `.feature/plan.md` when workplans are disabled per step 1), `.feature/NOTES.md`, and (round > 1) `.feature/findings-round-<N-1>.md`.
- Round 1: implement the plan. Later rounds: address every blocking finding, THEN rebase if the branch conflicts with <DEFAULT_BRANCH> — rebase first only when a conflict sits in code a finding touches.
- Follow repo conventions/CLAUDE.md; run the tests and linters relevant to what it touches and get them passing. If a test or run needs gitignored caches absent from the worktree, regenerate them here (see step 0b) — never hand-copy or inline secrets.
- When a cheap test path exists, write the failing test first, then the fix, then rerun. Keep the test PROPORTIONATE to what it protects: extend an existing test file rather than adding a new one, and skip the test entirely where its scaffolding (a mock rig, a synthetic construction path that dodges the real schema, a log-capture handler) would cost more than the change and catch only what the diff already makes obvious. A test earns its place by covering behaviour that could silently regress — not by existing for every line touched. The suite pays for every test on every run.
- Verify on the surface, not just in the test suite: name the surface each change's consumer meets (test suite, local stack, CLI, dev warehouse, CI plan), verify there, and attach the observation — command plus output, row count, read-back of the stored value. Write "inconclusive" and why where it could not run.
- Commit as it goes — specific files only, never `git add -A`; clear messages in the repo's style.
- Append to `.feature/NOTES.md` before finishing. Do NOT push or open a PR.

**3. Review (round N)**
Before spawning, classify the round's delta. Round 1: DELTA is `git diff <DEFAULT_BRANCH>...HEAD`. Round N>1: DELTA is `git diff <reviewed-sha>..HEAD`, where `<reviewed-sha>` is the HEAD the previous review saw (step 4 records it in NOTES.md). PROSE-ONLY when every path in DELTA is markdown, skill, rule or doc text, or when the repo's prose-only tripwire (a `tests/check-prose-only.sh` or equivalent) passes on it.

Spawn a FRESH reviewer subagent (`subagent_type: "<REVIEWER_EFFORT>"`). Model: `<REVIEWER_MODEL>` in round 1; `opus` in every later round and in any prose-only round; `<REVIEWER_MODEL>` in every round when the reviewer model was pinned by `--reviewer=` or `--best`. Give it the workplan path, the implementer's report (its NOTES.md entry), DELTA's base and head shas, and `.feature/findings-round-<N-1>.md` when N>1. Its prompt must include this severity bar verbatim (unless `--strict` was passed, in which case: any finding with a concrete failure scenario is blocking): "Mark a finding BLOCKING only if a senior human reviewer would request changes for it — a concrete correctness bug, security issue, a missing test for behavior that could SILENTLY regress, or an unintentional workplan deviation. A missing test is NOT blocking when the only test available would need more scaffolding than the change it guards, or would only re-assert what the diff plainly shows. Hardening suggestions, docs polish, style preferences, and disproportionate tests are non-blocking notes. Do not manufacture blockers to justify the round: on a small clean diff, CLEAN is the correct and expected verdict. An input that cannot occur given its trust boundary — operator-set config or an internal caller, not untrusted/network input — is a non-blocking note at most, never a blocking finding; do not require hardening against unrealizable inputs." And these rules, every round:
- Read-only on this checkout: never mutate the working tree, the index, HEAD or branch state. Inspect with `git diff`, `git show`, `git log` and by reading files.
- You do not dispatch subagents and you do not invoke review skills: do all of the review yourself. This process already provides every review seat the work gets; a reviewer you spawn duplicates one at full cost and its verdict counts for nothing. If the diff is too large for one pass, review it in passes yourself and say so.
- The implementer's report is unverified claims. Confirm it names the tests covering the change and shows their output, and verify its claims against the diff. Do not re-run the suite. Run one focused test only when reading the code raises a specific doubt no existing run answers.
- Do not crawl the codebase beyond DELTA and what it directly touches unless checking a named risk.
- Blast radius, only when DELTA adds or changes something destructive, network-facing or credential-adjacent (round 1), or touches such code (later rounds): name the ONE fact the change is safe because of and prove it by reading and by printing the path or target the code WOULD act on. Never execute a deletion as a probe, whatever the target is redirected to — the global deletion rule applies; a deletion that cannot be proven safe by reading is a finding that asks for a redesign. Unproven is reported as unproven, not as safe.
- Output: no preamble, no narration of what was checked. Every line is a verdict, a finding with file:line, or a check that was run.

Round 1 (FULL pass over the whole PR), two dimensions:
- Spec compliance against the workplan: Missing (a plan item skipped or half-done), Extra (unrequested features, over-engineering, scope creep), Misunderstood (the right item built wrong). Check `.feature/NOTES.md` before calling a deviation unintentional; a recorded, reasoned deviation is a note, not a blocker.
- Code quality: correctness bugs, unhandled edge cases, error handling, separation of concerns, DRY without premature abstraction, tests that verify real behavior rather than mocks and that are proportionate to what they protect (scaffolding dwarfing the change, or a new test file where an existing one would do, is noise — flag it as you would comment noise), and conformance to the repo's CLAUDE.md and the global rules — comments, public-repo hygiene, deletion safety, tmux safety, CI/CD safety — with comment/prose noise as non-blocking notes and deletion of a load-bearing guard/why comment treated as a code change, not cleanup.

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
- If this branch already carries a PR, confirm it is still open (`gh pr view --json state`) before anything is committed. A PR that merged while the run was going takes no further commits: branch fresh off <DEFAULT_BRANCH> in its own worktree (`wt switch -c <branch>` run from the repo's MAIN checkout — `dirname $(git rev-parse --git-common-dir)`; never raw `git worktree add`) and ship the remaining work as its own PR, never onto the merged branch.
- Invoke the `pr` skill (it commits anything outstanding, pushes, opens the PR) and give it the body material in that skill's sections. The workplan is committed and the body links it; the body never restates the plan, the assumptions list or the review rounds.
- "Reviewer should check" carries what a human still has to judge: assumptions the run never verified, the deferred reviewer notes that matter, product decisions taken on the pipeline's own authority, and any surface that could not be verified. The remaining deferred notes go in the commit body, not the PR.

**6. Report**
`SendMessage` to `<REQUESTER>` — or, with no requester named, print here — ONLY: the PR URL (raw, on its own line; a `--quick` run that produced no commits reports its findings here instead), a 2-line summary of what was built, rounds used, count of unresolved findings, the worktree path, and the Lessons block below.

**Lessons** — at most three, each a FACT the run learned (a gotcha, a convention, a follow-up), never a preference about how the user wants work done. Written at step 5, before the push. Tag each `repo`, `wiki`, `backlog`, `dotfiles` or `none`:
- `repo` — write it into the repo's CLAUDE.md and name it under "Reviewer should check": prose the human on the PR judges. Under `--local` there is no PR body, so name it in the report instead.
- `wiki` — report it; the requester appends it to the repo's module page in the vault and commits, per the knowledge rule.
- `backlog` — report it; the requester appends it to the hq backlog as an inbox item.
- `dotfiles` — propose it in the report only. Never apply it.
- `none` — worth saying once, worth writing nowhere.
