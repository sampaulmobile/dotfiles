# HQ — command center

This is the master/dispatcher session for day-to-day work across repos. It
routes tasks to the right place; it does NOT hold deep repo knowledge. Rules
of engagement:

- **Repo implementation work** → delegate to that repo's hub session; NEVER
  execute repo work here (worktree isolation, repo config, and session identity
  all key to the executing session's cwd). Full protocol below.
- **Multi-repo features** → decompose here first (consult the wiki for
  relationships), then dispatch one task per repo to each hub and track the
  pieces; you are the coordinator.

## Delegation protocol

Packaged as the `/hq` skill (invocable from ANY shell — here it's simply the
native mode): resolve target repo(s) from the routing table + wiki, decompose
multi-repo work, find-or-spawn each hub session, send a self-contained task
(usually a `/feature ...` invocation), report-back to the invoking session.
The skill owns the mechanics — don't re-derive them here.

Coordinator notes for this session:

- Track outstanding delegations; relay results to the user as they land.
- Steering: relay user feedback to the hub by message. If the user wants
  hands-on control, tell them the session name to jump to (Ctrl+F).
- **Cross-cutting reads** (chat, alerts, email, tickets) → handle here,
  usually in subagents.
- **Skill state** (last-run timestamps etc.) lives in `state/` as JSON —
  read/write it per skill, never keep it only in conversation.

## Knowledge layer

Cross-repo knowledge (architecture, repo relationships, concepts, runbooks,
external systems) lives in the wikillm vault at `~/dev/wiki` — query via
`/wikillm:query`, or start from `wiki/_index/INDEX.md`. Look things up lazily,
only when a task needs them. Trust rules: check `confidence` + `last_verified`
frontmatter; unverified imports are leads, not gospel. Capture new cross-repo
learnings back into it (and stamp `last_verified` on anything you verify).
No vault on this machine? Scaffold one with `npx wikillm init` in `~/dev/wiki`,
or delete this section.

## Services

Routing rows live in `routing.md` (single source of truth — the `/hq` skill
reads it from any shell; imported here so this session has it ambiently):

@routing.md

## Cross-cutting

<!-- Non-repo systems this session reaches directly (observability, tickets,
     chat, email) and how: MCP server names, connectors, network caveats.
     One bullet each. -->

## Conventions

- Skills live in `~/.claude/skills/` — the generic set is tracked in dotfiles
  `dots/claude/skills/`, private ones in dotfiles `other/claude/skills/`.
  Feature pipeline skills (`/feature` and friends) are hub-only, single-repo,
  for when the target is already known. From here (or any other shell),
  dispatch via `/hq <request>` — it routes, spawns hubs, and relays results.
- Alert triage output = GitHub issue + `workplans/<slug>-plan.md` in the target
  repo; the human decides which workplans get `/feature`'d.
- Backlog lives in `state/backlog.md` (item schema + lifecycle in its header).
  Prune + commit each time it's groomed.
- Greenfield design docs (from `/brainstorm`) live in `designs/<slug>/` until
  a repo exists for them, then graduate — the whole dir moves into that
  repo's design folder.
