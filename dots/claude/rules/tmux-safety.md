# tmux safety (live server = the user's entire workspace)

- NEVER run `tmux kill-server`, `kill-session`, `source-file`, `set-hook`, or
  any server/session-mutating tmux command against the default server. The
  default tmux server hosts every live Claude session on this machine —
  killing it destroys the user's whole working state (this happened; twice).
- Tests needing a tmux server MUST use a throwaway socket with the `-L <name>`
  flag VISIBLE IN THE COMMAND TEXT ITSELF (e.g. `tmux -L attn-test-$$ ...`).
  Socket selection via environment variables, wrapper functions, or scripts
  (python subprocess env, etc.) is FORBIDDEN — env indirection is exactly how
  the default server got killed.
- Read-only tmux commands (list-sessions, display -p, capture-pane) are fine.
- If a task seems to require touching the live server (reload config, kill a
  session), STOP and hand that step to the user.
