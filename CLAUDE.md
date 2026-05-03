# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, worktree helpers, etc.)
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
- `Ctrl+G` — claude session dashboard (status, tokens, model for all claude sessions)
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

- `bin/tmux-sessionizer` — fuzzy finds projects in `~/dev` (depth 1) and `~/dotfiles` (depth 0). For worktree-layout repos (those with `.bare/`), enumerates each worktree as a separate entry. Sessions named `<project>_<branch>` for worktrees, `<basename>` for regular repos (dots → underscores).
- `bin/tmux-claude-popup` — toggles a floating 80x80 popup with Claude Code. Creates `claude-<session>` sessions. Ctrl+Space inside popup closes it.
- `bin/tmux-claude-dashboard` — interactive dashboard showing all claude sessions with status (working/idle/permission), token usage (context/output/total), and model. j/k to navigate, r to refresh, q to quit. Responsive columns adapt to terminal width.
- `bin/tmux-claude-statusbar` — prints permission-needed count for the tmux status bar. Shows `🔴 N` when N sessions need permission.
- `bin/tmux-claude-notify` — notification hook for Claude Code. Sends terminal bell + macOS notification on permission prompts. Configured in `~/.claude/settings.json`.
- `bin/tmux-claude-lib` — shared functions sourced by the claude session manager scripts.

## Git Worktree Layout

Repos can use a bare+worktree layout for branch-per-directory workflows:

```
~/dev/myproject/
├── .bare/          # bare git database (shared across all worktrees)
├── main/           # worktree for main branch
└── feature-xyz/    # worktree for feature branch
```

- No `.git` pointer file at the parent — it's a plain container directory.
- Each worktree is a fully independent checkout; git commands work normally inside them.
- The sessionizer discovers worktrees automatically by detecting `.bare/` in project dirs.

### Worktree Scripts (`bin/`)

| Script | Usage | Purpose |
|--------|-------|---------|
| `gwclone` | `gwclone <url> [name]` | Bare clone into `~/dev/`, create initial worktree for default branch, drop into tmux session |
| `gwnew` | `gwnew <branch> [base]` | Create a new worktree (new branch, existing local branch, or remote-tracking branch) |
| `gwrm` | `gwrm <branch>` | Remove worktree, kill its tmux session, prompt to delete the branch |
| `gwls` | `gwls` | List worktrees for current project, `*` marks active tmux sessions |
| `gwconvert` | `gwconvert [path]` | Migrate an existing normal clone to bare+worktree layout (re-clones from origin, keeps `.gwbak` backup) |

### Worktree Conventions

- `~/dotfiles/bin` is on `PATH` (via `sources/exports`), so `gw*` commands are available everywhere.
- `git wt` is aliased to `git worktree` in gitconfig for raw worktree commands.
- Worktree scripts find the project root by walking up from cwd looking for `.bare/`.
- `gwconvert` only migrates branches that exist on origin — local-only branches, stashes, and untracked files stay in the `.gwbak` backup.

## Conventions

- zshrc loads brew first, then auto-launches tmux. The outer shell skips everything after the tmux block (`&& return`). The inner shell (inside tmux) loads the full config.
- Platform-specific zshrc: `zshrc` for macOS, `zshrc_linux` for Linux.
- GHA runners run locally — never add `[safe] directory` to the global gitconfig. Set it in the runner's local `.git/config` instead.
