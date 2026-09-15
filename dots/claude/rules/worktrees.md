# Worktrees

A project repo is a normal clone at `~/dev/<repo>` with the default branch checked
out. Exploratory and one-off work happens there, but anything that becomes a
branch or a PR moves to a disposable sibling worktree managed by worktrunk
(`wt`) with its own tmux session:

- Create: from the main checkout, `git pull` then `wt switch -c <branch>` — it
  lands the worktree as a `~/dev/<repo>.<branch>` sibling (slashes sanitized)
  and sets up its tmux session. Do NOT use raw `git worktree add`. New
  branches base off LOCAL main, so pull the main checkout first (same
  discipline as `git checkout -b`).
  From an agent's shell (Claude Code sets `CLAUDECODE`) the post-switch hook
  is a no-op: the worktree appears, but no tmux session is built, no claude
  auto-starts and the user's screen never switches — Ctrl+F lists the
  worktree and builds its session on first visit. So agents may use
  `wt switch` freely; the hook's tmux side is for humans at the keyboard.
- `wt switch pr:123` makes a review worktree for a PR. `wt remove <branch>`
  tears the worktree down (and its tmux/claude) when done.
- Runnable by default for ENV: a `pre-start` hook (`dots/worktrunk.toml`)
  auto-runs `wt step copy-ignored` on worktree creation, copying gitignored
  ENV/secrets/config from the main checkout but EXCLUDING the fat regenerable
  caches (`.venv`, `node_modules`, build dirs — see
  `[step.copy-ignored] exclude`). So
  a new worktree runs `bin/` scripts and anything needing `.env*` immediately,
  from inside the worktree. Regenerate the excluded caches on demand there
  (`uv sync` / `npm i` / `flutter pub get`) — fast (warm package caches) and
  correct for the branch's lockfile; a copied `.venv` isn't relocatable anyway.
  Run a full `wt step copy-ignored` manually only if you deliberately want the
  heavy caches cloned into a worktree.
- Every claude session is ephemeral and may be cleared at any time, so durable
  knowledge goes in files: the repo's CLAUDE.md for what the repo needs to be
  worked on, a worktree's `.feature/` for a pipeline run's own state.

## Operating on a worktree from a session homed elsewhere

- When running shell commands against a git worktree from a session homed
  elsewhere (e.g. a session at a repo's main checkout touching
  `.claude/worktrees/...`), ALWAYS anchor
  the command: `git -C <worktree-path> ...`, absolute file paths, or
  `cd <worktree> && ...` within the same compound command. Never rely on the
  shell's cwd persisting across turns — it silently resets to the session's
  home dir (on resume, and at other times).
- Wrong-tree commands usually SUCCEED silently (main checkout and worktree
  share the repo, and most files exist in both). Treat these as wrong-tree
  symptoms and check `pwd` + `git -C . log --oneline -1` first: unexpected
  test-collection counts, HEAD at the default branch when you expected a
  feature branch, diffs that look already-applied or missing.
- Which mechanism when an agent needs a worktree:
  - NEW work from a clean base, done by a subagent: spawn it with
    `isolation: "worktree"`. The harness makes `.claude/worktrees/agent-<id>`
    on a fresh branch (base governed by the `worktree.baseRef` setting) and
    BLOCKS cross-tree writes.
    It never reuses an existing worktree or branch, and the tree carries no
    gitignored runtime files (`wt step copy-ignored` when a step needs them).
  - An EXISTING branch or PR (review fixes), or seats that must share one
    tree (implementer + reviewer + fixer): work in that tree. If no worktree
    holds the branch, `wt switch <branch>` / `wt switch pr:N` from the main
    checkout makes the sibling. No write fence here, so the anchoring
    discipline above is the guardrail — keep such a session's own freelancing
    in worktree paths to small, carefully-anchored operations.
