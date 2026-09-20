# Deletion safety (agents never delete outside the tree they work in)

- Never add a command that deletes files or directories outside the git
  worktree it runs in — no `rm -r` / `rm -rf` on state dirs, caches, archives
  or anything under `$HOME` — to a script, skill, hook or test. Design the
  step to append or rename instead: a fresh timestamped directory per run, a
  `.partial` copy that is `mv`ed into place when complete. When a deletion is
  genuinely wanted, print the exact command and hand it to the user.
- Reviewers and implementers never execute a deletion as a probe or a test,
  however the target is redirected (a scratch `HOME`, a temp prefix, an env
  var). Prove containment by reading the code and by printing the path the
  command WOULD act on. A deletion that cannot be proven safe by reading is
  redesigned, not tested.
- Fine: `git worktree remove` / `wt remove` on a worktree (git's own guards
  apply), `git clean` inside the worktree, build outputs inside the worktree,
  and a test suite removing the one scratch directory it created itself under
  `mktemp -d` or the session scratchpad.
