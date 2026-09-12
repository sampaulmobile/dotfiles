---
name: hq
description: Dispatch a work request to the right repo hub session(s) — resolve targets from the hq routing table (+ wiki), find-or-spawn each hub, delegate the work (usually a /feature run), track and relay results. Works from any shell; handles single- and multi-repo requests.
disable-model-invocation: true
---

Route a work request to the repo hub session(s) that should execute it. The
argument is a free-form request; pass any /feature tier flags the user
included (`--quick`, `--hard`, `--best`, `--strict`, `--rounds N`, `--xhigh`,
`--local`, `--go`) through verbatim to the dispatched invocation.

You are the DISPATCHER, not the implementer. Never execute repo work in the
invoking session — worktree isolation, repo config, and session identity all
key to the executing session's cwd. (The step-2 short-circuit is not an
exception: there the invoking session IS the correct executing session.)

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

## 2. Short-circuit: already in the right hub?

If there is exactly ONE target repo and this session's cwd is that repo's hub
(the main checkout: `git rev-parse --show-toplevel` matches the routing row's
repo path, and `.git` is a directory, not a file), skip delegation and run the
task here directly — usually by invoking `/feature`. Steps 3–5 are for every
other case.

## 3. Find or spawn each hub session

- The hub is the claude session whose peer name is EXACTLY
  `<repo-dir-basename>-hub` (`routing.md` lists it as `hub`).
  new_hub_session launches it as `claude -n <basename>-hub`, so ListAgents
  shows it under that name. Other claude sessions in the same repo show up as
  auto-named `<basename>-NN` — those are NOT hubs: never dispatch to them,
  even if idle (durable repo context lives in the hub; dispatching elsewhere
  splits it and risks two sessions on one branch).
- Hub tmux session exists but no exactly-named peer (hub launched before the
  naming convention, or renamed)? Don't spawn a duplicate: ask the user to
  run `/rename <basename>-hub` in that hub's claude pane, then re-check.
- Not running? Spawn one headlessly with the standard hub layout, then
  re-check ListAgents (allow ~15s):
  `source ~/dotfiles/bin/tmux-claude-lib && new_hub_session <repo-dir-basename> ~/dev/<repo-dir> claude`
  NEVER launch claude as the tmux session command (`new-session ... claude`) —
  that bypasses zsh rc files, so env from other/zshrc.local (ANTHROPIC_MODEL,
  TLS, ...) is missing and claude comes up on the wrong model.
  new_hub_session instead types `claude` into an initialized shell, same as
  Ctrl+F, so claude starts warm in window 1.
  The third argument is the agent (`claude` or `codex`) — always pass `claude`
  explicitly: omitting it means the machine's default agent, and a codex
  session has no SendMessage/ListAgents equivalent to be dispatched to.
  Creation only — never kill or mutate existing sessions (tmux-safety rules).

## 4. Delegate

Before dispatching anything that touches an EXISTING PR or branch (review
fixes, rebases, follow-ups), assume the user may already be working it directly
in that hub. Every such dispatch must open with an in-flight check the hub
answers before acting: "If work on <PR/branch> is already in flight in your
session (e.g. the user ran /address-review or is steering an agent there),
do NOT start a second agent — fold this into the running work where it fits,
drop what the user has since overridden, and reply with the current state."
Fresh work (a new /feature) needs no check.

SendMessage each hub a SELF-CONTAINED brief — the receiver has none of this
conversation. Every field, every time:

```
GOAL        one sentence: what is true when this is done
SCOPE       the repo; the paths it may touch, and the ones it may not
CONTEXT     pointers only (PR, issue, wiki page, file path). For multi-repo
            work: this piece's place in the whole — what the other repos are
            doing, ordering, the interface between the pieces
ACCEPTANCE  checkable lines, one per condition
VERIFY      the commands to run, or the surface to verify on
FORBIDDEN   what this task must not do, beyond the global rules
FLAGS       the /feature flags to pass through verbatim (--go when the
            acceptance criteria above already settle the plan)
REPORT      the digest, then the PR URL, by SendMessage to <THIS session's
            name>
```

A field you cannot fill is a task you have not scoped yet — scope it here, or
ask the user, before dispatching.

## 5. Track and relay

- In-flight state comes from the FILES the pipelines write, never from this
  conversation and never from a ledger of your own: each worktree's
  `.feature/status.jsonl`, whose LAST line is that run's current
  phase/round/seat. `bin/worktrees` shows the same last line as its PIPELINE
  column; to read them directly:
  ```
  source ~/dotfiles/bin/project-dirs-lib && project_dirs
  for d in "${project_dirs_out[@]}"; do
      [[ -f "$d/.feature/status.jsonl" ]] || continue
      printf '%s\t%s\n' "$d" "$(tail -n1 "$d/.feature/status.jsonl")"
  done
  ```
  A `phase: gate` line means that run is waiting on the requester, not
  working: relay its digest and send the go.
- Relay results to the user as they land — PR URLs and summaries, not
  implementation detail.
- Multi-repo: report per-piece status; the feature is done only when every
  piece lands.
- Steering: relay user feedback onward by message. If the user wants hands-on
  control, name the tmux session to jump to (Ctrl+F).
