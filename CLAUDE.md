# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, worktree helpers, etc.)
- `sources/` — zsh source files (aliases, history config, exports)
- `etc/` — Brewfiles: `Brewfile_mac` (base, all machines), `Brewfile_other` (supplemental, installed by `setup_other.sh`)
- `other/` — machine-local config, gitignored except `*.example` templates and README. Consumed via: zshrc sources `other/zshrc.local` last; gitconfig includes `other/gitconfig.local`; tmux-sessionizer sources `other/tmux-sessionizer.local` (can redefine `search_dirs`); `other/claude/` symlinked into `~/.claude/` by `bin/symlink_files.sh` (settings.json file link; skills/, rules/ dir links)
- `archive/` — old/unused configs kept for reference
- `notes/` — machine setup guides

## IMPORTANT: This repo is PUBLIC

Nothing sensitive or machine/employer-identifying may ever be committed — no
private filepaths, directory/service/project names, claude skills content, or
absolute paths beyond generic `$HOME` placeholders, in tracked files OR commit
messages. All of that belongs in the gitignored `other/` directory. Generic
public package names in Brewfiles are fine. Sweep diffs before pushing.

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
- `bin/tmux-claude-dashboard` — interactive dashboard showing all claude sessions with status (working/idle/permission/gone), token usage (context/output/total), and model. Responsive columns adapt to terminal width. Keys: `j/k` navigate, `⏎` switch to session, `x` kill session, `X` prune all gone sessions, `a` toggle agent trees, `r` refresh, `R` hard refresh (clears token cache), `q` quit. Sessions whose CWD no longer exists (e.g. deleted worktrees) show `✗ gone`. A session row expands into a tree of its live subagents (indented by spawn depth, parents before children), rendered on the same SESSION/STATUS/CONTEXT/OUTPUT/TOTAL/MODEL column grid as session rows (status shows working/idle with age, e.g. `working 30s`; MODEL shows the agentType); a working agent's activity snippet prints as its own dim quoted line beneath the row. A `+N` badge marks sessions with N agents actively working. Sessions with a working agent auto-expand; `a` forces every session's tree open (including idle-only agents) and toggles back.
- `bin/tmux-claude-statusbar` — prints permission-needed count for the tmux status bar. Shows `🔴 N` when N sessions need permission.
- `bin/tmux-claude-notify` — notification hook for Claude Code. Sends terminal bell + macOS notification on permission prompts. Configured in `~/.claude/settings.json`.
- `bin/tmux-claude-lib` — shared functions sourced by the claude session manager scripts.

## Worktrees: hub model (worktrunk)

Work repos are normal clones ("hubs") at `~/dev/<repo>` with the default
branch checked out. Branch work happens in disposable sibling worktrees
managed by [worktrunk](https://github.com/max-sixty/worktrunk) (`wt`,
installed via Brewfile):

```
~/dev/myproject/                # hub: normal clone, main checked out — you live here
~/dev/myproject.feat-x/         # worktree for branch feat/x (slashes sanitized)
```

- Daily flow: `Ctrl+F` to the hub → `git pull` → `wt switch -c <branch>` →
  the post-switch hook drops you into a tmux session for the worktree →
  `Ctrl+Space` for claude there. `wt remove <branch>` when done (hook kills
  the worktree's tmux + claude sessions and returns you to the hub).
- New branches base off LOCAL main — pull the hub first, same discipline as
  `git checkout -b`.
- `wt switch pr:123` makes a review worktree for a PR. Plain `wt switch`
  (no `-c`) is redundant with `Ctrl+F`.
- Secrets/machine-local files live in the hub checkout (gitignored).
  `wt step copy-ignored` copies them (plus caches like `.venv`,
  `node_modules`) into a worktree when it needs to be runnable — kept
  MANUAL, not a hook: ~13s / 3.2 GiB on the biggest repo.
- Glue: `dots/worktrunk.toml` (user-level hooks) + `bin/wt-tmux-jump` /
  `bin/wt-tmux-cleanup`; the zshrc `wt()` wrapper passes `--no-cd` on
  switch so the invoking pane never moves. Session naming (dir basename,
  dots→underscores) matches the sessionizer, so Ctrl+F/Ctrl+Space/Ctrl+G
  work on worktrees with no special handling.
- Claude memory/sessions key to the LAUNCH directory: hub sessions
  accumulate context durably; per-worktree claude sessions are ephemeral
  (put durable knowledge in the repo's CLAUDE.md, or CLAUDE.local.md at
  the hub). For work whose context should persist, run claude AT the hub
  and let it use its own worktree isolation.

The previous bare+worktree layout (`.bare/` containers) and its `gw*`
scripts are retired — kept in `archive/` for reference. The sessionizer
still recognizes `.bare/` containers (other machines may lag during the
transition).

## Conventions

- zshrc loads brew first, then auto-launches tmux. The outer shell skips everything after the tmux block (`&& return`). The inner shell (inside tmux) loads the full config.
- Platform-specific zshrc: `zshrc` for macOS, `zshrc_linux` for Linux.
- GHA runners run locally — never add `[safe] directory` to the global gitconfig. Set it in the runner's local `.git/config` instead.
- Fresh machine: `git clone` (triggers CLT install) → `./setup.sh` → optionally `./setup_other.sh`. Both end with manual-step checklists.
- Claude Code config is fully machine-local (public repo): settings.json/skills/rules live in `other/claude/`, seeded from `other/claude/settings.json.example`; machine differences (model, TLS) are env vars in `other/zshrc.local` (e.g. `ANTHROPIC_MODEL`). Never commit claude config.
- claude-code is installed via npm global — per-node-version under fnm, so reinstall after changing the default node.
