# Workplan: agent trees in tmux-claude-dashboard

## Goal

Extend `bin/tmux-claude-dashboard` (Ctrl+G) so each Claude session row can
expand into a tree of its live subagents, giving one screen that shows
everything running: sessions AND the agents inside them, with per-agent
label, model/effort, token usage, age, and a snippet of current activity.

## Background: where the data lives (verified against Claude Code v2.1.258)

For a session whose transcript is `~/.claude/projects/<proj-key>/<sid>.jsonl`
(the dashboard already resolves this via `find_session_jsonl` in
`bin/tmux-claude-lib`), its subagents live at:

```
~/.claude/projects/<proj-key>/<sid>/subagents/
  agent-<id>.jsonl        # the agent's transcript (same format as sessions)
  agent-<id>.meta.json    # spawn metadata
```

`meta.json` fields (all observed, treat missing keys as optional):
- `agentType` — the agent definition name (e.g. `sonnet-high`, `fable-high`,
  `general-purpose`). For our presets this encodes model AND effort.
- `description` — the short spawn label ("Implement round 1"). Use as the row title.
- `parentAgentId` — present when the agent was spawned by another agent;
  its value matches the parent's `agent-<id>` stem. Absent → child of the
  session's main conversation.
- `spawnDepth` — integer nesting depth; use for indentation.
- `spawnedWithWorktree` / `inheritedWorktreePath` — optional worktree info.

Agent transcript (same JSONL schema as a session transcript):
- Records with `.type == "assistant"` carry `.message.model` (model id) and
  `.message.usage` (`input_tokens`, `output_tokens`,
  `cache_read_input_tokens`, `cache_creation_input_tokens`). Context size of
  the LAST assistant record ≈ `cache_read + cache_creation + input`.
  The existing `get_context_and_model` in tmux-claude-lib already computes
  this for session JSONLs — reuse it unchanged on agent JSONLs.
- Activity snippet: the last `.message.content[] | select(.type=="text") |
  .text` across assistant records; fall back to meta `description`.

Liveness heuristic (v1): an agent file with mtime within the last 2 minutes
renders as working (●); older renders as done/idle (◯) with its age; hide
agents whose mtime is older than 30 minutes (tunable constants at top of the
lib). This mirrors how the harness's own panel presents recency and avoids
parsing completion records in v1.

## Files to touch

- `bin/tmux-claude-lib` — new functions (keep the existing style: plain bash +
  jq, per-file mtime caching like `get_totals_incremental`):
  - `list_session_agents <sid-jsonl-path>` → emits one line per agent under
    that session (agent-id, depth, parent-id, agentType, description, mtime)
    sorted for tree rendering (parents before children).
  - `get_agent_stats <agent-jsonl>` → context tokens, output tokens, model
    (reuse `get_context_and_model` + `format_tokens` / `short_model`).
  - `get_agent_snippet <agent-jsonl> <maxlen>` → last assistant text,
    single-line, truncated; jq on `tail -c 65536` of the file for speed.
- `bin/tmux-claude-dashboard` — rendering + interaction:
  - Under each session row, when expanded, indent agent rows by `spawnDepth`:
    `  └ ● <description> · <agentType> · ctx <N> · <age> · "<snippet>"`.
  - Snippet consumes remaining terminal width (existing responsive-column
    logic applies; drop the snippet first, then agentType, when narrow).
  - Session rows gain a live-agent badge (e.g. `⛁2`) when agents are working.
  - New key: `a` toggles agent expansion (global). Sessions with ≥1 working
    agent auto-expand. Update the in-dashboard help line.
- `CLAUDE.md` (repo) — update the tmux-claude-dashboard bullet: new key and
  what the tree shows.

## Ordered steps

1. Lib: implement + unit-smoke the three functions against a real session dir
   (any `~/.claude/projects/*/<sid>/subagents/` with files works; create a
   fixture from a copied sanitized sample if none exists at test time).
2. Dashboard: render trees behind the `a` toggle; badge on session rows.
3. Responsive behavior: verify at 80/120/200 columns (snippet truncation,
   column dropping); keep refresh latency acceptable (agent parsing must use
   the same mtime-cache pattern as token totals — no full-file re-reads on
   every refresh tick).
4. Keys/help/CLAUDE.md doc updates.
5. Manual test matrix (see below), then `/pr`.

## Test plan

- With no agents running: dashboard renders exactly as today; `a` shows
  nothing extra; no latency regression.
- With one session running nested agents (spawn any background task): tree
  shows correct nesting (parentAgentId honored), labels, model via agentType,
  context tokens ≈ what the in-session panel shows, live snippet updates
  across refreshes.
- Stale agents (>30 min) disappear; 2–30 min agents show ◯ + age.
- Narrow terminal: no wrapped/garbled rows.
- Sessions whose CWD is gone ("✗ gone") unaffected.

## Out of scope

- Acting on agents (kill/steer) — v1 is read-only observation.
- Historical/completed-run archaeology; only recent agents render.
- Cross-machine/cloud sessions (`claude agents` covers those).
- Format-drift resilience beyond v2.1.258: the transcript/meta formats are
  internal; this repo pins claude-code and re-verifies parsing on deliberate
  upgrades. Guard every jq with fallbacks so unknown records degrade to
  blank fields, never crashes.

## Public-repo caution

This repo is public: keep all fixtures/examples generic (no employer names,
no real repo names, no transcript content copied verbatim into tests).
