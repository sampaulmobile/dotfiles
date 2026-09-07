# Codex as a second agent backend

Codex (OpenAI's CLI) runs in the same tmux workflow as Claude Code: the
sessionizer builds its sessions, Ctrl+Space toggles its window, prefix+C
opens an extra one, the status bar counts its prompts, Ctrl+Y jumps to them,
and Ctrl+G shows its tokens. Which agent a session runs is decided when the
session is created and pinned as the tmux session option `@agent`.

Verified against codex-cli 0.153.4.

## Setup

1. **Install** — `brew bundle --file etc/Brewfile_mac` (or `brew install
   codex`).

2. **Back up the config codex already wrote.** Codex stores per-project
   trust in `~/.codex/config.toml` (`[projects."<path>"] trust_level`), and
   the next step replaces that file with a link into `other/codex/`:

   ```
   cp ~/.codex/config.toml /tmp/codex-projects.toml   # keep the [projects] block
   ```

   (`bin/symlink_files.sh` also moves the original into its
   `~/DELETE_dotfiles-<timestamp>` backup dir, so it is recoverable either
   way.)

3. **Link the config** — `./bin/symlink_files.sh`. It seeds
   `other/codex/config.toml` and `other/codex/AGENTS.md` from their
   `.example` templates and creates:

   ```
   ~/.codex/config.toml -> other/codex/config.toml      (private)
   ~/.codex/AGENTS.md   -> other/codex/AGENTS.md        (private)
   ~/.codex/hooks.json  -> dots/codex/hooks.json        (tracked)
   ~/.agents/skills     -> other/codex/skills           (private dir, with
                                                         per-item links to
                                                         the shared tracked
                                                         skills inside)
   ```

   It creates `~/.codex` and `~/.agents` on every machine, codex installed
   or not (empty dirs cost nothing, and the links are then already in place),
   and a pre-existing REAL `~/.agents/skills` directory is moved into the
   `~/DELETE_dotfiles-<timestamp>` backup dir before the link replaces it —
   the same policy as the `~/.claude` dirs, so hand-written skills there are
   recoverable but no longer live until you move them into
   `other/codex/skills/`.

   Then paste the saved `[projects]` block back into
   `other/codex/config.toml` — future trust entries codex writes land there
   too (gitignored, so nothing private is ever committed).

4. **Sign in** — `codex login` (ChatGPT sign-in; not an API key).

5. **Trust the hooks.** Codex refuses to run hooks it has not been shown.
   Start `codex` and either answer the startup prompt ("Hooks need review")
   with *Trust all and continue*, or run `/hooks` and press `t`. The table
   must show 4 hooks, all Active:

   | Event | What it does |
   |-------|--------------|
   | SessionStart | writes the pane → rollout map the Ctrl+G dashboard reads |
   | SessionEnd | removes that map entry |
   | Stop | flags the pane "finished but unseen" (✅ in the status bar, Ctrl+Y target) |
   | PermissionRequest | bell + macOS notification titled *Codex* |

   **Any edit to `hooks.json` invalidates the trust** and the prompt comes
   back — expected, not a bug.

6. **Check the rest** — inside codex: `/skills` lists the shared tracked
   skills (`pr` today; the list is `dots/codex/shared-skills`), and
   `/status` shows the approval policy and sandbox mode from
   `other/codex/config.toml`. A managed workspace can override those; what
   `/status` shows is what you actually get.

## Choosing the agent

Picking the default and the per-session override is in CLAUDE.md's Agents
convention. Two things only true here:

- **Check what a session got**: `tmux show-options -t <session> @agent` — a
  plain session name, since the `=name` exact-match form comes back empty
  for options.
- Worktree sessions from `wt switch -c` always get the default agent.

## What differs from claude in the tooling

- **Dashboard (Ctrl+G)**: codex rows take their context window from the
  rollout itself, show the model id raw, and put the plan's rate-limit usage
  (e.g. `5h:42%`) in the COST column — plan billing has no per-token cost.
  Rows show no subagent tree; codex subagents are not read yet.
- **Turns**: counted as `task_started` events in the rollout — one per
  prompt you submit.
- **`bin/claude-tokens`** (the offline analyzer) still only reads claude
  transcripts.
- **Rules and skills**: codex has no rules directory, and only
  harness-neutral skills are shared — see CLAUDE.md's Agents convention for
  which, and why.

## Gotchas found while wiring this up

- `SessionStart` fires on a thread's **first prompt**, not when the TUI
  launches — so a codex you started but never prompted has no map entry
  yet. The dashboard falls back to the newest rollout whose `session_meta`
  cwd matches the pane's.
- `/new` starts a new thread and fires `SessionStart` again (source is
  still `startup`), so the map follows the new rollout.
- `SessionEnd` fires on `/quit` even for a thread that never started.
- `hooks.json` accepts only two top-level keys, `description` and `hooks`;
  anything else is a parse error and ALL hooks are dropped (codex prints a
  warning line in the TUI). Hook commands are shell-expanded, so `$HOME`
  works.
- A hook that is not executable fails the turn visibly ("Hook failed — hook
  exited with code 126").
- The first run in a new directory asks a separate "Do you trust the
  contents of this directory?" question. Both that and the hook-trust prompt
  count as "needs attention" in the status bar, since both block the agent.
