# Worktrees

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
