# other/ — machine-local config

Everything machine-specific or private lives here, in one place, so it's easy
to see, back up, and migrate (e.g. `tar czf other.tgz other/` + AirDrop when
setting up a new machine). Only this README and the `*.example` templates are
tracked — the real files are gitignored and never leave the machine.

| File | Consumed by | Purpose |
|------|-------------|---------|
| `zshrc.local` | sourced at the end of `~/.zshrc` | env vars, extra PATH, anything shell |
| `aliases.local` | sourced by `~/.zshrc` after shared aliases | machine/work-specific aliases & functions |
| `gitconfig.local` | `[include]` in `~/.gitconfig` | per-machine git identity/overrides |
| `tmux-sessionizer.local` | sourced by `bin/tmux-sessionizer` | override `search_dirs` |
| `claude/settings.json` | file-symlinked to `~/.claude/settings.json` | Claude Code settings (seeded from the .example) |
| `claude/skills/`, `claude/rules/`, `claude/agents/` | dir-symlinked to `~/.claude/{skills,rules,agents}` | private Claude skills/rules/agents, plus per-item links to the tracked generic set (see below) |

## Claude config: two layers under one `~/.claude`

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

To start: `bin/seed_other.sh` copies every missing `<name>.example` to
`<name>` (never overwrites, logs created vs existing), then edit. `setup.sh`
and `bin/symlink_files.sh` both run it, so a rerun of either fills gaps.
