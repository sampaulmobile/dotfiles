# Workplan: option C topology — task sessions, no hub role (step 2a)

## Restatement (before reading the code)

- Task: move the agent pipeline to "option C" topology — every `/feature` run
  lives in its own worktree and its own tmux task session as a peer of whoever
  dispatched it, and the long-lived per-repo "hub session" role disappears from
  the skills, rules, templates and repo docs.
- Done means: `/feature` split into a Launch entry point (creates worktree +
  task session, types the Run invocation) and a Run entry point (executes the
  pipeline in the worktree it is in), with step 1's pipeline text preserved
  where this plan says PRESERVE; `/address-review` and `/hq` carry no hub
  wording and hq dispatches through Launch; `dots/claude/rules/worktrees.md`
  and `delegation.md` updated; `templates/hq/` drops the hub column and prose;
  a new agent-callable tmux launch helper that only ever CREATES a session,
  never switches the client or mutates an existing one, with an offline naming
  test; this repo's CLAUDE.md rewritten; `tests/run.sh` green under both bashes.
- Assuming: this plan is authoritative; step 1 is merged in this base;
  `new_hub_session` stays for the human paths; the plan's file list is
  complete; the end-to-end Launch and hq dispatch runs cannot be executed from
  inside the pipeline and go to the human test plan.

## Digest

- **Task** — Split `/feature` into a Launch and a Run entry point, add an
  agent-callable tmux launch helper that builds a worktree's task session, and
  strip the hub-session role from the three skills, two rules, the hq templates
  and this repo's CLAUDE.md.
- **Done means** — `bin/tmux-task-session` creates a worktree's tmux session
  (standard layout, agent window warm) and starts claude there with the Run
  invocation as its first turn, never switching the client and never touching
  an existing session; `/feature` has two entry points in one file, Launch
  (main checkout, makes the worktree + session, types Run) and Run (linked
  worktree, is the orchestrator itself); every PRESERVE item from step 1
  survives; `/hq` dispatch calls Launch with REPORT set to the hq session and
  has no find-or-spawn-hub step; `/address-review` finds-or-creates a checkout
  with no hub wording; the two rules, the two hq templates and CLAUDE.md carry
  no hub-session role; `tests/run.sh` green under both bashes with a new
  offline suite for the helper's naming and command building.
- **Not doing** — step 2b (`snapshot-collector-plan.md`); renaming
  `new_hub_session` or dropping its `-hub` peer suffix (see Question);
  `bin/worktrees`' internal `hub` shorthand for a repo's main checkout (a
  variable name for a directory, not the session role); parameterizing any
  repo's stack; any change to how implementer/reviewer seats are spawned.
- **Assuming**
  - `claude -n <name> '<prompt>'` starts an interactive session whose first
    turn is that prompt. Verified by: a throwaway `tmux -L` run that types the
    line and reads the pane back.
  - `SendMessage` to a peer session by name works from a claude started by
    typing into a tmux window. Verified by: a real Launch whose digest arrives
    at the requester (human test plan, item 1).
  - `/clear` in a session kills its background subagents. Verified by: clearing
    a session mid-run and watching its subagent stop (human test plan, item 3).
  - Run IS the task session's claude, so `--orchestrator=<model[:effort]>` maps
    to that claude's `--model` and its effort has no CLI knob to land on.
    Verified by: a Launch with `--orchestrator=opus` producing
    `claude --model opus -n <session> ...`.
- **Surface** — `tests/run.sh` under `/bin/bash` 3.2 and the default bash; a
  throwaway `tmux -L task-session-test-$$` server for the helper's real
  behavior; a read of the rendered skill text for the Launch/Run split and the
  typed Run invocation.
- **Touches** — 11 files: `dots/claude/skills/{feature,hq,address-review}/SKILL.md`,
  `dots/claude/rules/{worktrees,delegation}.md`, `templates/hq/{CLAUDE.md,routing.md}`,
  `bin/tmux-task-session` (new), `bin/tmux-claude-lib`, `tests/test-task-session.sh`
  (new), `tests/run.sh`, `CLAUDE.md`.
- **Question** — `new_hub_session` still names a main-checkout session's claude
  `<basename>-hub`, and the function keeps that name. Nothing consumes the
  suffix once `/hq`'s find-or-spawn-hub step is gone. Leave both as they are
  (this plan's default: the plan says the human path is kept, and renaming the
  peer changes how the user's existing repo sessions are addressed), or rename
  the function to `new_agent_session` and drop the `-hub` suffix in the same
  pass?

Reading the code changed: the launch helper became a standalone
`bin/tmux-task-session` over an extracted shared layout function rather than a
new mode of `new_hub_session`, and Launch passes the Run invocation as claude's
initial-prompt argument sourced from a `.feature/` file, so an arbitrary brief
reaches Run byte-for-byte with no shell quoting hazard.

## Goal

Every `/feature` run lives in its own worktree and its own tmux session, as a
peer of the dispatcher rather than a subagent inside a long-lived per-repo
"hub" session. Any session — hq or a repo session — can be cleared at any
time and nothing in flight is lost or hidden. Depends on step 1
(`pipeline-state-and-pr-shape-plan.md`, merged 2026-09-13): `status.jsonl`, the
digest, the PIPELINE column. The snapshot collector and the screens that read
it are step 2b, `snapshot-collector-plan.md`, which depends on this step's
Launch helper only for the tmux-session naming it already shares.

## Approach

### A. Skills become invoker-agnostic

- **`/feature` splits into two entry points** in one skill file:
  - **Launch.** Arguments: a repo path (default: the repo the cwd is in, via
    `git rev-parse --show-toplevel`; must be a main checkout, `.git` a
    directory), the task description or plan path, flags, and an optional
    requester (a session name to report to). It pulls the default branch,
    runs `wt switch -c <type>/<slug>` from that checkout, builds the
    worktree's tmux session (see C), starts a claude in it, and types the
    Run invocation carrying the task, flags and requester. It reports the
    session name to the caller and is done.
  - **Run.** No location arguments. Executes the pipeline (step 1's
    orchestrator logic) in the worktree it is in, spawning implementer and
    reviewer subagents inside itself. Reports the digest and the PR URL to
    the requester by `SendMessage` when one was named, else to the terminal.
    Refuses if the cwd is not a linked worktree (`.git` is a file).
  - The hub-only precondition and every mention of "hub" are removed. The
    single-repo rule stays: Launch refuses a request that spans repos.
  - Step 1's text is PRESERVED, not hub prose: the gate (1b), the
    nothing-to-change and brief-contradiction stops in step 1, review by
    round with its reviewer bounds (step 3), the Lessons block, and the
    requester-side paragraphs (relay the digest verbatim; this session never
    edits the pipeline's branch or PR by hand). The requester-side paragraphs
    move to Launch; the rest stays in Run unchanged.
  - Launch TYPES the Run invocation as a string, so the task, flags and
    requester reach Run verbatim through code, not through a model's copy.
    The reviewer checks this explicitly: a Launch with three seat flags and
    `--go` must produce a Run line carrying exactly those.
  - Entry points are selected by a flag, not by a positional word: `--run`
    means Run, its absence means Launch. Launch refuses when `.git` at the
    toplevel is a file; Run refuses when it is a directory.
  - New flags: `--repo=<path>` (Launch target, default the cwd's repo),
    `--requester=<session>` (who Run reports to) and `--run`. Run is the
    orchestrator itself rather than a spawned seat, so `--orchestrator=`'s
    model becomes the task session's `claude --model` and its effort has no
    CLI knob; `--quick` runs its single implementer seat inside Run, which is
    already in the worktree, so no `isolation: "worktree"` is passed.
- **`/address-review`**: "find a checkout of the branch; otherwise create one
  with `wt switch <branch>` from the repo's main checkout" (resolved from
  the routing table or the branch's git common dir). No hub wording.
- **`/hq`**: dispatch calls Launch directly with the brief's fields mapped to
  Launch's arguments and REPORT set to this session's name. Step 3
  (find-or-spawn hub session, `-hub` peer naming) is removed. The dispatcher
  paragraph becomes: never implement in this session; creating a worktree
  and its session is dispatch mechanics and is allowed. Steering messages go
  to the task session by its sessionizer name (`session_name_for`).

### B. Rules and templates

- `dots/claude/rules/worktrees.md`: replace the first paragraph. The clone at
  `~/dev/<repo>` keeps the default branch checked out; exploratory and
  one-off work may happen there, but anything that becomes a branch or a PR
  moves to a sibling worktree at `~/dev/<repo>.<branch>`. Remove the hub
  session, `-hub` naming and "durable context keys to the launch dir"
  sentences. The anchoring section and the mechanism table stay unchanged.
- `dots/claude/rules/delegation.md`: receivers are task sessions or hq, not
  hubs; adjust nouns. The overlap rule ("never spawn a second agent on work
  already in flight") stays.
- `templates/hq/CLAUDE.md` and `templates/hq/routing.md`: drop the `hub`
  column and hub delegation prose; routing rows keep repo path, alerts,
  tracker, wiki pointer.
- `CLAUDE.md` (this repo): rewrite the "Worktrees: hub model" section and the
  `new_hub_session` mentions to describe the launch helper.

### C. tmux layer: launch helper

- New script `bin/tmux-task-session`, callable from an agent shell:

  ```
  tmux-task-session [--model <model>] <worktree-path> <prompt>
  ```

  It resolves the session name with `session_name_for <worktree-path>`, builds
  the session with the standard layout, and starts claude in the agent window
  with `<prompt>` as its first turn. It prints the session name on stdout.
  CREATION ONLY (tmux-safety rule): if the session already exists it prints the
  name and exits without touching it; it never kills, switches the client,
  sources a file or sets a hook.
- The prompt is written to `<worktree>/.feature/launch-prompt.md` and the typed
  line is `claude -n '<session>' "$(cat '<abs path>')"`, so a multi-line brief
  reaches Run byte-for-byte with no shell-quoting hazard, and the file is a
  durable record of what Run was asked (readable after any `/clear`). The
  helper creates `.feature/` and adds it to the repo's
  `$(git rev-parse --git-common-dir)/info/exclude` if missing.
- The layout is extracted from `new_hub_session` into one shared function in
  `bin/tmux-claude-lib` that takes the command to type into the agent window.
  `new_hub_session` becomes a thin caller of it with its signature, peer naming
  and behavior unchanged, so the sessionizer and `wt-tmux-jump` are untouched
  and the layout has one home.
- `new_hub_session` is kept for humans (sessionizer, `wt-tmux-jump`); the
  `CLAUDECODE` guards in `wt-tmux-jump` stay. The new helper is the only
  agent-callable path.
- The claude it starts must come up in an initialized shell (type the
  command, never pass it as the tmux session command) so `other/zshrc.local`
  env applies.
- Offline test `tests/test-task-session.sh`, added to `tests/run.sh`: the
  helper's pure pieces — the session name it derives for an agent worktree and
  a worktrunk sibling (must equal what `session_name_for` gives), and the
  command string it builds (single-quote escaping of the session name and the
  path, `--model` present only when asked). No tmux server. The real behavior
  is checked once by hand on `tmux -L task-session-test-$$`.

### E. Memory and lessons

- No per-repo auto-memory is expected to accrue (task sessions are
  ephemeral). Step 1's Lessons block is the harvest; this step adds nothing
  but removes the "hub accumulates durable context" claim from docs.

## Files to touch

- `dots/claude/skills/feature/SKILL.md`, `hq/SKILL.md`, `address-review/SKILL.md`
- `dots/claude/rules/worktrees.md`, `delegation.md`
- `templates/hq/CLAUDE.md`, `templates/hq/routing.md`
- `bin/tmux-task-session` (new) and `bin/tmux-claude-lib` (layout extracted);
  `bin/wt-tmux-jump` and `bin/tmux-sessionizer` stay untouched because
  `new_hub_session` keeps its signature
- `tests/test-task-session.sh` (new), `tests/run.sh`
- `CLAUDE.md`

## Ordered steps

1. Launch helper in the tmux layer, with an offline test for its naming and
   a manual test on a throwaway socket (`tmux -L`) — never the live server.
2. `/feature` Launch/Run split; `/address-review` wording; run one Launch
   from a repo session end to end (`--local`).
3. `/hq` dispatch via Launch; remove hub steps; run one dispatch from hq.
4. Rules and templates.
5. `CLAUDE.md`; `tests/run.sh`; `bin/doctor`.

## Test plan

- `tests/run.sh` green under both bashes (new parsers covered by fixtures).
- Helper: on `tmux -L test-$$`, builds a session named as `session_name_for`
  predicts, does not switch the client, types the given command.
- One full dispatch: hq → Launch → task session → digest arrives at hq →
  go → PR URL arrives at hq; hq `/clear` mid-run changes nothing; Ctrl+G
  lists the task session's claude and `bin/worktrees` shows its PIPELINE
  column; `wt remove` kills the session.

## Out of scope

- Parameterizing any repo's local stack to run from a worktree. Repo work.
- Replacing JSONL/TSV with a database.
- Any change to how subagents inside Run are spawned (seats are unchanged).

## Assumptions

- ASSUMED: `claude -n <name> '<prompt>'` starts an interactive session whose
  first turn is that prompt. This is what makes Launch's typed invocation
  atomic (no send-keys race against claude's startup). Verify on a throwaway
  `tmux -L` server before the skill text depends on it; if it is false, the
  fallback is a second `send-keys` after polling for claude's prompt.
- ASSUMED: `SendMessage` to a peer session by name works from a claude that
  was started by typing into a tmux window (same as the sessionizer path).
  Believed true since hq already messages sessions started that way. Verified
  only by a real Launch whose digest reaches the requester.
- ASSUMED: `/clear` in a session kills its background subagents. The design
  does not depend on it, but the "clear any session any time" claim does;
  confirm once on a throwaway run.
- JUDGMENT (literal instruction followed, not extended): this step removes the
  hub ROLE from prose. It does NOT rename `new_hub_session` or drop the
  `-hub` peer suffix it gives a main-checkout session — the plan keeps that
  function for the human paths and says nothing about its naming, and the
  suffix has no consumer left once `/hq`'s find-or-spawn-hub step is gone.
  Raised as the digest's Question rather than resolved here.
- JUDGMENT: `bin/worktrees`, `bin/prs`, `bin/wt-tmux-cleanup` and
  `dots/worktrunk.toml` use `hub` as shorthand for a repo's MAIN CHECKOUT (a
  directory, in local variable names and `--help` scope lines), not for the
  session role this step removes. Out of scope; left alone so the diff stays
  the plan's.
- VERIFIED: `wt switch -c` from an agent shell creates the worktree but no
  tmux session (`wt-tmux-jump` exits under `CLAUDECODE`, bin/wt-tmux-jump:22),
  so Launch must build the session itself.
- VERIFIED: `session_name_for` / `session_name_for_branch` produce the same
  name for a worktree whether created by `wt` or by the Agent tool
  (bin/project-dirs-lib:107), so a task session is addressable before and
  after the worktree exists.
- VERIFIED: `templates/hq/routing.md` has no `hub` column to drop — its row
  template is already repo path / alerts / tracker / wiki. The hub column
  exists only as `hq/SKILL.md`'s claim that "routing.md lists it as `hub`",
  which goes with that step.
- VERIFIED: a new `bin/` script needs no `bin/doctor` or `symlink_files.sh`
  entry — `~/dotfiles/bin` is on PATH wholesale (dots/zshrc:66) and scripts
  there are not symlinked individually.

## Status

- 2026-09-12: drafted, uncommitted. Gated on step 1 landing.
- 2026-09-13: step 1 merged; snapshot collector split out to `snapshot-collector-plan.md` (step 2b); A gains the preserve-step-1-text and typed-invocation lines.
- 2026-09-13: planned for implementation — restatement, digest, concrete helper design in C, entry-point flags in A, Assumptions extended.
