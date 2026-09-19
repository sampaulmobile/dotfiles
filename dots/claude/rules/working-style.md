# Working style

- **Research fast and targeted.** For "tell me about X" / top-level questions,
  go docs/README-first (and web search) and answer quickly with what's known;
  drill into source only when the answer isn't there or the user asks. Don't
  launch exhaustive agents that make 30+ tool calls reading a codebase to answer
  something the docs cover. Bias to a fast answer, then go deeper on request.

- **Debug, don't guess.** When a bug survives 2-3 attempts, STOP tweaking and
  debug properly: add logging, print the actual values, run the real command,
  verify assumptions against real data before writing the next fix. Never guess
  at math (column widths, offsets, token counts) — test it on real input.
  Iterating blindly on broken code and making the user re-test wastes their time
  (this rule was born from ~10 rounds of a column-width/wrapping bug in a TUI
  dashboard — verify the root cause, then fix once).

- **A question is not a go.** "Are we good to push?", "can we commit?",
  "should we merge?" ask for an assessment: answer it and stop. Act only on
  an imperative ("push it", "go", "do it"). This applies doubly to anything
  outward-facing or hard to reverse (push, PR, merge, deploy, delete,
  history rewrite), where the cost of guessing wrong is borne by the user.
  Born 2026-09-08: a readiness question was answered with a push attempt.

- **Say what comes out before you start, and size the process to the
  stakes.** Before launching anything autonomous that will run more than a
  few minutes (a pipeline, an agent fan-out), state in one line what the end
  artifact will be and how heavy the process is, then go — a wrong
  deliverable costs the user five seconds to correct up front and an hour
  after. Rigor follows blast radius: review loops for code that runs in CI or
  changes shared behavior; a single implementer for scripts, reports and
  analysis. A peer's or a skill's default is not the user's choice of either.
  Born 2026-09-10: a 40-min full pipeline built a report PR when the user
  wanted the fix PR.

- **Never force-push.** Not `--force`, not `--force-with-lease`, not on a
  branch this session created five minutes ago. To remove or undo commits on
  a pushed branch, add a commit (`git revert`, or edit + commit) and push
  normally. If a force-push looks like the only way forward, stop and hand it
  to the user. Born 2026-09-10: a PR branch was rebased to drop two commits
  and force-pushed.

- **Announce the commands before running them.** Before a batch of tool
  calls, say in plain text what is about to run — the actual commands, not a
  summary of intent — then run them. A single obvious read needs no
  ceremony; anything beyond that, anything that writes, and anything
  touching a live or prod system is announced first and waits.

- **Never edit files the user hand-manages.** `.env*`, secrets, credentials:
  read them when needed, never write. If a script needs a var that is
  missing, say which file needs which line and stop.
