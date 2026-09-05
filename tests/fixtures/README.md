# Classifier fixtures

Pane captures fed to `classify_pane_status` by `tests/test-classify.sh`. One
file per (agent, state) the attention layer has to tell apart. Keep them
realistic: they are the only place the UI strings the classifier depends on
are written down.

| Fixture | Agent | Expected status | Provenance |
|---------|-------|-----------------|------------|
| `claude-idle.txt` | claude | idle | hand-written from the strings the classifier matches (`❯` prompt) |
| `claude-working.txt` | claude | working | hand-written (`esc to interrupt`, `s · ↓ … tokens`, `⎿  Running…`) |
| `claude-permission.txt` | claude | permission | hand-written (Yes/No selector) |
| `claude-plan-permission.txt` | claude | permission | hand-written (plan-mode question, `Enter to select` on the last line — deliberately has no "No" option so it exercises that branch and not the Yes/No one) |
| `codex-idle.txt` | codex | idle | real `tmux capture-pane -p` from codex-cli 0.153.4 |
| `codex-working.txt` | codex | working | real capture, mid-turn |
| `codex-permission.txt` | codex | permission | real capture of the command-approval overlay |
| `codex-dir-trust.txt` | codex | permission | real capture of the first-run directory-trust prompt |
| `codex-hook-trust.txt` | codex | permission | real capture of the hook-trust prompt (shown after any `hooks.json` change) |

The codex captures were taken on a throwaway tmux socket in a scratch
directory and scrubbed: every real path was replaced with `~/dev/proj`.
Nothing here may carry a private path, host, or org name — this repo is
public.

To refresh one: run the agent in a throwaway tmux session
(`tmux -L fixture-grab new-session -d -x 180 -y 45 codex`), drive it into the
state you want, `tmux -L fixture-grab capture-pane -p -t 0 -S -30 > file`,
scrub the paths, then `tmux -L fixture-grab kill-server`. Never use the
default tmux server for this.
