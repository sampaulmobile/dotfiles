# Backlog

Working set, not a log: statuses flip in place, refs accrete on the item's
line. Every grooming pass ends by pruning `done`/`dropped` items and
committing (git history + the external tracker are the archive).

Item format:
`- [status] (altitude) blurb — refs`
- status: `inbox` | `recon` | `ready` | `in-progress` | `done` | `dropped`
- altitude: `inv` (investigation → findings doc) | `build` (one /feature) |
  `project` (needs a planning session, decomposes into builds)
- refs: findings → `recon/<slug>.md`; ticket id / issue URL once published;
  PR URL once dispatched
