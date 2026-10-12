# Workplan: reap finished pipeline sessions

## Restatement (from the request alone)

- **Task:** stop finished `/feature` task sessions from accumulating as resident
  claude processes: kill the tmux session of one whose PR is merged/closed, and
  end (park) the claude of a done one whose PR is still open after a long idle,
  resumable on the next visit.
- **Done means:** one script with a dry-run default and `--apply`, driven
  automatically by the statusbar tick's due-gating, logging every kill/park
  append-only under `~/.local/state/hq`; visiting a parked session resumes its
  claude by name; Ctrl+G shows parked sessions distinctly; the feature and hq
  skills describe the lifecycle.
- **Assuming:** a task session is recognisable from tmux/process state; PR state
  is already collected (the worktrees snapshot) so no new gh calls are needed.

## Digest

- **Task:** new `bin/hq-reap`: tier 1 kills a task session whose worktree's PR
  is MERGED/CLOSED (clean, pushed, no busy pane); tier 2 parks (SIGTERMs the
  claude, keeps session/shell/worktree) a phase-done task session with an OPEN
  PR idle ≥12 h. Dry-run default, `--apply`, `resume <session>`; spawned by
  `hq-snapshot tick` when due (every 2 min).
- **Done means:** dry run on this machine lists plausible verdicts and kills
  nothing; tier rules pinned by an offline decision-table test; a parked
  session's claude restarts (`claude --resume '<name>' [--model --effort]`) on
  Ctrl+F, wt-tmux-jump, Ctrl+G ⏎ or `hq-reap resume`; Ctrl+G lists it as
  `◌ parked <age>`; kills/parks appended to `~/.local/state/hq/reap/log.tsv`.
- **Not doing:** removing worktrees or any file; a tmux hook (the three entry
  points call one lib function instead, so no live config reload is needed);
  reaping codex or multi-agent sessions; a kill switch beyond removing the
  tick line.
- **Assuming:** SIGTERM ends Claude Code cleanly leaving the pane's shell at a
  prompt (verified only on a throwaway socket with a stand-in process, not on
  a real claude); `claude --resume <name>` keeps the `-n` peer address (the
  lib's own comment and the hubs' `--resume <name>` say so).
- **Surface:** `bin/hq-reap` dry run against the live machine (read-only);
  `tests/run.sh`; shellcheck; `bin/doctor`; a park/resume round trip on a
  `tmux -L reap-verify-$$` socket run by hand (not in the suite).
- **Touches:** ~9 files — new `bin/hq-reap`, `tests/test-hq-reap.sh`;
  `bin/hq-snapshot` (tick spawn + header), `bin/tmux-claude-lib`
  (`unpark_session`), `bin/tmux-task-session` (`@task` mark),
  `bin/tmux-sessionizer`, `bin/wt-tmux-jump`, `bin/tmux-claude-dashboard`,
  CLAUDE.md, the feature and hq skills.
- **Question:** none.

Reading the code changed: a parked session has no agent pane, so Ctrl+G would
simply drop it — parked rows must be added from tmux session options, not
from the agent scan. And `hq-reap resume` lets a hub wake a parked session
itself, so "needs a visit before a message reaches it" becomes "needs a visit
or `hq-reap resume`".

## Goal

Finished pipelines stop holding memory. Twelve idle task-session claudes held
~5 GB on 2026-10-12. Phase `done` alone is never a trigger: a done run still
receives hub corrections and `/address-review`, and waits days on the owner's
merge.

## Approach

### Which sessions are candidates (both tiers)

A tmux session is a **task session** when its `@task` session option is set
(new: `tmux-task-session` sets it at creation) or, for sessions launched before
this change, a claude on one of its panes has `/feature --run` in its process
arguments (one `ps -A -o tty=,pid=,args=`). It is **tied to a worktree** when
its name equals `session_name_for <path>` of a row in the `worktrees` snapshot
(linked worktrees only — a main checkout is never a row, so hub sessions can
never match). Never a candidate, either tier:

- not a task session, or not tied to a worktree row;
- attached (`#{session_attached}` > 0) — someone is looking at it;
- any agent pane in it `working`, `permission` or `unknown` (live
  `scan_agent_panes`, never a snapshot);
- any non-agent pane running something other than a shell or an editor
  (`#{pane_current_command}` ∉ zsh/bash/sh/fish/nvim/vim/vi, leading `-`
  stripped) — a dev server or test run is work in flight.

### Tier 1 — kill

The worktree row's facts, classified by `bin/worktrees`' own
`classify_worktree false <dirty> false <pr_state> <unpushed> <merged_local>`
(liveness and prunable forced false — the session IS the liveness):

- `MERGED` and `sweep_is_removable MERGED …` (merged locally, or the merged
  PR's head is the worktree HEAD, or nothing ahead of origin) → **kill**;
- `ABANDONED` (PR CLOSED) and (not unpushed, or PR head == worktree HEAD) →
  **kill**;
- `DIRTY` or anything else → keep.

Action: `tmux kill-session -t "=<name>"`. The worktree is untouched.

### Tier 2 — park

PR `OPEN` (the row's `pr_state`), the pipeline's last `status.jsonl` phase is
`done` (`pipeline_state <path>`, live file read), exactly one agent pane and it
is a claude at `idle`, and the newest of (that claude's transcript mtime,
`#{session_last_attached}`) is ≥ 12 h ago (`HQ_REAP_PARK_SECS`, default 43200).
No transcript found → keep (activity unknown).

The claude's pid and name come from `~/.claude/sessions/*.json` (one jq: the
`tmux` field's `%pane`, `pid`, `name`, `sessionId`, `cwd`); the transcript is
`~/.claude/projects/<encode_cwd cwd>/<sessionId>.jsonl`. Before acting, the pid
must still be a claude on that pane's tty (`ps -p <pid> -o tty=,comm=`), so a
recycled pid is never signalled.

Action: `kill -TERM <pid>`, then set session options `@task 1`,
`@parked <epoch>`, `@parked_pane <%id>`, `@parked_cmd "claude --resume
'<name>'[ --model M][ --effort E]"` (model/effort parsed from the claude's
args, so the orchestrator seat does not fall back to settings.json).

### Resume

`unpark_session <session>` in `bin/tmux-claude-lib`: one
`display -p -t <session> '#{@parked_pane}\t#{@parked_cmd}'`; empty → return
(the cost every non-parked visit pays). Otherwise, if the pane exists and its
tty has no agent (`agent_ttys`), `send-keys -t <pane> <cmd> Enter`; then unset
the three `@parked*` options either way. Called from the sessionizer and
wt-tmux-jump on their existing-session branch, from Ctrl+G's ⏎, and by
`hq-reap resume <session>` (what a hub runs before messaging a parked session).

### Driver and log

- `hq-snapshot` (sourceable half) gains `REAP_DIR`
  (`~/.local/state/hq/reap`, `HQ_REAP_DIR` overrides) and `REAP_CADENCE=120`;
  its `tick` spawns `bin/hq-reap --apply` detached when
  `$REAP_DIR/last-run` is older than the cadence. hq-snapshot itself still
  kills and removes nothing; its header and `--help` say what it spawns.
- `hq-reap --apply` takes a `lockf -k -s -t 0` lock (a second run exits at
  once), `touch`es `last-run`, and refuses to act on a `worktrees` snapshot
  that is not fresh (it recollects once first, as Ctrl+G does for pipelines).
- Every kill/park appends `<iso>\t<kill|park>\t<session>\t<worktree>\t<pr>\t<reason>`
  to `$REAP_DIR/log.tsv`. Nothing under `~/.local/state/hq` is removed.

### Output

Dry run prints one line per task session tied to a worktree: `KILL`, `PARK` or
`KEEP` with session, PR, phase, idle age and the reason; non-task sessions are
not listed. Exit 0. `--apply` prints what it did; exit 2 if any action failed.

### Ctrl+G

`reload_sessions` appends one row per session whose `@parked` is set (one
`list-sessions -F`), agent `parked`, pane `@parked_pane`. `load_data` skips the
stats/capture for it and records `st=parked`, `mtime=@parked`; render shows
`◌ parked <age>` in a dim colour. ⏎ on it runs `unpark_session` then switches.

## Files

- `bin/hq-reap` (new) — classification, dry run, `--apply`, `resume`.
- `bin/hq-snapshot` — `REAP_DIR`, `REAP_CADENCE`, tick spawn, header/usage.
- `bin/tmux-claude-lib` — `unpark_session`.
- `bin/tmux-task-session` — `set-option -t <name> @task 1` after creation.
- `bin/tmux-sessionizer`, `bin/wt-tmux-jump` — call `unpark_session`.
- `bin/tmux-claude-dashboard` — parked rows, ⏎ unparks, status legend.
- `tests/test-hq-reap.sh` (new) — offline decision table and arg parsing.
- `CLAUDE.md` — an `hq-reap` bullet; hq-snapshot bullet notes the spawn.
- `dots/claude/skills/feature/SKILL.md` (requester side), `dots/claude/skills/hq/SKILL.md`.

## Steps

1. `bin/hq-reap` with pure halves split out: `reap_decide` (facts → `kill` /
   `park` / `keep <reason>`), `reap_resume_cmd` (ps args + name → command),
   `reap_is_task_args`, `reap_busy_command`. Sourceable, no side effects when
   sourced.
2. Tests for those pure halves, offline.
3. `unpark_session`; wire sessionizer, wt-tmux-jump, dashboard ⏎; `@task` in
   tmux-task-session.
4. Dashboard parked rows.
5. hq-snapshot tick spawn.
6. Docs: CLAUDE.md, both skills.
7. Verify (below).

## Test plan

- `tests/test-hq-reap.sh`: every keep reason and both actions from the decision
  table (attached, not task, no row, busy pane, working/permission/unknown
  agent, dirty, unpushed-but-PR-head-matches, CLOSED unpushed, OPEN not done,
  OPEN done idle 11 h vs 13 h, two agent panes, no transcript); resume command
  from real-shaped args with and without model/effort; task-args detection.
- `tests/run.sh` under both bashes; `shellcheck` on every touched script.
- `bin/hq-reap` dry run on the live machine: read-only, prints verdicts.
- By hand, recorded in NOTES.md, never in the suite (the suite starts no tmux
  server): a park/resume round trip on `tmux -L reap-verify-$$` with a
  stand-in process instead of claude and `@parked_cmd` set to an `echo`,
  then `tmux -L reap-verify-$$ kill-server`.
- `bin/doctor`.

## Out of scope

- Worktree removal (that stays `worktrees sweep`).
- Codex sessions, sessions with more than one agent pane (kept, with a reason).
- A `client-session-changed` hook in tmux.conf.

## Assumptions

- VERIFIED: the worktrees snapshot carries `pr_state`, `pr_head`, `wt_head`,
  `merged_local`, dirty/unpushed flags and the path for every linked worktree,
  LIVE ones included (live `~/.local/state/hq/snapshot/worktrees.tsv`: a LIVE
  row shows `PR #202 MERGED`).
- VERIFIED: task-session claudes carry `-n <session> … /feature --run` in their
  process args; hubs run `claude -n <x>-hub` or `claude --resume <x>-hub`
  (`ps -A -o args=` on this machine, 2026-10-12).
- VERIFIED: `~/.claude/sessions/<pid>.json` records `pid`, `name`,
  `sessionId`, `cwd` and `tmux` (`<session>:@win.%pane`) per claude (read one).
- VERIFIED: pane commands read `claude.exe`, `nvim`, `zsh` in the standard
  layout (`list-panes -a -F '#{pane_current_command}'`).
- VERIFIED: `tmux-claude-attention list` filters to live panes, so a killed
  session's leftover `.done` flags do not inflate the ✅ count (its usage text).
- ASSUMED: Claude Code exits on SIGTERM and the pane returns to its shell.
  Verify: the first real park. A claude that ignored TERM would leave an idle
  row beside the parked one in Ctrl+G; `unpark_session` then finds an agent
  on the tty and only clears the mark, typing nothing.
- ASSUMED: `claude --resume '<name>'` resumes the newest transcript of that
  name and keeps it as the peer address. Verify: the first resume.
- ASSUMED (judgment): the sessions-launched-before-this-change fallback
  (`/feature --run` in args) is wanted so today's sessions are reapable
  without a relaunch.
