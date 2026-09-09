# Workspace knowledge layer

- Put knowledge at the altitude it applies to, and don't duplicate it downward.
  Workspace-wide knowledge (applies to every repo in `~/dev`) belongs in a
  global rule (`dots/claude/rules/`, always loaded), `~/dev/hq` (dispatch), or
  the `~/dev/wiki` vault (architecture/runbooks) — NOT copied into an individual
  repo's CLAUDE.md or a per-repo/project memory. A repo's CLAUDE.md holds only
  genuinely repo-specific facts; generic scaffolding belongs to built-in/`high`
  agents + skills, not bespoke per-repo agents. Duplicated workspace knowledge
  rots and drifts across repos; a single top-level source stays correct
  everywhere. Before adding cross-repo guidance to a repo's CLAUDE.md, put it
  higher up and have the repo point to it (or hold only its repo-specific
  nugget).
- Cross-repo/workspace knowledge (architecture, repo relationships, where
  infra/monitors/secrets live, cross-repo concepts, runbooks, external
  systems) lives in the wikillm vault at `~/dev/wiki`. When a question is
  about the wider system rather than the current repo's own code, consult it
  BEFORE grepping across repos: start at `~/dev/wiki/wiki/_index/INDEX.md`
  (or `/wikillm:query`), read the 1–3 relevant pages, follow `[[wikilinks]]`
  lazily. `$WORKSPACE` in wiki pages means `~/dev`.
- Trust rules: check `confidence` + `last_verified` frontmatter. Unverified
  imports are leads, not gospel — verify against the repo/live system before
  acting, then stamp `last_verified` on the page.
- Write back: when you learn or verify something cross-repo (a location, a
  rule, a gotcha), capture it in the wiki per its SCHEMA.md — edit/create the
  page, update `wiki/_index/` (INDEX + LOG entry), commit. Knowledge that
  stays only in a session dies with it.
- Day-to-day routing (which repo, alert channels, tmux sessions) is
  `~/dev/hq/CLAUDE.md`; the wiki is knowledge, hq is dispatch.
- Team-shared files never carry personal filesystem paths. A repo's CLAUDE.md,
  its docs, PR bodies and code comments are read by teammates whose machines
  differ — `~/dev/...`, `/Users/<name>/...`, `$HOME`-relative or any other
  path that only resolves on this laptop is wrong there (review feedback,
  2026-09-08). Reference the thing
  portably instead: repo-relative path, `<org>/<repo>` plus path, or a URL.
  The `~/dev/wiki` vault is PERSONAL, not a team resource — never reference
  it (by path or page name) in a repo's CLAUDE.md or docs. Local paths and
  wiki pointers are fine ONLY in these global rules, hq, and per-machine
  memory.
- Editing `~/dotfiles` from any session: confirm the diff with the user
  first, and commit on a `<type>/<slug>` topic branch — never on master. It is
  loaded into every session's prompt, so it gets a review point.
