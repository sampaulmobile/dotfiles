# other/ — machine-local config

Everything machine-specific or private lives here, in one place. The public
dotfiles repo tracks only this README and the `*.example` templates; the real
files are gitignored by it and belong to a second, PRIVATE git repo rooted at
this directory (`other/.git`), which is how two machines share them. The
nesting is clean: the outer repo keeps tracking the README and templates, and
the inner repo ignores exactly those (its `.gitignore`: `.DS_Store`, `*.zip`,
`README.md`, `*.example`), so every file has one home. `*.zip` stays local —
the repo-secrets archive must never leave the machine.

## Cross-machine sync

`bin/sync` (in this directory) is run by a launchd job every 5 minutes: it
commits, merges from origin and pushes this repo and `~/dev/hq`, and only
merges and pushes `~/dev/wiki` (whose commits are the wiki write-back flow's,
and which it skips while dirty). A conflict is aborted and logged, never
resolved; nothing is ever force-pushed. `bin/sync --check` is `bin/doctor`'s
"private state repos" section; `bin/sync --install` does the per-machine
wiring (gitleaks `pre-commit` via `core.hooksPath` in each repo, the plist in
`launchd/` loaded into `~/Library/LaunchAgents`). Log:
`~/.local/state/private-sync/sync.log`.

Second machine, in order: clone the private `other` repo to `~/dotfiles/other`
(delete nothing — the outer checkout's README and templates are already
there and ignored by the clone), clone `hq` and `wiki` to `~/dev`, run
`setup.sh` (its seeding finds every live file present and creates nothing),
then `other/bin/sync --install`.

Never a credential VALUE in any of the three repos: reference the 1Password
item or the env-var name. The gitleaks hook is the backstop, not the rule.

| File | Consumed by | Purpose |
|------|-------------|---------|
| `zshrc.local` | sourced at the end of `~/.zshrc` | env vars, extra PATH, anything shell |
| `aliases.local` | sourced by `~/.zshrc` after shared aliases | machine/work-specific aliases & functions |
| `gitconfig.local` | `[include]` in `~/.gitconfig` | per-machine git identity/overrides |
| `tmux-sessionizer.local` | sourced by `bin/project-dirs-lib` (used by `bin/tmux-sessionizer` and `bin/worktrees`) | override `search_dirs` |
| `claude/settings.json` | file-symlinked to `~/.claude/settings.json` | Claude Code settings (seeded from the .example) |
| `claude/skills/`, `claude/rules/`, `claude/agents/` | dir-symlinked to `~/.claude/{skills,rules,agents}` | private Claude skills/rules/agents, plus per-item links to the tracked generic set (see below) |
| `codex/config.toml` | file-symlinked to `~/.codex/config.toml` | Codex settings, seeded from the .example — codex writes its own `[projects]` trust entries here |
| `codex/AGENTS.md` | file-symlinked to `~/.codex/AGENTS.md` | Codex global instructions (seeded from the .example); codex has no rules dir, so this is hand-written |
| `codex/skills/` | dir-symlinked to `~/.agents/skills` | private Codex skills, plus per-item links to the tracked skills named in `dots/codex/shared-skills` |
| `tmux-agent-default` | read by `bin/tmux-claude-lib` | one line, `claude` or `codex` — the agent new tmux sessions get (missing = claude) |

## Agent config: two layers, per agent

`~/.claude/{skills,rules,agents}` point at the dirs here, so anything dropped
in (by you or by a Claude session) lands in `other/` — private by default.
The generic set is tracked in `dots/claude/` and layered in by
`bin/symlink_files.sh` as relative symlinks inside these dirs
(`claude/skills/feature -> ../../../dots/claude/skills/feature`). `ls -l`
tells them apart: links are tracked, real dirs/files are private.

- Promote a private item: move it to `dots/claude/<kind>/`, re-run
  `bin/symlink_files.sh`, then commit it with the usual public-repo sweep.
- A private entry with the same name as a tracked one wins; the script warns
  and leaves it alone.
- Editing a tracked item through `~/.claude/...` edits `dots/claude/` — it
  shows up in `git status` and needs a commit.
- The links inside `other/` are relative, so the `other.tgz` migration stays
  valid; `setup.sh` recreates them anyway.

Codex works the same way one level over: `~/.agents/skills` points at
`codex/skills/` here, and the tracked skills listed in
`dots/codex/shared-skills` are layered in as relative links to the SAME
files claude uses (`codex/skills/pr -> ../../../dots/claude/skills/pr`).
`~/.codex/hooks.json` is a plain link to the tracked `dots/codex/hooks.json`
— it holds no private data, and codex asks you to trust it after every edit
(see `notes/codex.md`).

To start: `bin/seed_other.sh` copies every missing `<name>.example` to
`<name>` (never overwrites, logs created vs existing), then edit. `setup.sh`
and `bin/symlink_files.sh` both run it, so a rerun of either fills gaps.

Because the copy happens once, a default added to an `.example` later never
reaches an existing `<name>` on its own. For `claude/settings.json` the run
ends with `bin/claude-settings-check`, which lists every hook, allowlist entry
or key the example has that the live file lacks (values that legitimately
differ per machine — model, theme — are not drift). It only reports; add what
you want by hand or ask claude to. `bin/doctor` runs the same check
(`bin/seed_other.sh --check`) without seeding anything.
