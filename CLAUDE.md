# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, the worktrunk tmux glue, the attention flag hook, `bin/runners`). `bin/doctor` is the read-only install check and exits 1 when it flags something:
  - `bin/doctor` — install drift, for after a `git pull`: `.example` files with no live copy and a settings.json missing entries its example has since gained (`bin/seed_other.sh --check`, which ends with `bin/claude-settings-check`, read-only and naming `bin/claude-settings-check --apply` as the fix), links missing/wrong/blocked by a real file (`bin/symlink_files.sh --check`), deck missing from PATH, its config not a symlink or `deck status` not fresh, Brewfile_mac formulae not installed (`brew bundle check`). Each line names the fixing script. Add a section by giving the owning script a `--check` mode, never by teaching the doctor its own copy of the expected state.
- `bin/runners` — self-hosted GitHub Actions runners, per repo, as interchangeable numbered copies under `~/dev/gha-runners/<repo>/<n>/` (`runners_root` in `bin/project-dirs-lib`, which keeps that dir out of Ctrl+F): `status` (default), `start [N]`, `stop [N]`, the cwd's repo or an fzf pick. Each runs the runner's own `run.sh` detached, never launchd, so a reboot leaves them stopped. Liveness and stop order are in its header, removal in `--help` (it deletes nothing). See `tests/test-runners.sh`.
- `sources/` — zsh source files (aliases, history config, exports)
- `etc/` — Brewfiles: `Brewfile_mac` (base, all machines), `Brewfile_other` (supplemental, installed by `setup_other.sh`)
- `dots/claude/` — the generic, tracked Claude Code layer: `skills/`, `rules/`, `agents/`. Layered into `~/.claude/` by `bin/symlink_files.sh` as per-item links inside the `other/claude/` dirs, so tracked and private entries coexist. Promote a private item by moving it here and re-running the script.
- `dots/codex/` — the generic, tracked Codex layer: `hooks.json` (the Stop hook that writes deck's done flag) and `shared-skills` (which `dots/claude/skills/` entries are also linked into `~/.agents/skills`). Private codex config lives in `other/codex/`. See `notes/codex.md`.
- `tests/` — one offline suite per pure function left in `bin/` (the pipe-truncate guard, the docker-deletion guard, the settings-drift check, `bin/project-dirs-lib`'s enumeration/naming, `bin/runners`) plus fixtures. `tests/run.sh` runs everything under both `/bin/bash` (3.2) and the default bash — on a machine with no Homebrew bash the two are the same binary, so it says so and runs one pass: a bash-4-ism in `bin/` is caught there, a 3.2-only regression is not. No tmux server is started or touched. `tests/check-prose-only.sh <base-ref>` is the tripwire for comment-only passes: it fails if a changed `bin/` or `tests/` file differs once full-line comments and blank lines are stripped.
- `templates/` — scaffolds copied to new locations by `bin/` scripts: `templates/hq/` → `bin/hq-init` (the `/hq` dispatcher repo, default `~/dev/hq`)
- `other/` — machine-local config, gitignored except `*.example` templates and README, and its own PRIVATE git repo nested here (synced across machines by `other/bin/sync`, a launchd job every 5 min; `bin/doctor` runs its `--check`; details in `other/README.md`). Consumed via: zshrc sources `other/zshrc.local` last; gitconfig includes `other/gitconfig.local`; `bin/project-dirs-lib` sources `other/tmux-sessionizer.local` (can redefine `search_dirs`); `other/claude/` symlinked into `~/.claude/` by `bin/symlink_files.sh` (settings.json and repo-props.toml file links; `skills/`, `rules/`, `agents/` dir links — anything dropped into `~/.claude/{skills,rules,agents}` therefore lands here, private by default); `other/codex/` the same way for codex (config.toml, AGENTS.md, skills/); `other/tmux-agent-default` is read by nothing today (deck pick and deck launch build every session as claude, with `@agent claude`)
- `archive/` — old/unused configs kept for reference
- `notes/` — machine setup guides

## IMPORTANT: This repo is PUBLIC

Nothing sensitive or machine/employer-identifying may ever be committed — no
private filepaths, directory/service/project names, or absolute paths beyond
generic `$HOME` placeholders, in tracked files OR commit messages. All of that
belongs in the gitignored `other/`, including anything private under
`other/claude/`; tracked `dots/claude/` text gets the same sweep as any other
tracked file. Generic public package names in Brewfiles are fine. Sweep diffs
before pushing.

## Key Configs

| File | Symlinked to | Notes |
|------|-------------|-------|
| `dots/zshrc` | `~/.zshrc` | Auto-launches tmux after brew init |
| `dots/tmux.conf` | `~/.tmux.conf` | Prefix is default Ctrl+B |
| `dots/gitconfig` | included by `~/.gitconfig` | `~/.gitconfig` is a real file whose only content is an include of this one, so `git config --global` writes land there and never in the repo |
| `dots/starship.toml` | `~/.config/starship.toml` | Prompt theme |
| `dots/ghostty` | `~/.config/ghostty` | Terminal config |
| `dots/nvim` | `~/.config/nvim` | LazyVim |
| `dots/atuin.toml` | `~/.config/atuin/config.toml` | Shell history + Ctrl+R fuzzy search (sqlite, local-only, no sync) |

## Tmux Keybindings

- `Ctrl+F` — `deck pick` in a new window (fuzzy find project, create/switch tmux session; also bound in copy-mode-vi)
- `Ctrl+G` — `deck open agents` (deck's Agents screen in its home session)
- `Ctrl+E` — `deck open feed` (deck's Feed screen in its home session). Passed through untouched to vim/fzf when the current pane runs one (vim-tmux-navigator's own is-vim idiom), since `C-e` is vim's scroll-line-down.
- URLs open with **⌘⇧+hover+click** (Ghostty). Shift is required: tmux `mouse on` and Claude Code's TUI capture mouse reporting, so unshifted clicks never reach Ghostty's link handler. `prefix+u` (wfxr/tmux-fzf-url) fuzzy-picks one from the pane instead — also the fix for URLs that wrap inside tmux and so miss Ghostty's regex, since the plugin captures with `-J`; it lists claude's OSC 8 `file://` links too. `prefix+U` (`bin/tmux-url-latest`) skips the picker and opens the newest, filtered to http(s) so the ubiquitous file:// links cannot shadow the web URL just printed.
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

Each script's own header carries its mechanics; this list is what a session
needs to find them and to change them safely.

- `bin/project-dirs-lib` — the bash side's answer to "which directories are projects" and what their sessions are called (deck keeps its own `search_dirs` in its config and the same naming rule); fork-free and sourceable. Owns `search_dirs` (the "path:depth" list — `~/dev` at depth 1, `~/dotfiles` at depth 0) and its `other/tmux-sessionizer.local` override; `project_dirs`, which also enumerates legacy `.bare/` containers' worktrees, agent worktrees (`<repo>/.claude/worktrees/agent-<id>`, made by the Agent tool and by `/feature`) and worktrunk siblings (`~/dev/proj.feat-x`, `~/dotfiles.feat-x`); and the naming rule in `session_name_for` / `worktree_branch` / `worktree_repo_out` — `<project>_<branch>` for a worktree with branch slashes sanitized to `-` to match worktrunk (so an agent worktree and a `wt switch -c` sibling for one branch share a session), `<basename>` otherwise, dots → underscores. Sourced by `bin/runners` and `bin/wt-tmux-cleanup`, so `wt remove` on an agent worktree kills the session Ctrl+F created for it. `session_name_for_branch <repo-name> <branch>` is the same rule with no filesystem read, used via `session_name_for_removed` by the post-remove/post-merge hooks, which run after the worktree directory (and its `.git` file) is gone. See `tests/test-project-dirs.sh`.
- `bin/tmux-claude-attention` — the done-flag hook: `~/.cache/claude-attention/<session>@<pane>.done`, one per finished-but-unseen agent PANE, written by both agents' Stop hooks (`flag-done`), removed by the tmux hooks in `dots/tmux.conf` when the pane's window is on an attached client's screen (`clear`), and read by deck's Feed and picker as "finished, not yet visited" (its `attention_dir`). `jump-to <client-tty> <session> <pane>` is what deck's Feed `g` runs (its `attention_cmd`): switch the named client, land on the pane, drop its flag. INVARIANT: everything is per pane, never per session — a session-level flag both suppresses an agent finishing in a background window of an attached session and clears a window nobody looked at. No tmux subcommand here beyond `display`, `list-clients`, `list-panes`, `switch-client -c`, `select-window` and `select-pane`.

## deck

deck is a separate tool, installed with `uv tool install -e <deck checkout>`
into `~/.local/bin`. It owns the Feed, Agents and Board screens, the picker
(`deck pick`), the task launcher (`deck launch`), the reaper (`deck reap`)
and token stats (`deck stats`). tmux keys, the `wt` post-switch hook and
`/feature` call it by bare name off PATH; `bin/doctor` checks it. The only
bash left under it is `bin/tmux-claude-attention`, the done-flag file deck
reads. Nothing in this repo runs `deck daemon` or `deck reap`. Not in deck
yet: status bar glyphs and tab tint, a permission bell or notification, a
jump-to-attention key, an agent-window toggle, a codex adapter. deck's own
CLAUDE.md and `docs/design.md` are its reference.

## Worktrees and task sessions (worktrunk)

The generic worktrunk flow (`wt switch -c`, `wt step copy-ignored`, sibling
naming, run-inside-the-worktree discipline) lives in the global
`dots/claude/rules/worktrees.md` rule — loaded into every session, so it is NOT
repeated here. This section is only the DOTFILES-specific glue.

```
~/dev/myproject/                # main checkout, default branch
~/dev/myproject.feat-x/         # worktree for branch feat/x (slashes sanitized)
```

- Daily entry: `Ctrl+F` to the repo → `wt switch -c <branch>` (post-switch hook
  drops you into the worktree's tmux session, with claude in its agent window).
- Every branch gets its own worktree AND its own tmux session; no session
  outlives the branch it was made for, and none is a privileged home for a
  repo. A `/feature` run is one such session, built by `deck launch`
  instead of a keypress.
- Glue: `dots/worktrunk.toml` (user-level hooks) + `bin/wt-tmux-jump` /
  `bin/wt-tmux-cleanup`. `wt-tmux-jump` hands the worktree to `deck pick
  <path>`, which builds or wakes its session (human shells only:
  it exits early under `CLAUDECODE`); the zshrc `wt()`
  wrapper passes `--no-cd` on switch so the invoking pane never moves.
  `wt-tmux-cleanup` kills the removed worktree's session. Session naming
  matches `bin/project-dirs-lib`, so Ctrl+F/Ctrl+E/Ctrl+G work on worktrees with
  no special handling.
- `wt step copy-ignored` runs manually, not as a switch hook; cost on the
  biggest repo here: ~13s / 3.2 GiB.

`bin/project-dirs-lib` and deck still recognize `.bare/` containers (other
machines may lag during the transition off that layout); the old scripts are in `archive/`.

## Conventions

- **Confirm before commit, topic branch always.** Any agent session editing this repo (from here or from another repo's session) shows the diff and waits for a yes, then commits on a `<type>/<kebab-slug>` branch — never directly on master. Rules/skills/agents here load into every session's prompt, so each change needs a review point; the PUBLIC sweep above applies to the diff and the commit message.
- Branch names: `<type>/<kebab-slug>` with `type` ∈ `feat`, `fix`, `chore`, `docs` — the same prefixes as commit types. `/feature` Launch reads this line when it names its worktree branch; older branches predate it.
- zshrc loads brew and puts `~/.local/bin` (deck) and `dotfiles/bin` on PATH first, then auto-launches tmux, so the server and every binding find both by bare name; a running server keeps the PATH it started with. The outer shell skips everything after the tmux block (`&& return`). The inner shell (inside tmux) loads the full config.
- Platform-specific zshrc: `zshrc` for macOS, `zshrc_linux` for Linux.
- GHA runners run locally, and `actions/checkout` runs `git config --global --add safe.directory <path>` on every job. Those writes land in `~/.gitconfig`, a real file that only includes `dots/gitconfig` — so a runner's `$HOME` paths and the private repo's name cannot reach this PUBLIC repo. Never make `~/.gitconfig` a symlink to the tracked file again; `bin/symlink_files.sh --check` (and so `bin/doctor`) fails if it is.
- Fresh machine: `git clone` (triggers CLT install) → `./setup.sh` → optionally `./setup_other.sh`. Both end with manual-step checklists. Existing machine after a pull: `bin/doctor`, then run whichever script it names (`bin/symlink_files.sh` for new tracked skills/rules/agents, `bin/seed_other.sh` for new `.example` files, `brew bundle` for Brewfile additions).
- Claude Code config is two-layered (public repo): the generic skills/rules/agents are tracked in `dots/claude/`; settings.json and private skills live in `other/claude/`; machine differences (model, TLS) are env vars in `other/zshrc.local` (e.g. `ANTHROPIC_MODEL`). settings.json is seeded ONCE from `other/claude/settings.json.example` and never auto-merged, because Claude Code writes to it itself — a default the example gains later is reported by `bin/claude-settings-check` / `bin/doctor` and added by `bin/claude-settings-check --apply`, which `bin/seed_other.sh` (so `bin/symlink_files.sh`) runs. `other/claude/repo-props.toml` (seeded from its own `.example`, schema documented there) is the same one-shot seed with no drift checker — it's a static per-repo properties file, not a growing settings file. Never commit settings.json, repo-props.toml, or anything else from `other/`.
- **Agents: claude + codex.** Both backends share the tmux layer and the done-flag hook. A session's agent is fixed at creation and pinned as the tmux session option `@agent`. deck pick and deck launch build every session as claude and set `@agent claude`. Nothing reads `@agent` today; `bin/tmux-claude-attention` keeps its name, wired into tmux.conf, both agents' hook configs and private settings.json. Codex config is two-layered like claude's — tracked `dots/codex/` (hooks.json, shared-skills), private `other/codex/` (config.toml, AGENTS.md, skills/). Only harness-neutral skills are shared with codex (`dots/codex/shared-skills`, `pr` today); `feature`, `hq` and `address-review` need Claude Code's Agent tool, ListAgents and SendMessage. Rules are NOT shared: codex has no rules directory, and `~/.codex/AGENTS.md` is hand-written (seeded from `other/codex/AGENTS.md.example`). Setup, hook trust and the per-agent differences are in `notes/codex.md`.
- `/hq` needs an hq repo at `~/dev/hq` (routing table + coordinator CLAUDE.md); `bin/hq-init` scaffolds one from `templates/hq/`. The skill stops and says so when the routing table is missing.
- claude-code is installed via npm global — per-node-version under fnm, so reinstall after changing the default node.
