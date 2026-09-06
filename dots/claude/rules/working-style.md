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
