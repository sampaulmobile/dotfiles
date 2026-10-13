# Workplan: live subagents in every agent-status screen

## Restatement (from the request alone)

- **Task:** make the one pane scan behind every status screen count each
  claude pane's live background subagents (the dashboard's `+N` definition),
  carry that count as its own field through the `sessions`/`panes`/`turns`
  snapshots, and have the sessionizer, statusbar, hq-feed and Ctrl+Y treat a
  pane with live subagents as busy rather than idle/done.
- **Done means:** a parent claude that ended its turn with background agents
  still running shows blue `+N` in Ctrl+F, `●` in the statusbar and a working
  window tint, a `+N` WORKING block in hq-feed, and no ✅ / green / Ctrl+Y
  target until its count drops to 0; the status word itself is unchanged;
  `tests/run.sh` green under both bashes with the extended suites; CLAUDE.md
  and each changed screen's legend/`--help` describe the new field.
- **Assuming:** the dashboard's count (subagent transcript mtime within
  `LIVE_AGENT_SECS`) is cheap enough to batch into the statusbar scan; the
  pane → transcript mapping can be done once per tick.

## Digest

- **Task:** `live_agent_counts` in `bin/tmux-claude-lib` — one `jq` over
  `~/.claude/sessions/*.json` (the program `build_cwd_session_map` already
  runs, shared) maps each claude pane to `<proj>/<sid>/subagents`, then ONE
  `find <dirs> -maxdepth 1 -name 'agent-*.jsonl' -mtime -$((LIVE_AGENT_SECS+1))s`
  across all panes lists the live ones; a live jsonl counts only when its
  `.meta.json` exists (as `list_session_agents` requires). `scan_agent_panes`
  gains a 6th field `agents`, `aggregate_session_status` a 4th (sum over the
  session's panes); `-` for 0, codex and unresolved panes. Every reader of
  those lines is updated, and the `turns` record carries the field after
  `status`. Screens render it; the ✅ flag is deferred at READ time.
- **Done means:** as the restatement, plus a measured scan time
  before/after (budget: the added jq + find ≤ ~35ms on this machine), and a
  live read-only `scan_agent_panes` run while an implementer subagent is
  running showing the orchestrator's pane with `agents` ≥ 1.
- **Not doing:** changing the status word; `bin/tmux-claude-dashboard`
  (keeps its own `list_session_agents` path and badge); codex subagents;
  cross-session task sessions; the cwd fallback of `find_pane_jsonl` in the
  batched count (pane-exact only — see Assumptions); the up-to-5s `done`
  window tint `flag-done` sets before the next statusbar tick corrects it.
- **Assuming:** BSD `find -mtime -<N>s` (macOS) — VERIFIED working here; GNU
  find would reject it and the count degrades to 0, not an error.
- **Surface:** `tests/run.sh` (both bashes); a read-only live
  `scan_agent_panes` + timing; `bin/hq-feed --dump` over a scratch
  `HQ_SNAPSHOT_DIR` filled by this worktree's collectors. The worktree's
  statusbar is NOT run against the live server (it set-options windows).
- **Touches:** ~9 files — `bin/tmux-claude-lib`, `bin/tmux-claude-statusbar`,
  `bin/tmux-sessionizer`, `bin/tmux-claude-attention`, `bin/hq-snapshot`,
  `bin/hq-feed`, `bin/hq-reap`, `CLAUDE.md`, 5 test suites.
- **Question:** none.

Reading the code changed: the deferral point (flag time is unworkable — see
Assumptions A3), and found two readers (`cmd_jump`, `hq-reap`) whose last
`read` variable would silently swallow a new trailing field.

## Approach

### 1. The count — `bin/tmux-claude-lib`

- Hoist the jq program in `build_cwd_session_map` into a variable (e.g.
  `_CWD_MAP_JQ`) and use it there, in the new function, and in
  `bin/hq-snapshot`'s `collect_turns` (which inlines the same program today).
- New `live_agent_counts <claude-pane-ids>` (newline-separated `%N` ids).
  Sets a global (e.g. `LIVE_AGENTS_OUT`, leading-newline
  `"\n%N\t<count>\n..."`, only panes with count > 0) — no subshell, so the
  scan calls it without a fork of its own. Steps:
  1. return at once (zero forks) when no pane ids are given;
  2. one `jq -r "$_CWD_MAP_JQ" "$CLAUDE_SESSIONS_DIR"/*.json`; for each pane,
     the FIRST row whose pane field matches (same first-match semantics as
     `_pane_exact_jsonl`), dir =
     `$CLAUDE_PROJECTS_DIR/${cwd//[\/._]/-}/$sid/subagents` (the bash form of
     `encode_cwd`'s sed, verified equal under /bin/bash 3.2); keep it when
     `[[ -d ]]`;
  3. no dirs → return; else ONE `find "${dirs[@]}" -maxdepth 1 -name
     'agent-*.jsonl' -mtime -$(( LIVE_AGENT_SECS + 1 ))s` (BSD: strictly less
     than N seconds, i.e. `now - mtime <= LIVE_AGENT_SECS`, the dashboard's
     test);
  4. per printed path: skip unless `${path%.jsonl}.meta.json` exists
     (`[[ -f ]]`, fork-free); attribute to every pane whose dir equals
     `${path%/*}`. Bash 3.2: no mapfile, no associative arrays — parallel
     indexed arrays + prefix stripping, like `aggregate_session_status`.
  A comment at the function states the shared definition: live =
  `LIVE_AGENT_SECS`, meta required, i.e. the dashboard's `+N`.
- `scan_agent_panes`: collect the claude panes' ids from `targets`, call
  `live_agent_counts` once before the print loop, print a 6th field
  `agents` (`-` when absent/0; codex always `-`). Update its header comment.
- `aggregate_session_status`: read the 6th field, output
  `<session>\t<status>\t<pane>\t<agents>` (sum over the session's panes,
  `-` when 0). Status/pane selection unchanged.
- `window_status_from_panes`: read the 6th field; a pane with agents > 0
  counts as `working` unless it is `permission`. Output unchanged.
- New pure, fork-free `drop_deferred_flags <flag-lines> <pane-lines>`:
  `<flag-lines>` are `<session>\t<pane>` (what `attention list` prints);
  prints those whose pane does NOT carry agents > 0 in `<pane-lines>`
  (scan format). Per pane, never per session.

### 2. Readers of the scan/sessions lines (every one must take the field)

Each `read -r ... last` whose last variable would absorb `\t<agents>`:
- `bin/tmux-claude-attention` `cmd_jump`: `read -r session st pane` → add a
  trailing `_` (pane would otherwise become `%N\t-` and break the switch).
- `bin/hq-reap` `reap_pane_facts` (`read -r s p _w _a st`): add the field;
  a pane with agents > 0 sets `reap_bad_status_out` (e.g. `agents`) so a
  claude with running subagents is never parked/killed. `--help` tiers line
  updated.
- `bin/hq-snapshot` `turns_rows`: read the 6th field; the turns record becomes
  `session pane window agent status agents name mtime jsonl kind prompt from
  reply tool pending cwd` (16 fields; agents `-` for 0/codex). Shift the awk
  mtime gate's indices (`pf[8]`/`pf[9]` compare, reuse `pf[10..15]`) and the
  REUSE/PARSE re-reads. The agents value always comes from the CURRENT pane
  body, never from the reused previous record. Update the function header,
  `collect_panes`/`collect_sessions` comments and the `--help` source lines.
- `bin/tmux-claude-statusbar`: `working_count` counts a session whose status
  is working, OR idle/unknown with agents ≠ `-`. Header legend: `●` also
  covers sessions with live subagents.
- `bin/tmux-sessionizer` (see 4).
- Implementer greps `bin/` and `tests/` for any other reader
  (`snapshot_read sessions|panes`, `scan_agent_panes`, `scan_claude_sessions`,
  `aggregate_session_status`) and fixes it the same way.

### 3. Done-flag deferral — read time (Assumption A3)

- `bin/tmux-claude-attention cmd_list`: after building its output, when at
  least one flag survived, source `bin/hq-snapshot` (or source it at the
  top — its reader half is side-effect free) and, if the `panes` snapshot is
  `fresh`, pipe through `drop_deferred_flags`; stale/missing → no filter
  (fail open: a flag still shows). Covers the statusbar's ✅ count, its
  `done` window tint (`window_status_from_panes` is fed `list`), and Ctrl+Y
  (`cmd_jump` → `cmd_list`). The flag FILE is untouched: it stays on disk
  and surfaces once the count reads 0. `cmd_list` keeps no-flag ticks free of
  any snapshot read. Update the attention header's `list` line.
- `bin/tmux-sessionizer`: drop flags the same way using the fresh `panes`
  snapshot (see 4).
- `bin/hq-feed`: the bucket order makes it moot (WORKING before DONE when
  agents > 0); no flag filtering needed.

### 4. Screens

- **Sessionizer.** Extract the status-list build into a pure function
  defined ABOVE the `BASH_SOURCE` guard (line ~97) so
  `tests/test-session-order.sh` can call it: inputs = sessions snapshot body,
  flag keys (`<session>@<pane>` from the glob), panes snapshot body (empty
  when not fresh); outputs the four lists plus a badge list
  (`<session>\t<N>`). Rules: permission → red; a flag whose pane has no live
  agents → green; status working OR agents > 0 → blue; else idle → dim blue.
  `emit_rows` appends ` +N` to the DISPLAY field (never the key field) for a
  session with agents. Header legend: blue covers live subagents, `+N` badge.
  The no-scan-at-keypress invariant holds: both inputs are snapshot reads.
- **Statusbar.** As in 2, plus the window option via
  `window_status_from_panes` (1).
- **hq-feed.** `load_data` takes the new header field (jq indices shift:
  prompt..pending `$f[10..14]`, cwd `$f[15]`, agents `$f[5]` into the H
  line); `p_agents` array. `feed_bucket <status> <done> <agents>`:
  permission → NEEDS YOU; agents > 0 → WORKING; flag → DONE; working →
  WORKING; else IDLE. The block header's status reads `● working +N <age>`
  (badge inside `status_plain` so the width math counts it); DETAIL's header
  the same if it renders the status. `--help`: WORKING = status working or
  live subagents (`+N`).
- **Ctrl+Y.** Covered by `cmd_list` (3) and the `cmd_jump` read fix (2).

### 5. Docs

`CLAUDE.md`: the statusbar bullet (`sessions` record
`<session>\t<status>\t<pane>\t<agents>`, `panes` record = scan line with
`agents`), the `bin/hq-feed` bucket line, the sessionizer row colours if
stated, `bin/hq-snapshot`'s `turns` line if it names fields, hq-reap's
never-a-candidate list. One home per fact: formats live at the code; CLAUDE.md
names the field and stops.

## Test plan (extend existing suites; no tmux server)

- `tests/test-window-status.sh`: scan-line fixtures gain the 6th field;
  `aggregate_session_status` sums agents (`-` for 0) and keeps status/pane;
  `window_status_from_panes` turns idle+agents into working, permission still
  wins; `drop_deferred_flags` keeps a flag on an agent-free pane of the same
  session and drops the one on the agent pane; `live_agent_counts` over a
  `mktemp -d` fixture (`CLAUDE_SESSIONS_DIR`/`CLAUDE_PROJECTS_DIR` pointed at
  it): fresh agent with meta counts, fresh without meta does not, one
  `touch -t`'d 10 minutes old does not, an unmapped pane gets nothing.
- `tests/test-hq-snapshot.sh`: turns record carries `agents` after
  `status`; a REUSE row takes the current pane body's agents, not the
  previous record's.
- `tests/test-session-order.sh`: the extracted sessionizer function — agents
  session blue with `+N`, deferred flag not green, a flag on another pane of
  the same session still green.
- `tests/test-hq-feed.sh`: bucket table (agents → WORKING over DONE and
  IDLE; permission still NEEDS YOU); a `--dump` fixture block header shows
  `+N`; fixture turns records gain the field.
- `tests/test-hq-reap.sh`: if its fixture shape allows it cheaply, an idle
  pane with agents is not a candidate; otherwise verify by reading.
- `tests/run.sh` green under both bashes.

## Assumptions

- **A1 VERIFIED** — every live claude pane on this machine resolves
  pane-exactly: all 13 claude panes from `scan_agent_panes` appear in the
  sessions-JSON `tmux` map (Claude Code 2.1.280). So the batched count skips
  `find_pane_jsonl`'s cwd fallback (a `tmux display` + `ls` per pane, which
  would break the budget); a pane with no session-JSON entry reads `-`.
- **A2 VERIFIED** — cost: the jq over 13 session files measured ~24ms, the
  `find` over 3 subagent dirs ~4ms. The existing scan measured 250–330ms here
  (already above the stated 200ms; not this change's to fix).
- **A3 (decision) — deferral at READ time, not flag time.** The Stop hook
  fires when the parent ends its turn; a background agent finishing makes the
  parent take another turn and Stop again within seconds — but the finished
  agent's transcript was written within `LIVE_AGENT_SECS`, so a flag-time
  check would still read count ≥ 1 and suppress the flag again, and nothing
  would ever flag the pane. Filtering at read time (`attention list` + the
  sessionizer) against the per-pane `panes` snapshot lets the flag surface on
  the first tick after the count reaches 0, costs nothing when no flag
  exists, and fails open when the snapshot is stale.
- **A4 VERIFIED** — BSD `/usr/bin/find` accepts `-mtime -121s`. ASSUMED that
  these scripts only run on macOS; on GNU find the count is 0.
- **A5 ASSUMED** — `-mtime -(N+1)s` equals the dashboard's
  `now - mtime <= N` for integer mtimes. Verified by the fixture test's
  fresh/old cases, not at the 1-second boundary.
- **A6 (decision)** — hq-reap treats agents > 0 as not-a-candidate: it reads
  the same line and must change anyway; parking a claude whose subagents are
  writing would kill their parent.
