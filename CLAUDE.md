# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, etc.)
- `sources/` — zsh source files (aliases, history config, exports)
- `archive/` — old/unused configs kept for reference
- `notes/` — machine setup guides

## Key Configs

| File | Symlinked to | Notes |
|------|-------------|-------|
| `dots/zshrc` | `~/.zshrc` | Auto-launches tmux after brew init |
| `dots/tmux.conf` | `~/.tmux.conf` | Prefix is default Ctrl+B |
| `dots/gitconfig` | `~/.gitconfig` | Keep clean — no safe.directory entries (use local git config on runners) |
| `dots/starship.toml` | `~/.config/starship.toml` | Prompt theme |
| `dots/ghostty` | `~/.config/ghostty` | Terminal config |
| `dots/nvim` | `~/.config/nvim` | LazyVim |

## Tmux Keybindings

- `Ctrl+F` — sessionizer (fuzzy find project, create/switch tmux session)
- `Ctrl+Space` — toggle floating Claude Code popup (per-project session)
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

- `bin/tmux-sessionizer` — fuzzy finds projects in `~/dev` (depth 1) and `~/dotfiles` (depth 0). Sessions named after directory basename (dots → underscores).
- `bin/tmux-claude-popup` — toggles a floating 80x80 popup with Claude Code. Creates `claude-<session>` sessions. Ctrl+Space inside popup closes it.

## Conventions

- zshrc loads brew first, then auto-launches tmux. The outer shell skips everything after the tmux block (`&& return`). The inner shell (inside tmux) loads the full config.
- Platform-specific zshrc: `zshrc` for macOS, `zshrc_linux` for Linux.
- GHA runners run locally — never add `[safe] directory` to the global gitconfig. Set it in the runner's local `.git/config` instead.
