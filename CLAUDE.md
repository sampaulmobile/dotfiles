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
- `Ctrl+Space` — toggle claude per project: floating popup session OR a `claude` window inside the project session, per `other/tmux-claude-mode` (switch live with `bin/tmux-claude-migrate {window|popup}`)
- `prefix+C` — extra claude window in the current session: new window at the caller pane's directory (repo dir in a hub/worktree session, wherever you've cd'd otherwise) running claude via a shell. Named `claude+`, not `claude`, so the C-Space window/migrate by-name lookups never grab it; dashboard/statusbar/Ctrl+Y track claudes by tty, so extra windows show up in all of them automatically (the dashboard gives each its own `session:N` row). Shadows tmux's default customize-mode binding.
- `Ctrl+G` — claude session dashboard (status, tokens, model for all claude sessions)
- `Ctrl+Y` — jump to whatever needs attention: a session waiting on a permission prompt first, else the newest finished-but-unseen claude pane (landing on its window, not just its session), else a "nothing needs attention" message. Landing on a flagged pane clears its ✅ flag. Passed through untouched to vim/fzf when the current pane is running one (same is-vim detection idiom as vim-tmux-navigator's own C-h/j/k/l bindings), since `C-y` is vim's scroll-line-up — everywhere else it shadows readline's rare `yank`. (Not `Ctrl+J` — vim-tmux-navigator's pane navigation; not `Ctrl+O` — Claude Code's toggle-verbose-transcript key, which a root binding stole in exactly the panes this layer serves.)
- URLs open with **⌘⇧+hover+click** (Ghostty) — shift is required because tmux `mouse on` (and Claude Code's TUI) capture mouse reporting, so unshifted clicks never reach Ghostty's link handler. Keyboard alternative: `prefix+u` (wfxr/tmux-fzf-url) fuzzy-picks a URL from the pane and opens it in the browser — also the fix for URLs that wrap/truncate inside tmux and so don't match Ghostty's regex (the plugin captures with `-J`, joining wrapped lines); it lists claude's OSC 8 `file://` tool-use links too. `prefix+U` (`bin/tmux-url-latest`) skips the picker and opens the newest URL directly — same extraction, filtered to http(s) so the ubiquitous file:// links don't shadow the web URL just printed.
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

- `bin/tmux-sessionizer` — fuzzy finds projects in `~/dev` (depth 1) and `~/dotfiles` (depth 0). For worktree-layout repos (those with `.bare/`), enumerates each worktree as a separate entry. Sessions named `<project>_<branch>` for worktrees, `<basename>` for regular repos (dots → underscores). Scans NOTHING at keypress time: rows stream straight into fzf, and status colors come from caches (the statusbar's `status.tsv`, ignored when stale, plus the attention `.done` flags) — red = permission prompt waiting, green = finished-but-unseen, blue = working, dim blue = idle claude; dirs without a session render dim with `~`-shortened paths (cyan tint = linked worktree, i.e. `.git` is a file). `ctrl-/` inside fzf toggles a lazy preview (live pane snapshot for sessions; git status/log for dirs). No popup (`claude-*`) special-casing — popups are retired. New sessions get the standard hub layout via `new_hub_session` in `bin/tmux-claude-lib`: window mode = claude (warm) / nvim / zsh, landing on claude; popup mode = nvim / zsh, landing on zsh. The nvim window launches nvim in the project dir and keeps automatic-rename (shows "nvim" while it runs, tracks later commands); only the claude window's name is pinned.
- `bin/tmux-claude-popup` / `bin/tmux-claude-window` — the two C-Space implementations (floating `claude-<session>` popup vs a `claude` window in the project session); `bin/tmux-claude-migrate` moves live sessions between the layouts and sets the mode file. Popup-only logic elsewhere keys off `claude-*` sessions existing, so it self-disables in window mode.
- `bin/tmux-claude-dashboard` — interactive dashboard showing all claude sessions with status (working/idle/permission/gone), token usage (context/output/total), and model. One row per claude PANE, not per tmux session (`get_claude_panes` in tmux-claude-lib): a second claude outside window 1 gets its own row named `session:N` (N = window index) with its own transcript, tokens, and subagent tree — per-session rows pinned to window 1's transcript made such a claude (and its agents) invisible. Columns (SESSION, STATUS, MODEL, CONTEXT, CTX%, TURNS, OUTPUT, TOTAL, COST) fill the terminal width — CONTEXT is a used/total fraction of the model's window (`162.7k/1M`; per-model table in the script, `context_window_for`: 1M for the current Fable/Opus/Sonnet lineup, 200K Haiku/older, bare number when unknown) and CTX% the same as a percent, which drives the context coloring (yellow ≥50%, red ≥70%, bold red ≥90%; unknown models fall back to absolute thresholds). TURNS = user prompts handled (not API requests). COST: `$1.23` = exact (claude's own cost-state snapshot, subagents included — but live sessions rarely have one), `~$1.23` = price-sheet estimate over the main transcript (price table duplicated from claude-tokens' JQ_PRELUDE — keep in sync; subagent spend NOT included), `-` = neither. Token/turn/cost sums live in `get_totals_incremental` (tmux-claude-lib), which dedupes assistant records per requestId (one API response logs once per content block — naive summing inflates OUTPUT/TOTAL ~2-3x): SESSION is the flexible left-aligned column absorbing all spare space (so long agent-tree descriptions rarely truncate), the rest are pinned to the right edge; on narrow terminals columns drop before names truncate. Idle/done session rows show an age (time since the transcript's last write), matching agent rows; permission rows too (`⏳ perm 9m` — claude stops writing at the prompt, so mtime ≈ how long it's been stuck). Keys: `j/k` navigate, `⏎` switch to the row's exact pane, `x` kill row (the whole session when it's the session's only claude row, just that pane when the session has others), `X` prune all gone rows (session when every row is gone, else just the gone panes), `a` toggle agent trees, `r` refresh, `R` hard refresh (clears token cache), `q` quit. Sessions whose CWD no longer exists (e.g. deleted worktrees) show `✗ gone`. A session row expands into a tree of its live subagents (indented by spawn depth, parents before children), rendered on the same SESSION/STATUS/MODEL/CONTEXT/OUTPUT/TOTAL column grid as session rows (status shows working/idle with an age — `working 12m` counts from the agent's spawn (its meta.json mtime), `idle 3m` from its last transcript write; MODEL shows the agentType); each row's transcript is resolved pane-exactly via the `tmux` field in `~/.claude/sessions/*.json` (`find_pane_jsonl`), so two claudes sharing one cwd can't read each other's transcript (that pane's cwd+newest-jsonl remains the fallback for /clear); a working agent's activity snippet prints as its own dim quoted line beneath the row. A `+N` badge marks sessions with N agents actively working. Sessions with a working agent auto-expand; `a` forces every session's tree open (including idle-only agents) and toggles back.
- `bin/tmux-claude-statusbar` — ambient attention layer for the tmux status bar: `🔴N ✅N ●N ` for permission-needed / finished-but-unseen / working counts (each segment omitted when zero; empty output when all zero; 🔴/● count sessions, ✅ counts flagged panes). Scans every pane owned by a live claude process — any window of any session (found by tty via one `ps` + one `list-panes -a`, then a single batched capture of just those panes), aggregating worst-status per session (permission > working > idle), so a manually launched claude outside window 1 counts too and non-claude panes are never captured (prompt-lookalike text can't false-positive). The scan is `scan_claude_sessions` in `bin/tmux-claude-lib`, shared with Ctrl+Y's jump. Refreshed every ~5s by tmux. Each tick also publishes `~/.cache/claude-attention/status.tsv` (`<session>\t<status>` per claude session, written atomically) — the sessionizer's row colors read this instead of scanning panes themselves.
- `bin/tmux-claude-attention` — flag-file backend for the attention layer: `~/.cache/claude-attention/<session>@<pane>.done`, one per finished-but-unseen claude PANE (the dir also holds the statusbar's `status.tsv`). Pane granularity fixes two session-level bugs at once: a claude finishing in a background window of an attached session used to be suppressed entirely, and attaching used to wipe the session's flag even when the finished claude's window was never looked at. `flag-done` (called by the Claude Code Stop hook — see the script's header comment for the settings.json snippet) flags `$TMUX_PANE`, silently no-op outside tmux or when the pane is on screen (its window is the session's current one and a client is attached); `clear <session>` removes the flags for the panes in the session's *current window* only, and is triggered by three tmux hooks — client-attached, client-session-changed, and session-window-changed (all control-mode notifications double as hooks; `clear` gates on an attached client because session-window-changed also fires when scripts select-window in detached sessions); `list` prints flagged live panes newest-first, pruning dead-pane and legacy session-level flags; `jump` is Ctrl+Y's backend — both target kinds land on the exact pane's window via select-window/select-pane: done-targets from the flag files (consuming the flag directly), permission targets from the lib's shared `scan_claude_sessions` (multi-pane, tty-gated), whose per-session worst-status line carries the exhibiting pane as a 3rd field precisely so the jump can reach a prompt outside the session's current window.
- `bin/tmux-claude-notify` — notification hook for Claude Code. Sends terminal bell + macOS notification on permission prompts. Configured in `~/.claude/settings.json`.
- `bin/tmux-claude-lib` — shared functions sourced by the claude session manager scripts; home of `new_hub_session` (the standard hub session layout, used by the sessionizer and `wt-tmux-jump`) and `scan_claude_sessions` (the multi-pane status scan behind the statusbar and Ctrl+Y).
- `bin/claude-tokens` — offline token/cost analyzer over the `~/.claude/projects` transcripts (no tmux involved; full-parses files, so seconds not milliseconds). `claude-tokens` = per-project rollup, `sessions [fragment]` = per-session rows, `session <id|path>` = one session's per-model table + per-(sub)agent tree with tokens and estimated cost per agent, `pr <num|url-frag>` = sessions carrying a matching pr-link record, `branch <name>` = sessions that touched a branch; `--since 7d/24h/90m` windows overview/sessions. Costs: sessions with cost-state records report claude's own cumulative cost (subagents included); everything else is estimated from usage × a price table in the script (per-agent rows always are, prefixed `~`). Transcript gotchas the script handles: (1) one assistant record is written per content block with usage that grows across blocks, so records are deduped per requestId keeping the max-output one — estimates still run ~10% under actual because some billed calls (retries, utility requests) never hit the transcript; (2) resuming a session copies the entire history into a new session file (per-record snake_case `session_id` keeps the original id, camelCase `sessionId` is rewritten), so listings collapse each resume chain into one row keyed by the live tip — superseded files dropped, agent counts absorbed, ancestor cost-state reused marked `>` — instead of double-counting near-identical files.

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
  `bin/wt-tmux-cleanup`. `wt-tmux-jump` builds new worktree sessions with
  the same `new_hub_session` layout as the sessionizer (so in window mode
  a worktree session starts claude warm too); the zshrc `wt()` wrapper passes `--no-cd` on
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
