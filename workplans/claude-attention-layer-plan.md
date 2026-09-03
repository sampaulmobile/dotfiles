# Workplan: claude attention layer (statusbar v2 + Ctrl+J)

## Goal

Never discover a waiting/finished Claude session by flipping to it. Ambient,
always-visible state in the tmux status bar (`🔴N ✅N ●N`), an instant
jump-to-what-needs-me key (`Ctrl+J`), and event-driven "finished but unseen"
tracking via the Stop hook. Silent by design: only 🔴 (permission) keeps the
existing bell/notification; ✅ (done-unseen) is visual-only.

## Design

### State: flag files (new helper `bin/tmux-claude-attention`)

- Flag dir: `~/.cache/claude-attention/` (create on demand). One file per
  tmux session: `<tmux-session-name>.done`, touched to flag, removed to clear.
- Subcommands: `flag-done` (called by the Stop hook), `clear <session>`
  (called by the tmux attach hook), `list` (emits flagged sessions,
  newest-first), `jump` (used by Ctrl+J; see below).

### Stop hook (config change in ~/.claude/settings.json — machine-local, NOT
this repo; document the snippet in the script header and README comment)

- Claude Code fires `Stop` when a session finishes responding. Hook command:
  `~/dotfiles/bin/tmux-claude-attention flag-done`, async.
- The hook runs as a child of the claude process: derive the owning tmux
  session via `$TMUX_PANE` → `tmux display -pt "$TMUX_PANE" '#{session_name}'`.
  Not inside tmux (no TMUX_PANE) → exit 0 silently.
- Suppress self-flagging: if the owning session IS the currently attached
  client's session (`tmux display -p '#{client_session}'` for the active
  client), do nothing — you watched it finish. Multiple clients: suppress if
  ANY client is attached to that session.
- Also clear any stale flag when flagging (idempotent touch).

### Clear-on-attach (dots/tmux.conf)

- `set-hook -g client-session-changed 'run-shell "~/dotfiles/bin/tmux-claude-attention clear #{client_session}"'`
  (also fire on `client-attached`). Visiting a session consumes its ✅.

### Statusbar v2 (rewrite `bin/tmux-claude-statusbar`)

- Output format: `🔴N ✅N ●N ` — omit any zero-count segment entirely; output
  empty string when all zero (preserves current status-right behavior).
- 🔴 permission: keep the existing capture-pane heuristic BUT scan ALL
  sessions running claude, not just `claude-*`-prefixed ones — reuse/source
  `bin/tmux-claude-lib`'s `get_claude_sessions` + `get_session_status`
  instead of the hand-rolled loop (fixes headless hubs being invisible).
- ✅ done-unseen: count of flag files whose session still exists (prune flags
  for dead sessions as encountered).
- ● working: sessions whose status is "working" per the lib.
- Budget: called every 5s by tmux — must stay <200ms. The lib's
  status check is capture-pane based (cheap); no transcript parsing here.

### Ctrl+J (dots/tmux.conf + `jump` subcommand)

- `bind-key -n C-j run-shell "~/dotfiles/bin/tmux-claude-attention jump"`
- `jump` priority: first session needing permission (per lib status), else
  newest ✅ flag, else no-op with a brief tmux display-message "nothing needs
  attention". Switch via `tmux switch-client -t <session>` (which then
  auto-clears its flag via the attach hook).
- Note: C-j shadows readline's rarely-used accept-line duplicate (C-j =
  newline in shells). Acceptable; comment it like the C-t shadow.

## Files

- `bin/tmux-claude-attention` (new): flag-done / clear / list / jump.
- `bin/tmux-claude-statusbar` (rewrite): three-segment output, lib-based.
- `dots/tmux.conf`: attach hooks + C-j binding (comments consistent w/ C-t).
- `CLAUDE.md`: update statusbar + keybinding bullets.
- Do NOT edit any settings.json in this repo; the Stop-hook JSON snippet goes
  in a header comment of tmux-claude-attention for manual/machine-local setup.

## Ordered steps

1. `bin/tmux-claude-attention` with all four subcommands; smoke each by hand
   (fake flags, jump priority, self-flag suppression logic).
2. Statusbar rewrite on the lib; verify output format + timing (<200ms with
   ~7 live sessions).
3. tmux.conf hooks + binding; `tmux source-file` to smoke live.
4. Docs (CLAUDE.md bullets).
5. Report the exact settings.json Stop-hook snippet for the user to apply.

## Test plan

- flag-done outside tmux: silent no-op. Inside: flag appears unless session
  is the attached one.
- clear-on-attach: switch to a flagged session → flag gone within the hook.
- statusbar: fabricate each state (flag files, a session at a permission
  prompt, a working session) → segments appear/omit correctly; all-zero →
  empty output; headless (non `claude-*`) hub sessions are counted.
- jump: permission session beats done flag; empty state → display-message.
- No regression: existing 🔴-only behavior preserved when feature unused.

## Out of scope

- macOS notifications for ✅ (deliberately silent).
- Dashboard changes (Ctrl+G already shows detail; this is the ambient layer).
- Historical/analytics on attention events.

## Public-repo caution

Generic examples only; no employer/machine identifiers in comments or tests.
