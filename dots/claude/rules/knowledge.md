# Workspace knowledge layer

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
