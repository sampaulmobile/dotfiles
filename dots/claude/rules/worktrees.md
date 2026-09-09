# Worktrees

Work repos are "hubs" — normal clones at `~/dev/<repo>` with the default branch
checked out; you live there and its claude session accumulates durable context.
The hub's claude is launched as `claude -n <repo-dir-basename>-hub` (tmux-claude-lib
does this), so its cross-session peer name is deterministic; worktree sessions are
named after their tmux session, and extra claude windows in the same repo are
auto-named `<basename>-NN` — neither is a hub.
Branch work happens in disposable sibling worktrees managed by worktrunk (`wt`):

- Create: from the hub, `git pull` then `wt switch -c <branch>` — it lands the
  worktree as a `~/dev/<repo>.<branch>` sibling (slashes sanitized) and sets up
  its tmux session. Do NOT use raw `git worktree add`. New branches base off
  LOCAL main, so pull the hub first (same discipline as `git checkout -b`).
- `wt switch pr:123` makes a review worktree for a PR. `wt remove <branch>`
  tears the worktree down (and its tmux/claude) when done.
- Runnable by default for ENV: a `pre-start` hook (`dots/worktrunk.toml`)
  auto-runs `wt step copy-ignored` on worktree creation, copying gitignored
  ENV/secrets/config from the hub but EXCLUDING the fat regenerable caches
  (`.venv`, `node_modules`, build dirs — see `[step.copy-ignored] exclude`). So
  a new worktree runs `bin/` scripts and anything needing `.env*` immediately,
  from inside the worktree. Regenerate the excluded caches on demand there
  (`uv sync` / `npm i` / `flutter pub get`) — fast (warm package caches) and
  correct for the branch's lockfile; a copied `.venv` isn't relocatable anyway.
  Run a full `wt step copy-ignored` manually only if you deliberately want the
  heavy caches cloned into a worktree.
- Durable context keys to the launch dir: hub claude sessions persist, per-
  worktree ones are ephemeral. Put durable knowledge in the repo's CLAUDE.md;
  for work whose context must persist, run claude AT the hub and let it use its
  own worktree isolation.

## Operating on a worktree from a session homed elsewhere

- When running shell commands against a git worktree from a session homed
  elsewhere (e.g. a repo hub touching `.claude/worktrees/...`), ALWAYS anchor
  the command: `git -C <worktree-path> ...`, absolute file paths, or
  `cd <worktree> && ...` within the same compound command. Never rely on the
  shell's cwd persisting across turns — it silently resets to the session's
  home dir (on resume, and at other times).
- Wrong-tree commands usually SUCCEED silently (main checkout and worktree
  share the repo, and most files exist in both). Treat these as wrong-tree
  symptoms and check `pwd` + `git -C . log --oneline -1` first: unexpected
  test-collection counts, HEAD at the default branch when you expected a
  feature branch, diffs that look already-applied or missing.
- Prefer real isolation for worktree labor: an agent spawned with
  `isolation: "worktree"` (or EnterWorktree) gets enforcement that BLOCKS
  cross-tree writes. A hub session freelancing in worktree paths has no such
  guardrail — keep that mode for small, carefully-anchored operations only.
