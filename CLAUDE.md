# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, worktree helpers). Two doctors live here and exit 1 when they flag something; `bin/doctor` is read-only, `bin/worktrees` is read-only except under its `sweep --apply` verb:
  - `bin/doctor` — install drift, for after a `git pull`: `.example` files with no live copy and a settings.json missing entries its example has since gained (`bin/seed_other.sh --check`, which ends with `bin/claude-settings-check`), links missing/wrong/blocked by a real file (`bin/symlink_files.sh --check`), Brewfile_mac formulae not installed (`brew bundle check`). Each line names the fixing script. Add a section by giving the owning script a `--check` mode, never by teaching the doctor its own copy of the expected state.
  - `bin/prs` — your PRs across every project `bin/project-dirs-lib` knows about (or the cwd's repo), one table per repo: OPEN rows carry ONE tag for what the PR waits on (`pr_tag` precedence: draft · merge-conflict · ci-red · changes-requested · approved · review-required · open) plus age, each row an OSC 8 link to its PR on a terminal (URL column when piped) and the tag in `bin/worktrees`' palette; then MERGED since `--since` (default today); a repo with neither, or archived, is not listed. Two GitHub search calls per run (open + merged, parallel), filtered locally to the repos in scope — never one call per repo; `--any-repo` drops the filter. Skips this repo in the cross-project scope. Read-only; the deterministic half of a status check, `bin/worktrees` being the other. A failed search fails the run with `gh`'s error.
  - `bin/worktrees` — every worktree of the repo the cwd is in (a worktree resolves to its hub), or of every project `bin/project-dirs-lib` knows about when run outside a repo or with `--all`; agent worktrees included, bucketed LIVE / DIRTY / PRUNABLE / MERGED / ABANDONED / IN-REVIEW / PARKED / SHIPPED? (first match wins), as one aligned table grouped act / surface / in-progress; `-v` adds the command that would act on each row. Liveness from `lsof -d cwd -Fpn`, never the worktree lock file; PR state from `gh`, with `--offline` degrading every row to `pr:unknown`. Exit 1 while anything is MERGED/ABANDONED/PRUNABLE; a repo with no linked worktree is never listed (absence = none), `--all` just widens scope to every project. `worktrees sweep` is the actor on the MERGED bucket — same program, same classification, so the two can never disagree on "merged". Dry-run unless `--apply`; even then it only removes a worktree bucketed MERGED that sits at the merged PR's head (or has nothing ahead of `origin/<branch>`, or is folded into local `main`), and only past a gitignored-data guard: a file must be a regenerable cache (the copy-ignored exclude list) or byte-identical to the hub's copy to count as safe — anything else SKIPs the worktree and lists what's at risk; `--force` overrides the skip. Exit 0 on a clean run, 2 on a removal failure under `--apply`; flags are in `--help`.
- `sources/` — zsh source files (aliases, history config, exports)
- `etc/` — Brewfiles: `Brewfile_mac` (base, all machines), `Brewfile_other` (supplemental, installed by `setup_other.sh`)
- `dots/claude/` — the generic, tracked Claude Code layer: `skills/`, `rules/`, `agents/`. Layered into `~/.claude/` by `bin/symlink_files.sh` as per-item links inside the `other/claude/` dirs, so tracked and private entries coexist. Promote a private item by moving it here and re-running the script.
- `dots/codex/` — the generic, tracked Codex layer: `hooks.json` (the tmux attention hooks) and `shared-skills` (which `dots/claude/skills/` entries are also linked into `~/.agents/skills`). Private codex config lives in `other/codex/`. See `notes/codex.md`.
- `tests/` — one offline suite per pure function in the agent layer (the pane-status classifiers, the per-session/per-window status folds, the hook payload schemas, the codex rollout reader, the agent-per-tty parse, the sessionizer's fzf `--expect` parse, the subagent snippet, the pipe-truncate guard, the settings-drift check, `bin/project-dirs-lib`'s enumeration/naming, `bin/worktrees`'s buckets and gitignored-data guard) plus fixtures. `tests/run.sh` runs everything under both `/bin/bash` (3.2) and the default bash. No tmux server is started or touched. `tests/check-prose-only.sh <base-ref>` is the tripwire for comment-only passes: it fails if a changed `bin/` or `tests/` file differs once full-line comments and blank lines are stripped.
- `templates/` — scaffolds copied to new locations by `bin/` scripts: `templates/hq/` → `bin/hq-init` (the `/hq` dispatcher repo, default `~/dev/hq`)
- `other/` — machine-local config, gitignored except `*.example` templates and README. Consumed via: zshrc sources `other/zshrc.local` last; gitconfig includes `other/gitconfig.local`; `bin/project-dirs-lib` sources `other/tmux-sessionizer.local` (can redefine `search_dirs`); `other/claude/` symlinked into `~/.claude/` by `bin/symlink_files.sh` (settings.json and repo-props.toml file links; `skills/`, `rules/`, `agents/` dir links — anything dropped into `~/.claude/{skills,rules,agents}` therefore lands here, private by default); `other/codex/` the same way for codex (config.toml, AGENTS.md, skills/); `other/tmux-agent-default` picks the default agent for new sessions
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
| `dots/gitconfig` | `~/.gitconfig` | Keep clean — no safe.directory entries (use local git config on runners) |
| `dots/starship.toml` | `~/.config/starship.toml` | Prompt theme |
| `dots/ghostty` | `~/.config/ghostty` | Terminal config |
| `dots/nvim` | `~/.config/nvim` | LazyVim |
| `dots/atuin.toml` | `~/.config/atuin/config.toml` | Shell history + Ctrl+R fuzzy search (sqlite, local-only, no sync) |

## Tmux Keybindings

- `Ctrl+F` — sessionizer (fuzzy find project, create/switch tmux session)
- `Ctrl+Space` — toggle the agent window per project: jump to/from the window named after the session's agent (`claude` or `codex`, its `@agent` option), creating it on first use (`bin/tmux-claude-window`)
- `prefix+C` — an extra agent window in the current session, at the caller pane's directory, via `bin/tmux-claude-window --extra`. Named `<agent>+` (e.g. `claude+`), not `<agent>`, so the C-Space by-name lookup never grabs it; the dashboard, statusbar and Ctrl+Y track agents by tty, so it appears in all of them anyway (with its own `session:N` dashboard row). Shadows tmux's default customize-mode binding.
- `Ctrl+G` — agent session dashboard (status, tokens, model for every claude and codex session)
- `Ctrl+Y` — jump to whatever needs attention: a permission prompt first, else the newest finished-but-unseen agent pane (landing on its window, not just its session), else a "nothing needs attention" message. Landing on a flagged pane clears its ✅ flag. Passed through untouched to vim/fzf when the current pane runs one (vim-tmux-navigator's own is-vim idiom), since `C-y` is vim's scroll-line-up; elsewhere it shadows readline's rare `yank`. Not `Ctrl+J` (vim-tmux-navigator's pane navigation) and not `Ctrl+O` (Claude Code's toggle-verbose-transcript key, which a root binding would steal in exactly the panes this layer serves).
- URLs open with **⌘⇧+hover+click** (Ghostty). Shift is required: tmux `mouse on` and Claude Code's TUI capture mouse reporting, so unshifted clicks never reach Ghostty's link handler. `prefix+u` (wfxr/tmux-fzf-url) fuzzy-picks one from the pane instead — also the fix for URLs that wrap inside tmux and so miss Ghostty's regex, since the plugin captures with `-J`; it lists claude's OSC 8 `file://` links too. `prefix+U` (`bin/tmux-url-latest`) skips the picker and opens the newest, filtered to http(s) so the ubiquitous file:// links cannot shadow the web URL just printed.
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

Each script's own header carries its mechanics; this list is what a session
needs to find them and to change them safely.

- `bin/tmux-sessionizer` — Ctrl+F's picker, over the shared `project_dirs` enumeration plus every live session. Rows, colors and keys: the script's header; candidate directories and session naming: `bin/project-dirs-lib`. INVARIANT: nothing is scanned at keypress time — rows stream straight into fzf and status colors come only from caches (the statusbar's `status.tsv`, ignored when stale, plus the attention `.done` flags); anything that forks per project dir breaks it.
- `bin/project-dirs-lib` — the one source of truth for "which directories are projects" and what their sessions are called; fork-free and sourceable. Owns `search_dirs` (the "path:depth" list — `~/dev` at depth 1, `~/dotfiles` at depth 0) and its `other/tmux-sessionizer.local` override; `project_dirs`, which also enumerates legacy `.bare/` containers' worktrees, agent worktrees (`<repo>/.claude/worktrees/agent-<id>`, made by the Agent tool and by `/feature`) and worktrunk siblings (`~/dev/proj.feat-x`, `~/dotfiles.feat-x`); and the naming rule in `session_name_for` / `worktree_branch` / `worktree_repo_out` — `<project>_<branch>` for a worktree with branch slashes sanitized to `-` to match worktrunk (so an agent worktree and a `wt switch -c` sibling for one branch share a session), `<basename>` otherwise, dots → underscores. Sourced by `bin/tmux-sessionizer`, `bin/worktrees`, `bin/wt-tmux-jump` and `bin/wt-tmux-cleanup`, so `wt remove` on an agent worktree kills the session Ctrl+F created for it. `session_name_for_branch <repo-name> <branch>` is the same rule with no filesystem read, used via `session_name_for_removed` by the post-remove/post-merge hooks, which run after the worktree directory (and its `.git` file) is gone. See `tests/test-project-dirs.sh`.
- `bin/tmux-claude-window` — the C-Space and prefix+C implementation: toggles between the session's agent window (found by the name of its `@agent`) and the last-used window, creating it at the current pane's path when missing; `--extra` opens a new `<agent>+` window there instead.
- `bin/tmux-claude-dashboard` — Ctrl+G's interactive dashboard for all claude and codex sessions. Columns, keys, formats and coloring thresholds: the script's header. Invariants a change must keep: one row per agent PANE, from `get_claude_panes` (whose 4th column names the row's agent), so an agent outside window 1 gets its own `session:N` row with its own transcript, tokens and subagent tree; transcripts resolve pane-exactly via the `tmux` field in `~/.claude/sessions/*.json` (`find_pane_jsonl`), so two claudes sharing a cwd cannot read each other's; sums come from `get_totals_incremental` (requestId-deduped); a cursor move repaints the cached frame (`build_frame` reruns only on a data change, a resize or a 30s-old cache), so nothing forks per keypress; the CONTEXT window comes from `context_window_for`'s per-model table for claude rows and from the rollout's own `model_context_window` for codex rows, which also show the plan's rate-limit usage (`5h:42%`) as COST and have no subagent tree. The estimate price table is duplicated from claude-tokens' JQ_PRELUDE: keep the two in sync. Agent snippets come from `get_agent_snippet` (`tail -c 131072`).
- `bin/tmux-claude-statusbar` — ambient attention layer in the status bar, refreshed every ~5s; the glyph legend is the script's header. The scan is `scan_agent_panes` in `bin/tmux-claude-lib` (per agent pane), folded per session by `aggregate_session_status` — `scan_claude_sessions`, shared with Ctrl+Y — and per window by `window_status_from_panes`. Each tick publishes both: `~/.cache/claude-attention/status.tsv` (`<session>\t<status>\t<pane>`, written atomically), which the sessionizer's row colors read instead of scanning, and the `@agent_status` window option (`permission|working|done|idle`, unset on windows without an agent), which `dots/tmux.conf` tints the window tab from. `tmux-claude-attention` flips the option itself on flag/clear/jump so a tab changes between ticks.
- `bin/tmux-claude-attention` — flag-file backend for the attention layer: `~/.cache/claude-attention/<session>@<pane>.done`, one per finished-but-unseen agent PANE. Subcommands, the hooks that drive them and the settings.json snippet: the script's header. INVARIANT: everything is per pane, never per session — a session-level flag both suppresses an agent finishing in a background window of an attached session and clears a window nobody looked at. The same dir holds the statusbar's `status.tsv` and `codex/<pane>.tsv`, the pane → rollout map codex's SessionStart hook writes (codex records no tmux pane of its own).
- `bin/tmux-claude-notify` — notification hook for both agents: terminal bell plus a macOS notification on permission prompts, titled after whichever agent asked. Reads Claude Code's Notification payload (`notification_type`) and codex's PermissionRequest payload (`hook_event_name`). Wired in `~/.claude/settings.json` for claude, `dots/codex/hooks.json` for codex.
- `bin/tmux-claude-lib` — shared functions for the agent session manager scripts: the agent helpers (`agent_default`, `agent_other`, `session_agent`, `agent_window_name`), `new_hub_session` (the standard hub layout — agent, nvim, zsh — used by the sessionizer and `wt-tmux-jump`), `agent_ttys` (the single `ps` behind every liveness check) and `scan_claude_sessions` (the status scan behind the statusbar and Ctrl+Y: one `list-panes -a`, then one batched capture of agent panes only). Sources `bin/tmux-claude-lib-codex` at the end.
- `bin/tmux-claude-lib-codex` — the codex half: `classify_codex_pane_status` (its own TUI strings — approval overlays, the two trust prompts, "esc to interrupt", the composer placeholder) and the rollout reader (`codex_find_pane_jsonl`, `codex_get_context_and_model`, `codex_get_totals`). Separate so the claude classifier, which the whole attention layer leans on, stays untouched.
- `bin/claude-tokens` — offline token/cost analyzer over the `~/.claude/projects` transcripts; claude only, no tmux, full-parses every file it reports on (seconds, not dashboard speed). Grains, flags, cost marks and the resume-chain collapsing: `--help` (the script's header). The transcript facts it and the dashboard both depend on — one assistant record per content block (dedupe per requestId) and a resume copying the whole history into a new file (`session_id` keeps the original id, `sessionId` is rewritten) — are documented at the code in `bin/tmux-claude-lib`'s `get_totals_incremental` and `claude-tokens`' `merge_chains`.

## Worktrees: hub model (worktrunk)

The generic worktrunk flow (`wt switch -c`, `wt step copy-ignored`, sibling
naming, run-inside-the-worktree discipline, hub-vs-worktree context) lives in
the global `dots/claude/rules/worktrees.md` rule — loaded into every session, so
it is NOT repeated here. This section is only the DOTFILES-specific glue.

```
~/dev/myproject/                # hub: normal clone, main checked out — you live here
~/dev/myproject.feat-x/         # worktree for branch feat/x (slashes sanitized)
```

- Daily entry: `Ctrl+F` to the hub → `wt switch -c <branch>` (post-switch hook
  drops you into the worktree's tmux session) → `Ctrl+Space` for claude there.
- Glue: `dots/worktrunk.toml` (user-level hooks) + `bin/wt-tmux-jump` /
  `bin/wt-tmux-cleanup`. `wt-tmux-jump` builds new worktree sessions with
  the same `new_hub_session` layout as the sessionizer (human shells only:
  it exits early under `CLAUDECODE`); the zshrc `wt()`
  wrapper passes `--no-cd` on switch so the invoking pane never moves.
  `wt-tmux-cleanup` kills the removed worktree's session. Session naming
  matches the sessionizer, so Ctrl+F/Ctrl+Space/Ctrl+G work on worktrees with
  no special handling.
- `wt step copy-ignored` cost on the biggest repo here: ~13s / 3.2 GiB — the
  reason it's kept manual rather than a switch hook.

The sessionizer still recognizes `.bare/` containers (other machines may lag
during the transition off that layout); its scripts are in `archive/`.

## Conventions

- **Confirm before commit, topic branch always.** Any agent session editing this repo (from here or from another repo's session) shows the diff and waits for a yes, then commits on a `<type>/<kebab-slug>` branch — never directly on master. Rules/skills/agents here load into every session's prompt, so each change needs a review point; the PUBLIC sweep above applies to the diff and the commit message.
- Branch names: `<type>/<kebab-slug>` with `type` ∈ `feat`, `fix`, `chore`, `docs` — the same prefixes as commit types. `/feature` reads this line when it renames its worktree branch; older branches predate it.
- zshrc loads brew first, then auto-launches tmux. The outer shell skips everything after the tmux block (`&& return`). The inner shell (inside tmux) loads the full config.
- Platform-specific zshrc: `zshrc` for macOS, `zshrc_linux` for Linux.
- GHA runners run locally — never add `[safe] directory` to the global gitconfig. Set it in the runner's local `.git/config` instead.
- Fresh machine: `git clone` (triggers CLT install) → `./setup.sh` → optionally `./setup_other.sh`. Both end with manual-step checklists. Existing machine after a pull: `bin/doctor`, then run whichever script it names (`bin/symlink_files.sh` for new tracked skills/rules/agents, `bin/seed_other.sh` for new `.example` files, `brew bundle` for Brewfile additions).
- Claude Code config is two-layered (public repo): the generic skills/rules/agents are tracked in `dots/claude/`; settings.json and private skills live in `other/claude/`; machine differences (model, TLS) are env vars in `other/zshrc.local` (e.g. `ANTHROPIC_MODEL`). settings.json is seeded ONCE from `other/claude/settings.json.example` and never auto-merged, because Claude Code writes to it itself — a default the example gains later is surfaced by `bin/claude-settings-check` / `bin/doctor` and applied by hand or by asking claude. `other/claude/repo-props.toml` (seeded from its own `.example`, schema documented there) is the same one-shot seed with no drift checker — it's a static per-repo properties file, not a growing settings file. Never commit settings.json, repo-props.toml, or anything else from `other/`.
- **Agents: claude + codex.** Both backends share the tmux layer. A session's agent is fixed at creation and pinned as the tmux session option `@agent`. The default is `claude`, overridable with a one-line `other/tmux-agent-default`; the sessionizer's `ctrl-x` / Option+Enter builds a session with the other one. The scripts keep their `tmux-claude-*` names: renaming them is a separate mechanical change, since the names are wired into tmux.conf, both agents' hook configs, private settings.json, the hq skill and these docs. Codex config is two-layered like claude's — tracked `dots/codex/` (hooks.json, shared-skills), private `other/codex/` (config.toml, AGENTS.md, skills/). Only harness-neutral skills are shared with codex (`dots/codex/shared-skills`, `pr` today); `feature`, `hq` and `address-review` need Claude Code's Agent tool, ListAgents and SendMessage. Rules are NOT shared: codex has no rules directory, and `~/.codex/AGENTS.md` is hand-written (seeded from `other/codex/AGENTS.md.example`). Setup, hook trust and the per-agent differences are in `notes/codex.md`.
- `/hq` needs an hq repo at `~/dev/hq` (routing table + coordinator CLAUDE.md); `bin/hq-init` scaffolds one from `templates/hq/`. The skill stops and says so when the routing table is missing.
- claude-code is installed via npm global — per-node-version under fnm, so reinstall after changing the default node.
