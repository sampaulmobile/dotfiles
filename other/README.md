# other/ — machine-local config

Everything machine-specific or private lives here, in one place, so it's easy
to see, back up, and migrate (e.g. `tar czf other.tgz other/` + AirDrop when
setting up a new machine). Only this README and the `*.example` templates are
tracked — the real files are gitignored and never leave the machine.

| File | Consumed by | Purpose |
|------|-------------|---------|
| `zshrc.local` | sourced at the end of `~/.zshrc` | env vars, extra PATH, anything shell |
| `gitconfig.local` | `[include]` in `~/.gitconfig` | per-machine git identity/overrides |
| `tmux-sessionizer.local` | sourced by `bin/tmux-sessionizer` | override `search_dirs` |
| `claude/skills/`, `claude/rules/` | symlinked into `~/.claude/` by `setup_other.sh` | machine-local Claude skills/rules |

To start: `cp <name>.example <name>` and edit (setup.sh does the copy for you
if the real file doesn't exist yet).
