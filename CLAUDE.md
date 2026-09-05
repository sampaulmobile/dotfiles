# Dotfiles

Personal dotfiles for macOS (Apple Silicon). Managed with symlinks, no fancy framework.

## Structure

- `dots/` — config files, symlinked to `~/` or `~/.config/` by `bin/symlink_files.sh`
- `bin/` — scripts (install helpers, tmux scripts, worktree helpers, etc.)
- `sources/` — zsh source files (aliases, history config, exports)
- `etc/` — Brewfiles: `Brewfile_mac` (base, all machines), `Brewfile_other` (supplemental, installed by `setup_other.sh`)
- `dots/claude/` — the generic, tracked Claude Code layer: `skills/`, `rules/`, `agents/`. Layered into `~/.claude/` by `bin/symlink_files.sh` as per-item links inside the `other/claude/` dirs (see below), so tracked and private entries coexist. Promote a private item by moving it here and re-running the script.
- `dots/codex/` — the generic, tracked Codex layer: `hooks.json` (the tmux attention hooks) and `shared-skills` (which `dots/claude/skills/` entries are also linked into `~/.agents/skills`). Private codex config lives in `other/codex/`. See `notes/codex.md`.
- `tests/` — offline bash tests for the agent layer (pane-status classifier, notify hook schemas, codex rollout reader) plus their fixtures. `tests/run.sh` runs everything under both `/bin/bash` (3.2) and the default bash. No tmux server is started or touched.
- `templates/` — scaffolds copied to new locations by `bin/` scripts: `templates/hq/` → `bin/hq-init` (the `/hq` dispatcher repo, default `~/dev/hq`)
- `other/` — machine-local config, gitignored except `*.example` templates and README. Consumed via: zshrc sources `other/zshrc.local` last; gitconfig includes `other/gitconfig.local`; tmux-sessionizer sources `other/tmux-sessionizer.local` (can redefine `search_dirs`); `other/claude/` symlinked into `~/.claude/` by `bin/symlink_files.sh` (settings.json file link; skills/, rules/, agents/ dir links — anything dropped into `~/.claude/{skills,rules,agents}` therefore lands here, private by default); `other/codex/` the same way for codex (config.toml, AGENTS.md, skills/); `other/tmux-agent-default` picks the default agent for new sessions
- `archive/` — old/unused configs kept for reference
- `notes/` — machine setup guides

## IMPORTANT: This repo is PUBLIC

Nothing sensitive or machine/employer-identifying may ever be committed — no
private filepaths, directory/service/project names, or absolute paths beyond
generic `$HOME` placeholders, in tracked files OR commit messages. All of that
belongs in the gitignored `other/` directory. Claude Code config splits the
same way: generic skills/rules/agents are tracked in `dots/claude/` and get
the same sweep as any other tracked text; anything private (settings.json,
private skills) stays in `other/claude/`. Generic public package names in
Brewfiles are fine. Sweep diffs before pushing.

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
- `Ctrl+Space` — toggle the agent window per project: jump to/from the window named after the session's agent (`claude` or `codex` — its `@agent` option), creating it on first use (`bin/tmux-claude-window`)
- `prefix+C` — extra agent window in the current session: new window at the caller pane's directory (repo dir in a hub/worktree session, wherever you've cd'd otherwise) running the session's agent via a shell. Named `<agent>+` (e.g. `claude+`), not `<agent>`, so the C-Space by-name lookup never grabs it; dashboard/statusbar/Ctrl+Y track agents by tty, so extra windows show up in all of them automatically (the dashboard gives each its own `session:N` row). Runs `bin/tmux-claude-window --extra` because the window name depends on the session's agent. Shadows tmux's default customize-mode binding.
- `Ctrl+G` — agent session dashboard (status, tokens, model for every claude and codex session)
- `Ctrl+Y` — jump to whatever needs attention: a session waiting on a permission prompt first, else the newest finished-but-unseen agent pane (landing on its window, not just its session), else a "nothing needs attention" message. Landing on a flagged pane clears its ✅ flag. Passed through untouched to vim/fzf when the current pane is running one (same is-vim detection idiom as vim-tmux-navigator's own C-h/j/k/l bindings), since `C-y` is vim's scroll-line-up — everywhere else it shadows readline's rare `yank`. (Not `Ctrl+J` — vim-tmux-navigator's pane navigation; not `Ctrl+O` — Claude Code's toggle-verbose-transcript key, which a root binding stole in exactly the panes this layer serves.)
- URLs open with **⌘⇧+hover+click** (Ghostty) — shift is required because tmux `mouse on` (and Claude Code's TUI) capture mouse reporting, so unshifted clicks never reach Ghostty's link handler. Keyboard alternative: `prefix+u` (wfxr/tmux-fzf-url) fuzzy-picks a URL from the pane and opens it in the browser — also the fix for URLs that wrap/truncate inside tmux and so don't match Ghostty's regex (the plugin captures with `-J`, joining wrapped lines); it lists claude's OSC 8 `file://` tool-use links too. `prefix+U` (`bin/tmux-url-latest`) skips the picker and opens the newest URL directly — same extraction, filtered to http(s) so the ubiquitous file:// links don't shadow the web URL just printed.
- `F12` — toggle keys off (for nested tmux over SSH)

## Tmux Scripts

- `bin/tmux-sessionizer` — fuzzy finds projects in `~/dev` (depth 1) and `~/dotfiles` (depth 0). For worktree-layout repos (those with `.bare/`), enumerates each worktree as a separate entry. Sessions named `<project>_<branch>` for worktrees, `<basename>` for regular repos (dots → underscores). Scans NOTHING at keypress time: rows stream straight into fzf, and status colors come from caches (the statusbar's `status.tsv`, ignored when stale, plus the attention `.done` flags) — red = permission prompt waiting, green = finished-but-unseen, blue = working, dim blue = idle agent; dirs without a session render dim with `~`-shortened paths (cyan tint = linked worktree, i.e. `.git` is a file). `ctrl-/` inside fzf toggles a lazy preview (live pane snapshot for sessions; git status/log for dirs). New sessions get the standard hub layout via `new_hub_session` in `bin/tmux-claude-lib`: agent (warm) / nvim / zsh, landing on the agent. `Enter` uses the default agent, `ctrl-x` or Option+Enter the other one (fzf `--expect` keys, not tmux bindings; the header line names both) — on a row that already has a session all of them just switch to it. The nvim window launches nvim in the project dir and keeps automatic-rename (shows "nvim" while it runs, tracks later commands); only the agent window's name is pinned.
- `bin/tmux-claude-window` — the C-Space and prefix+C implementation: toggles between the session's agent window (found by the name of its `@agent` — `claude` or `codex`) and the last-used window, creating it at the current pane's path when missing; `--extra` instead opens a new `<agent>+` window there (prefix+C). The old floating-popup layout (`claude-<session>` sessions, `bin/tmux-claude-popup`, `bin/tmux-claude-migrate`, the `other/tmux-claude-mode` file) was removed in 2026-09; see git history if it's ever wanted again.
- `bin/tmux-claude-dashboard` — interactive dashboard showing all agent sessions (claude and codex) with status (working/idle/permission/gone), token usage (context/output/total), and model. One row per agent PANE, not per tmux session (`get_claude_panes` in tmux-claude-lib, whose 4th column says which agent the row is): a second claude outside window 1 gets its own row named `session:N` (N = window index) with its own transcript, tokens, and subagent tree — per-session rows pinned to window 1's transcript made such a claude (and its agents) invisible. Columns (SESSION, STATUS, MODEL, CONTEXT, CTX%, TURNS, OUTPUT, TOTAL, COST) fill the terminal width — CONTEXT is a used/total fraction of the model's window (`162.7k/1M`; per-model table in the script, `context_window_for`: 1M for the current Fable/Opus/Sonnet lineup, 200K Haiku/older, bare number when unknown) and CTX% the same as a percent, which drives the context coloring (yellow ≥50%, red ≥70%, bold red ≥90%; unknown models fall back to absolute thresholds). TURNS = user prompts handled (not API requests). COST: `$1.23` = exact (claude's own cost-state snapshot, subagents included — but live sessions rarely have one), `~$1.23` = price-sheet estimate over the main transcript (price table duplicated from claude-tokens' JQ_PRELUDE — keep in sync; subagent spend NOT included), `-` = neither. Token/turn/cost sums live in `get_totals_incremental` (tmux-claude-lib), which dedupes assistant records per requestId (one API response logs once per content block — naive summing inflates OUTPUT/TOTAL ~2-3x): SESSION is the flexible left-aligned column absorbing all spare space (so long agent-tree descriptions rarely truncate), the rest are pinned to the right edge; on narrow terminals columns drop before names truncate. Idle/done session rows show an age (time since the transcript's last write), matching agent rows; permission rows too (`⏳ perm 9m` — claude stops writing at the prompt, so mtime ≈ how long it's been stuck). Keys: `j/k` navigate, `⏎` switch to the row's exact pane, `x` kill row (the whole session when it's the session's only claude row, just that pane when the session has others), `X` prune all gone rows (session when every row is gone, else just the gone panes), `a` toggle agent trees, `r` refresh, `R` hard refresh (clears token cache), `q` quit. Sessions whose CWD no longer exists (e.g. deleted worktrees) show `✗ gone`. A session row expands into a tree of its live subagents (indented by spawn depth, parents before children), rendered on the same SESSION/STATUS/MODEL/CONTEXT/OUTPUT/TOTAL column grid as session rows (status shows working/idle with an age — `working 12m` counts from the agent's spawn (its meta.json mtime), `idle 3m` from its last transcript write; MODEL shows the agentType); each row's transcript is resolved pane-exactly via the `tmux` field in `~/.claude/sessions/*.json` (`find_pane_jsonl`), so two claudes sharing one cwd can't read each other's transcript (that pane's cwd+newest-jsonl remains the fallback for /clear); a working agent's activity snippet prints as its own dim quoted line beneath the row. A `+N` badge marks sessions with N agents actively working. Sessions with a working agent auto-expand; `a` forces every session's tree open (including idle-only agents) and toggles back. Codex rows differ in three ways: their context window comes from the rollout's own `model_context_window` (not the per-model table), COST shows the plan's rate-limit usage (`5h:42%`) since plan billing has no per-token cost, and they have no subagent tree. Their transcript is found through the pane → rollout map that codex's SessionStart hook writes (see `bin/tmux-claude-attention`), falling back to the newest rollout whose recorded cwd matches the pane's.
- `bin/tmux-claude-statusbar` — ambient attention layer for the tmux status bar: `🔴N ✅N ●N ` for permission-needed / finished-but-unseen / working counts (each segment omitted when zero; empty output when all zero; 🔴/● count sessions, ✅ counts flagged panes). Scans every pane owned by a live agent process (claude or codex — one `ps`, `agent_ttys`) — any window of any session (found by tty via one `ps` + one `list-panes -a`, then a single batched capture of just those panes), aggregating worst-status per session (permission > working > idle), so a manually launched claude outside window 1 counts too and non-claude panes are never captured (prompt-lookalike text can't false-positive). The scan is `scan_claude_sessions` in `bin/tmux-claude-lib`, shared with Ctrl+Y's jump. Refreshed every ~5s by tmux. Each tick also publishes `~/.cache/claude-attention/status.tsv` (`<session>\t<status>` per claude session, written atomically) — the sessionizer's row colors read this instead of scanning panes themselves.
- `bin/tmux-claude-attention` — flag-file backend for the attention layer: `~/.cache/claude-attention/<session>@<pane>.done`, one per finished-but-unseen agent PANE (the dir also holds the statusbar's `status.tsv`, and `codex/<pane>.tsv` — the pane → rollout map written by codex's SessionStart hook, since codex records no tmux pane of its own; `codex-session-end` drops an entry and `list` prunes entries whose pane is gone). Pane granularity fixes two session-level bugs at once: a claude finishing in a background window of an attached session used to be suppressed entirely, and attaching used to wipe the session's flag even when the finished claude's window was never looked at. `flag-done` (called by the Claude Code Stop hook — see the script's header comment for the settings.json snippet) flags `$TMUX_PANE`, silently no-op outside tmux or when the pane is on screen (its window is the session's current one and a client is attached); `clear <session>` removes the flags for the panes in the session's *current window* only, and is triggered by three tmux hooks — client-attached, client-session-changed, and session-window-changed (all control-mode notifications double as hooks; `clear` gates on an attached client because session-window-changed also fires when scripts select-window in detached sessions); `list` prints flagged live panes newest-first, pruning dead-pane and legacy session-level flags; `jump` is Ctrl+Y's backend — both target kinds land on the exact pane's window via select-window/select-pane: done-targets from the flag files (consuming the flag directly), permission targets from the lib's shared `scan_claude_sessions` (multi-pane, tty-gated), whose per-session worst-status line carries the exhibiting pane as a 3rd field precisely so the jump can reach a prompt outside the session's current window.
- `bin/tmux-claude-notify` — notification hook for both agents. Sends terminal bell + macOS notification on permission prompts, titled after whichever agent asked. Reads Claude Code's Notification payload (`notification_type`) and codex's PermissionRequest payload (`hook_event_name`). Wired in `~/.claude/settings.json` for claude and `dots/codex/hooks.json` for codex.
- `bin/tmux-claude-lib` — shared functions sourced by the agent session manager scripts; home of the agent helpers (`agent_default`, `agent_other`, `session_agent`, `agent_window_name`), `new_hub_session` (the standard hub session layout, used by the sessionizer and `wt-tmux-jump`, taking an optional agent), `agent_ttys` (the one `ps` behind every liveness check) and `scan_claude_sessions` (the multi-pane status scan behind the statusbar and Ctrl+Y). Sources `bin/tmux-claude-lib-codex` at the end.
- `bin/tmux-claude-lib-codex` — the codex half: `classify_codex_pane_status` (its own TUI strings — approval overlays, the two trust prompts, "esc to interrupt", the composer placeholder) and the rollout reader (`codex_find_pane_jsonl`, `codex_get_context_and_model`, `codex_get_totals`). Kept separate so the claude classifier, which the whole attention layer leans on, stays untouched.
- `bin/claude-tokens` — offline token/cost analyzer over the `~/.claude/projects` transcripts (claude only — it does not read codex rollouts) (no tmux involved; full-parses files, so seconds not milliseconds). `claude-tokens` = per-project rollup, `sessions [fragment]` = per-session rows, `session <id|path>` = one session's per-model table + per-(sub)agent tree with tokens and estimated cost per agent, `pr <num|url-frag>` = sessions carrying a matching pr-link record, `branch <name>` = sessions that touched a branch; `--since 7d/24h/90m` windows overview/sessions/branch (default: no window, i.e. all transcripts on disk; a straddling session still reports lifetime totals, and the output footer states the active range either way). Costs: sessions with cost-state records report claude's own cumulative cost (subagents included); everything else is estimated from usage × a price table in the script (per-agent rows always are, prefixed `~`). Transcript gotchas the script handles: (1) one assistant record is written per content block with usage that grows across blocks, so records are deduped per requestId keeping the max-output one — estimates still run ~10% under actual because some billed calls (retries, utility requests) never hit the transcript; (2) resuming a session copies the entire history into a new session file (per-record snake_case `session_id` keeps the original id, camelCase `sessionId` is rewritten), so listings collapse each resume chain into one row keyed by the live tip — superseded files dropped, agent counts absorbed, ancestor cost-state reused marked `>` — instead of double-counting near-identical files.

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
- Claude Code config is two-layered (public repo): the generic skills/rules/agents are tracked in `dots/claude/`; settings.json (seeded from `other/claude/settings.json.example`) and private skills live in `other/claude/`; machine differences (model, TLS) are env vars in `other/zshrc.local` (e.g. `ANTHROPIC_MODEL`). Never commit settings.json or anything from `other/`.
- **Agents: claude + codex.** Two backends share the tmux layer. A session's agent is fixed when the session is created and pinned as the tmux session option `@agent`; the scripts keep their `tmux-claude-*` names (renaming them is a separate mechanical change — the names are wired into tmux.conf, both agents' hook configs, private settings.json, the hq skill, and these docs). The default is `claude`, overridable with a one-line `other/tmux-agent-default`; the sessionizer's `ctrl-x` / Option+Enter builds a new session with the other agent. Codex config is two-layered like claude's: tracked `dots/codex/` (hooks.json, shared-skills), private `other/codex/` (config.toml, AGENTS.md, skills/). Only harness-neutral skills are shared with codex (`dots/codex/shared-skills`, `pr` today) — `feature`/`hq`/`address-review` need Claude Code's Agent tool, ListAgents and SendMessage. Rules are NOT shared: codex has no rules directory, and `~/.codex/AGENTS.md` is hand-written (seeded from `other/codex/AGENTS.md.example`). Setup, hook trust and the per-agent differences are in `notes/codex.md`.
- `/hq` needs an hq repo at `~/dev/hq` (routing table + coordinator CLAUDE.md); `bin/hq-init` scaffolds one from `templates/hq/`. The skill stops and says so when the routing table is missing.
- claude-code is installed via npm global — per-node-version under fnm, so reinstall after changing the default node.
