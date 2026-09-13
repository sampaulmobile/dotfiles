---
name: hq
description: Dispatch a work request to the right repo(s) — resolve targets from the hq routing table (+ wiki), launch one task session per piece (usually a /feature run), track and relay results. Works from any shell; handles single- and multi-repo requests.
disable-model-invocation: true
---

Route a work request to the repo(s) that should execute it. The argument is a
free-form request; pass any /feature flags the user included (`--quick`,
`--hard`, `--best`, `--strict`, `--rounds N`, `--xhigh`, `--local`, `--go`,
`--no-workplan`; per-seat `--orchestrator=`, `--implementer=` and
`--reviewer=<model[:effort]>`) through verbatim to the dispatched invocation.

You are the DISPATCHER, not the implementer. Never execute repo work in this
session — worktree isolation, repo config, and session identity all key to
the executing session's cwd. Creating a worktree and its task session IS
dispatch mechanics and is allowed: that is all `/feature` Launch does before
it returns.

## 1. Resolve target repo(s)

- Read the routing table: `~/dev/hq/routing.md` (service → repo path, alerts
  channel, tracker, wiki pointer). If the file doesn't exist, this machine has
  no hq repo yet: STOP and tell the user to scaffold one with
  `~/dotfiles/bin/hq-init` and fill in routing rows. Never guess targets
  without a table.
- Not obvious from the table (the request names a concept rather than a
  service, spans services, or needs architecture to decompose)? Consult the
  wiki lazily: the module page a routing row points to, or start at
  `~/dev/wiki/wiki/_index/INDEX.md`.
- Still ambiguous → ASK the user. Never guess a target repo.
- Multi-repo requests: decompose FIRST into one self-contained task per repo
  (consult the wiki for relationships and ordering). You coordinate the
  pieces; no single dispatched task may span repos.

## 2. Launch a task session per piece

Before dispatching anything that touches an EXISTING PR or branch (review
fixes, rebases, follow-ups), check whether work on it is already in flight:
`bin/worktrees` lists a worktree for that branch with its PIPELINE column, and
the user may be steering an agent there. If so, do NOT launch a second run —
send the new direction to that session by name and ask it to fold the work in,
drop what the user has since overridden, and reply with the current state.
Fresh work needs no check.

Otherwise invoke `/feature` Launch here, with the target repo as `--repo=` and
this session as the reporting address:

```
/feature --repo=<repo path from the routing row> --requester=<THIS session's name> <FLAGS> <the brief below>
```

Launch makes the worktree and its tmux task session, types the Run invocation
into it, and reports the session name. It never moves your screen and never
touches an existing session.

The brief is the task text Launch passes on, and the receiving session has
none of this conversation. Every field, every time:

```
GOAL        one sentence: what is true when this is done
SCOPE       the repo; the paths it may touch, and the ones it may not
CONTEXT     pointers only (PR, issue, wiki page, file path). For multi-repo
            work: this piece's place in the whole — what the other repos are
            doing, ordering, the interface between the pieces
ACCEPTANCE  checkable lines, one per condition. State the END STATE
            ("the section has no typos or grammar errors") and any change
            the requester asked for by name. Do not state the specific
            edits the dispatcher worked out while scoping ("add the missing
            period on line 165"): deciding what to change is the run's job
            in its plan step, with the whole file in front of it. Written
            here, the dispatcher's guess becomes the standard the run is
            graded against
VERIFY      the commands to run, or the surface to verify on
FORBIDDEN   what this task must not do, beyond the global rules
FLAGS       the /feature flags to pass through verbatim. Add --go only when
            ACCEPTANCE names the specific change, not just the target: a
            task whose plan phase decides WHAT to change ("fix what you
            find") keeps the gate, however small the target. Express a
            small task through the flags the pipeline knows — --no-workplan
            (plan stays uncommitted, gate and review still run) or --quick
            (one seat, no review) — never through a FORBIDDEN line that
            fights the pipeline's defaults, such as naming the only file
            allowed to change when the pipeline commits a workplan
```

A field you cannot fill is a task you have not scoped yet — scope it here, or
ask the user, before dispatching.

## 3. Track and relay

- In-flight state comes from the FILES the pipelines write, never from this
  conversation and never from a ledger of your own: each worktree's
  `.feature/status.jsonl`, whose LAST line is that run's current
  phase/round/seat. `bin/worktrees` shows the same last line as its PIPELINE
  column; to read them directly:
  ```
  source ~/dotfiles/bin/project-dirs-lib && project_dirs
  for d in "${project_dirs_out[@]}"; do
      [[ -f "$d/.feature/status.jsonl" ]] || continue
      printf '%s\t%s\n' "$d" "$(awk '$0!=""{l=$0} END{print l}' "$d/.feature/status.jsonl")"
  done
  ```
  A `phase: gate` line means that run is waiting on the requester, not
  working: relay its digest to the user, and on a go send that go by message
  to the task session itself, which resumes at its implement step. The scan
  yields the phase, never the digest itself: for a run this session launched
  it arrived here as a message, and otherwise it is at the top of that
  worktree's `workplans/<slug>-plan.md`, or of `.feature/plan.md` when
  workplans are off.
- Relay results to the user as they land — PR URLs and summaries, not
  implementation detail.
- Multi-repo: report per-piece status; the feature is done only when every
  piece lands.
- Steering: relay user feedback onward by message to the task session,
  addressed by the name `bin/project-dirs-lib`'s `session_name_for` gives its
  worktree (`<repo-dir>_<branch-slug>`) — the same name Launch reported and
  Ctrl+F lists. If the user wants hands-on control, name that session to jump
  to (Ctrl+F).
