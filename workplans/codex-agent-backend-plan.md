# Workplan: codex as a second agent backend (tmux/hub workflow)

## Goal

Make OpenAI's Codex CLI a first-class alternative to Claude Code inside the
existing tmux workflow — sessionizer, hub-session layout, Ctrl+Space, prefix+C,
attention layer (statusbar / Ctrl+Y / notifications), and the Ctrl+G dashboard —
chosen per session with a configurable default, so both agents can run side by
side and be compared. Script names stay `tmux-claude-*` (no rename churn); an
"agent" concept is introduced inside them.

Prerequisite: the popup-mode retirement (deletes `bin/tmux-claude-popup` and
`bin/tmux-claude-migrate`, drops the `other/tmux-claude-mode` branch so
`new_hub_session` has one window-mode layout, and drops `claude-*` popup
handling) is in flight in a parallel session at the time of writing. This plan
assumes it has landed on master; branch from master AFTER it merges.

Decisions already made (do not re-open):
- Use the Codex CLI directly. Not Claude Code pointed at GPT via a proxy.
- Auth is ChatGPT sign-in against a managed workspace seat (possibly a personal
  plan later). Not API-key. Managed `requirements.toml` may constrain
  approval/sandbox/hooks — see Assumptions.
- Per-session choice, default `claude`, stored in a private mode file.
- Config sharing: only harness-neutral skills are shared (today exactly `pr`).
  `feature`, `hq`, `address-review` depend on Claude harness primitives
  (worktree-isolated Agent tool, ListAgents, SendMessage) and are NOT linked.
- Rules are TABLED: Codex has no rules directory; concatenating
  `dots/claude/rules` into AGENTS.md is a drifting shim. `~/.codex/AGENTS.md`
  is a private hand-written file. Revisit when Codex offers a supported surface.

## Background: Codex facts this plan relies on (docs verified 2026-09)

- Install: `brew install codex` (Rust binary; `ps -o comm=` shows `codex`).
- State dir `~/.codex` (`CODEX_HOME`): `config.toml`, `auth.json`, `hooks.json`,
  `AGENTS.md` (global instructions), `sessions/YYYY/MM/DD/rollout-*.jsonl`.
- Permissions are two-axis: `sandbox_mode` (`read-only` | `workspace-write` |
  `danger-full-access`) × `approval_policy` (`on-request` | `never`).
- Skills: open Agent Skills spec (same `SKILL.md` + `name`/`description`
  frontmatter as Claude Code). Discovery: `.agents/skills` up the tree, then
  `$HOME/.agents/skills`. Symlinked skill dirs are followed. Invoked as `$name`
  or model-chosen. No `disable-model-invocation` equivalent.
- Hooks: `~/.codex/hooks.json` (or inline `[hooks]` in config.toml), gated by
  `features.hooks = true`. Events: `SessionStart` (matcher on source:
  `startup|resume|clear|compact`), `SessionEnd`, `SubagentStart`, `SubagentStop`,
  `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`,
  `UserPromptSubmit`, `Stop`, `Interrupt`. Command hooks get JSON on stdin with
  `session_id`, `cwd`, `transcript_path`, `hook_event_name`, `model`,
  `permission_mode`, plus event fields; `async: true` supported. Hooks inherit
  the shell environment, so `TMUX_PANE` is available exactly as with Claude.
- TUI approval overlay strings (from Codex source `approval_overlay.rs`):
  headers "Would you like to run the following command?", "Would you like to
  make the following edits?", "Would you like to grant these permissions?",
  "<server> needs your approval."; options begin "Yes, " ("Yes, proceed",
  "Yes, make the edits", ...), "No, ...".
- Rollout JSONL: `session_meta` (id, cwd), `turn_context` (model, effort),
  `event_msg` of type `token_count` carrying cumulative usage
  (`input_tokens`, `cached_input_tokens`, `output_tokens`,
  `reasoning_output_tokens`), `model_context_window`, and `rate_limits`
  (`primary.used_percent`, window, reset). Exact field paths: CALIBRATE.
- Cross-session: `codex queue --session <name> "<msg>"` (app-server daemon),
  `codex agents` dashboard, `codex exec --json`. Out of scope here.

## Design

### Agent selection
- `other/tmux-agent-default` (private, one line: `claude` | `codex`; missing →
  `claude`). Lib helpers in `bin/tmux-claude-lib`: `agent_default`,
  `session_agent <session>` (tmux session option `@agent`, falling back to the
  default), `agent_window_name <agent>` (= the agent name).
- `new_hub_session <name> <dir> [agent]` sets `@agent` on the session, names
  window 1 `<agent>`, and `send-keys "<agent>" Enter` into an initialized shell
  (same reason as today: `other/zshrc.local` env must apply).
- Sessionizer override: fzf `--expect=ctrl-x,alt-enter`. Enter = default agent
  (today's behavior, unchanged). ctrl-x or Option+Enter, on a project WITHOUT a
  session yet, builds the same hub layout with the *other* agent. On an
  existing session both keys just switch to it. Header line:
  `⏎ new: <default> · ⌥⏎/^x new: <other>`. These are fzf-scoped keys like the
  existing `ctrl-/` — not tmux bindings. fzf 0.74 knows `alt-enter` but no
  `shift-enter`/`ctrl-enter`; tmux passes `\e\r` through untouched. Do NOT add
  Ghostty keybinds; if Option+Enter doesn't reach fzf as alt-enter, ctrl-x is
  the supported path and any terminal tweak is the user's call.
- `bin/tmux-claude-window` (C-Space): find/create the window named
  `agent_window_name "$(session_agent "$S")"` and type that agent. New
  `--extra` mode replaces the inline prefix+C binding in `dots/tmux.conf`:
  window `<agent>+`, automatic-rename off, send-keys agent.

### Liveness
- `agent_ttys` (new): one `ps -A -o tty=,comm=` → `tty\tagent` lines; comm
  matching `/claude/` or `/(^|\/)node$/` → `claude`, `/codex/` → `codex`.
  `claude_ttys` becomes a wrapper printing every agent's ttys (all consumers
  mean "agent panes"). `get_claude_panes` gains a 4th column `agent`;
  `scan_claude_sessions` carries the agent on the separator line and passes it
  to the classifier. `is_claude_pane_command` also accepts `codex*`.

### Status classification
- `classify_pane_status <raw> [agent]`; `claude` path byte-for-byte unchanged.
  `codex` dispatches to `classify_codex_pane_status` in a NEW file
  `bin/tmux-claude-lib-codex`, sourced at the end of `tmux-claude-lib`. Same
  contract (last 10 non-blank lines, pure bash 3.2, zero forks):
  permission = `*"Would you like to"*` or `*"needs your approval"*` AND `*"Yes, "*`;
  working = `*"to interrupt"*` (+ whatever the live capture shows — CALIBRATE);
  idle = composer prompt char (`›` expected — CALIBRATE); else unknown.
- `bin/tmux-claude-notify`: accept both hook schemas (`notification_type` from
  Claude, `hook_event_name` from Codex); `PermissionRequest` → "needs
  permission"; notification title `Codex` vs `Claude Code` accordingly.

### Attention
- Codex `Stop` hook → `tmux-claude-attention flag-done` — works unmodified
  (`TMUX_PANE`-keyed). `PermissionRequest` hook → `tmux-claude-notify`.
  `SessionStart` (matcher `startup|resume|clear`) →
  `tmux-claude-attention codex-session-start`; `SessionEnd` →
  `codex-session-end`. These two are NOT async (the map must be written before
  anything reads it).

### Dashboard telemetry
- Pane→rollout map (Codex has no tmux field in its session state):
  `codex-session-start` reads hook stdin and atomically writes
  `~/.cache/claude-attention/codex/<pane-sans-%>.tsv` =
  `session_id\ttranscript_path\tcwd`; `codex-session-end` removes it. Both
  no-op without `TMUX_PANE`. Fallback: newest rollout under `~/.codex/sessions`
  whose `session_meta.cwd` equals the pane's cwd.
- In `tmux-claude-lib-codex`: `codex_find_pane_jsonl <pane>`,
  `codex_get_context_and_model <jsonl>` (tail → last `token_count`: context =
  last-turn input + cached, window = `model_context_window`; model from the
  last `turn_context`), `codex_get_totals <jsonl> <cache>` (output/total from
  cumulative usage; turns = user message records; cost `-`; rate-limit
  `used_percent` as an extra field). Handle `.jsonl.zst` via `zstd -dc` if met.
- `bin/tmux-claude-dashboard`: dispatch per row on the agent column. Codex rows:
  CONTEXT uses the in-transcript window (bypass `context_window_for`), MODEL
  shown raw, COST shows `5h:NN%` rate-limit usage when available else `-`, no
  agent tree (subagent rollouts skipped in v1). `short_model` strips only
  `claude-`. `x`/`X` already operate on panes/sessions — agnostic.

### Config layering (public repo — two layers, same as claude)
- Tracked generic → `dots/codex/`: `hooks.json`, `shared-skills` (one skill
  name per line; initially `pr`).
- Private → `other/codex/`: `config.toml` (seeded from tracked
  `config.toml.example`: `features.hooks = true`,
  `approval_policy = "on-request"`, `sandbox_mode = "workspace-write"`,
  `tui.notifications = ["approval-requested"]`, commented `model` /
  `model_reasoning_effort` / `tui.status_line`), `AGENTS.md` (seeded from
  tracked `AGENTS.md.example`: a few generic lines — uv for python, tmux safety
  pointer), `skills/` (dir linked to `~/.agents/skills`, private by default).
- `.gitignore`: add `!other/codex`, `other/codex/*`, `!other/codex/*.example`
  (mirror the existing `other/claude` block).
- `bin/seed_other.sh`: extend the glob to `other/codex/*.example`.
- `bin/symlink_files.sh`: new `===== codex =====` block — `mkdir -p ~/.codex
  ~/.agents $other/codex/skills`; link `other/codex/config.toml` →
  `~/.codex/config.toml`, `other/codex/AGENTS.md` → `~/.codex/AGENTS.md`,
  `dots/codex/hooks.json` → `~/.codex/hooks.json`, `other/codex/skills` →
  `~/.agents/skills`; then per-item RELATIVE links for each name in
  `dots/codex/shared-skills` from `dots/claude/skills/<name>`. Factor the
  existing claude per-item loop (prune dangling, warn on private shadow) into
  `layer_tracked_items <src-dir> <dst-dir> [allowlist-file]` and use it for both.

## Files

Modify: `bin/tmux-claude-lib`, `bin/tmux-claude-window`, `bin/tmux-sessionizer`,
`bin/tmux-claude-attention`, `bin/tmux-claude-notify`, `bin/tmux-claude-dashboard`,
`bin/symlink_files.sh`, `bin/seed_other.sh`,
`dots/tmux.conf`, `etc/Brewfile_mac` (`brew "codex"`), `.gitignore`, `CLAUDE.md`,
`other/README.md`, `dots/claude/skills/hq/SKILL.md` (note the optional agent arg
to `new_hub_session`; hq keeps spawning the default).
New: `bin/tmux-claude-lib-codex`, `dots/codex/hooks.json`, `dots/codex/shared-skills`,
`other/codex/config.toml.example`, `other/codex/AGENTS.md.example`, `notes/codex.md`
(setup checklist: brew, `codex login`, `/hooks` shows 4, `/skills` shows `pr`,
`/status` shows the managed constraints).

## Ordered steps

1. Config layering: `.gitignore`, `dots/codex/*`, `other/codex/*.example`,
   `seed_other.sh`, `symlink_files.sh` (+ `layer_tracked_items` refactor),
   Brewfile. Run `./bin/symlink_files.sh`; verify the claude layer is unchanged.
2. Lib agent helpers + `new_hub_session` agent arg; `tmux-claude-window`
   (+ `--extra`); tmux.conf prefix+C; sessionizer `--expect` + header.
3. Liveness: `agent_ttys`, pane/scan plumbing carrying the agent column.
4. Codex classifier skeleton in `tmux-claude-lib-codex` with the verified
   permission strings; wire `classify_pane_status` dispatch; notify dual-schema.
5. CALIBRATE (needs a logged-in codex in a hub session): capture working /
   permission / idle screens with `tmux capture-pane -p` (read-only); finalize
   the classifier strings; `jq -c .type` over the newest rollout to confirm
   record shapes; finalize the codex reader's jq.
6. Attention hooks (`codex-session-start/end`, map dir) and the codex reader
   functions; dashboard per-row dispatch.
7. Docs: `CLAUDE.md` (new "Agents: claude + codex" subsection under Conventions;
   reword Ctrl+Space / prefix+C / dashboard bullets), `other/README.md`,
   `notes/codex.md`, hq SKILL.md note.

## Assumptions

- VERIFIED: every launcher except tmux.conf prefix+C goes
  through `new_hub_session` (repo sweep of bin/ and dots/tmux.conf).
- VERIFIED: liveness for statusbar / sessionizer colors / Ctrl+Y / dashboard
  funnels through `claude_ttys` + `is_claude_pane_command`.
- VERIFIED (docs): hook events, stdin fields, env inheritance, skills discovery
  path and spec compatibility, as listed under Background.
- VERIFIED (source): approval overlay strings as listed under Background.
- VERIFIED: fzf 0.74 has `alt-enter` and no `shift-enter`/`ctrl-enter`; ctrl-x
  is unbound in fzf and unclaimed in tmux.conf; tmux runs `extended-keys off`.
- ASSUMED (calibrate, step 5): Codex working indicator contains "to interrupt";
  idle composer prompt char; `token_count` payload field paths.
- ASSUMED: brew-installed `codex` shows as `codex` in `ps -o comm=` (Rust
  binary). An npm install shows the platform binary name, still matching /codex/.
- ASSUMED: the managed workspace does not set `allow_managed_hooks_only` or
  forbid `workspace-write`. Check `/status` and `/hooks` after login. If hooks
  are blocked, attention/telemetry degrade to scraping + the cwd/newest-rollout
  fallback (both designed in).
- ASSUMED: Option+Enter reaches fzf as `alt-enter` under Ghostty's default
  option handling inside tmux. If not, ctrl-x is the override; no Ghostty change.
- VERIFIED (orchestrator, 2026-09-05): the popup-retirement prerequisite is on
  master (c797ec1); `other/tmux-claude-mode` and `tmux-claude-popup` are gone.
- VERIFIED (orchestrator): consumers of `new_hub_session` are exactly
  `bin/tmux-sessionizer`, `bin/wt-tmux-jump`, and the hq SKILL.md snippet;
  `scan_claude_sessions` is consumed by `tmux-claude-statusbar` and
  `tmux-claude-attention jump`; `get_claude_panes`/`find_pane_jsonl` by the
  dashboard. Nothing else reads them.
- VERIFIED (orchestrator): `codex` 0.153.4 is brew-installed at
  `/opt/homebrew/bin/codex`; `~/.codex/` holds `auth.json` and a `config.toml`
  that codex itself wrote (a `[projects."..."] trust_level` entry only); no
  `hooks.json`, `AGENTS.md`, `~/.agents/skills`, or `sessions/` yet. Consequence:
  codex writes per-project trust entries INTO config.toml, so once
  `~/.codex/config.toml` is a link into `other/codex/`, those writes land in the
  private file (fine, gitignored). `symlink_files.sh` backs the pre-existing real
  file up; the user merges its `[projects]` block by hand — noted in
  `notes/codex.md`.
- VERIFIED (orchestrator): `bin/symlink_files.sh` hardcodes `$HOME/dotfiles`,
  so it cannot be exercised from a worktree against the real home. Test it with
  a sandbox `HOME` (scratch dir containing a `dotfiles` symlink to the
  worktree) — never against the real `~/.codex`/`~/.claude` from the worktree.
- ASSUMED: step 5 calibration may be impossible from the pipeline (no codex
  session has ever run here; approval prompts need an interactive turn). If a
  throwaway-socket (`tmux -L codex-test-$$`) capture cannot be obtained, ship
  the classifier with the docs/source-verified permission strings and the
  ASSUMED working/idle strings, record the gap in NOTES and here, and leave the
  fixture files as the place to paste real captures.

## Test plan

1. `brew bundle` / `brew install codex`; user runs `codex login`;
   `./bin/symlink_files.sh`; `ls -la ~/.codex ~/.agents/skills`; in codex:
   `/hooks` lists 4 hooks, `/skills` lists `pr`, `/status` matches config.
2. Fixture test for both classifiers: feed captured pane text (claude AND codex,
   all three states) and assert the status; keep the fixtures in the repo.
3. Launch: Ctrl+F new project + Enter → `<default>` window; + ctrl-x or
   Option+Enter → window `codex`, `tmux show -t <s> @agent` = codex; C-Space
   toggles the codex window; prefix+C opens `codex+`. `wt switch -c` sessions
   still get the default agent.
4. Attention: codex finishing a turn in a background window → statusbar ✅ and
   Ctrl+Y lands on that pane; an approval prompt → 🔴 + macOS notification
   titled Codex; sessionizer row colors follow `status.tsv`.
5. Dashboard: codex row shows status, model, `used/window` context, CTX%,
   TURNS, OUTPUT/TOTAL, rate-limit in COST; `/new` inside codex → the map
   refreshes and the row follows; claude rows unchanged.
6. Regression: with only claude sessions running, `status.tsv`, statusbar
   counts, sessionizer colors, and dashboard rows are identical to before.
   Statusbar scan stays inside its ~200ms budget with the extra ps arm.
7. Any test that needs a tmux server uses a throwaway socket with `-L` visible
   in the command text (`tmux -L codex-test-$$ ...`) — never the live server.

## Out of scope (this pass)

- hq dispatch to codex (`codex queue` bridge for SendMessage, ListAgents
  equivalent, porting `/feature` to Codex subagents).
- `bin/claude-tokens` (offline analyzer) reading codex rollouts.
- Codex subagent trees in the dashboard; exact cost for codex (plan auth has no
  per-token cost — rate-limit % stands in).
- Popup mode for codex (popups are retired).
- Sharing rules into AGENTS.md (tabled, see Goal).
- Renaming `bin/tmux-claude-*` (and `~/.cache/claude-attention`) to agent-neutral
  names. Deliberately deferred: the names are wired into tmux.conf, both agents'
  hook configs, private settings.json on every machine, the hq skill, and docs.
  Do it as a separate mechanical PR once codex has proven worth keeping — move
  the files, leave the old names as symlinks so hook paths keep working, then
  update docs.

## Public-repo caution

Nothing in `dots/codex/`, the `*.example` files, `notes/codex.md`, or commit
messages may carry private paths, workspace/org names, or model deployment
names. `other/codex/` is gitignored except the examples. Sweep the diff before
pushing.
