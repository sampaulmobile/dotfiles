# dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy
framework.

## Fresh machine setup

```sh
# 1. clone — macOS prompts to install the Xcode Command Line Tools on first git use
git clone https://github.com/sampaulmobile/dotfiles.git ~/dotfiles

# 2. base setup: macOS defaults, brew + Brewfile_mac, symlinks, zsh, tmux
cd ~/dotfiles && ./setup.sh

# 3. (some machines) supplemental packages + local claude config
./setup_other.sh
```

Both scripts end with a checklist of the remaining manual steps (logins,
editing local config, etc.).

## Layout

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, git worktree helpers)
- `sources/` — zsh source files (aliases, history config, exports)
- `etc/` — Brewfiles (`Brewfile_mac` base, `Brewfile_other` supplemental)
- `other/` — machine-local config, gitignored (see below)
- `archive/`, `notes/` — old configs and setup notes kept for reference

## Machine-local config: `other/`

Anything machine-specific or private lives in `other/` — one folder to see,
back up, or migrate (tar + AirDrop it when moving machines). Only the README
and `*.example` templates are tracked; the real files never leave the machine.

| File | Consumed by |
|------|-------------|
| `other/zshrc.local` | sourced last by `~/.zshrc` — env vars, PATH, anything |
| `other/gitconfig.local` | `[include]` from `~/.gitconfig` — git identity/overrides |
| `other/tmux-sessionizer.local` | `bin/tmux-sessionizer` — override project `search_dirs` |
| `other/claude/{skills,rules}/` | symlinked into `~/.claude/` by `setup_other.sh` |

To start from a template: `cp other/<name>.example other/<name>` (setup.sh
seeds these automatically).

Per-machine Claude Code model/env is set via env vars in `other/zshrc.local`
(e.g. `ANTHROPIC_MODEL`) — `~/.claude/settings.json` stays identical across
machines.
