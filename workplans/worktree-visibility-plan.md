# Workplan: worktree visibility — agent worktrees in Ctrl+F, plus a read-only worktree doctor

## Goal

Agent-created worktrees (`<repo>/.claude/worktrees/agent-<id>/`, made by the
Agent tool's worktree isolation and by EnterWorktree — i.e. every `/feature`
run) are invisible today: the sessionizer never lists them, nothing reports
them, and the harness only deletes the ones with no commits. They pile up
silently (a dozen across the machine at the time of writing, all finished,
several with merged PRs, one holding never-pushed work).

Two independent parts, one plan:

- **Part A — Ctrl+F lists them.** The sessionizer enumerates agent worktrees
  (and, for single-repo `depth 0` entries like dotfiles, their worktrunk
  siblings) as project rows, named by repo + branch, so a parked worktree is
  discoverable the same way any project is.
- **Part B — `bin/worktree-doctor`.** A read-only report in the spirit of
  `bin/doctor`: every worktree of every project the sessionizer knows about,
  classified into a state bucket, with the recommended action and the exact
  command that performs it. It changes NOTHING. Sweeping/deletion is a later,
  separate operation; `/feature` stays implementation-only and never removes
  worktrees.

Decisions already made (do not re-open):
- One source of truth for "which directories are projects": the sessionizer's
  `search_dirs` (defaults + the `other/tmux-sessionizer.local` override, which
  may redefine the array entirely). The doctor does NOT re-declare the list;
  both consume one shared enumeration function.
- Separate script from `bin/doctor` (different question, different cadence);
  not a doctor section.
- Part B is read-only in v1. No `--fix`, no prompts, no deletion.
- Liveness comes from consumer evidence (a live process whose cwd is inside
  the worktree), never from the git lock file or mtimes. The harness's lock
  reason names the *spawning hub session's* pid, which typically outlives the
  agent by days.
- PR state comes from `gh`, not `git branch --merged` (squash merges make a
  merged branch look unmerged to git).

## Design

### Shared enumeration: `bin/project-dirs-lib`

New sourceable bash lib (no side effects on source beyond defining
functions/defaults; bash 3.2-compatible — no `mapfile`, no assoc arrays, no
`${var,,}`; the sessionizer's hot path must stay fork-free).

- Owns the `search_dirs` defaults (moved verbatim from the sessionizer,
  `"path:depth"` entries) and the sourcing of
  `$HOME/dotfiles/other/tmux-sessionizer.local`. The `.local` contract is
  unchanged: it may redefine `search_dirs` entirely. Update the wording of
  `other/tmux-sessionizer.local.example` to say it is sourced by the shared
  lib (sessionizer + worktree-doctor), not just the sessionizer.
- `project_dirs` — fills a global array `project_dirs_out` (bash 3.2: no
  nameref) with every project directory, in this order per `search_dirs`
  entry:
  1. the entry itself (depth 0) or its immediate children (depth 1) — as
     today;
  2. legacy `.bare/` containers expanded into their worktree children — as
     today;
  3. **new:** for every candidate that is a git repo, its agent worktrees:
     glob `<cand>/.claude/worktrees/*/`;
  4. **new:** for depth-0 entries only, worktrunk siblings: glob
     `<entry>.*/` and keep only linked worktrees (`.git` is a FILE), so
     `~/dotfiles.bak`-style directories are not picked up. Depth-1 entries
     need nothing: their siblings are already plain depth-1 rows.
  Pure globs + `[[ -f ]]`/`[[ -d ]]` tests; zero forks.
- `worktree_branch <path>` — fork-free branch lookup for a linked worktree:
  read the `.git` file (`gitdir: <admin-dir>`), read `<admin-dir>/HEAD`,
  strip `ref: refs/heads/`. Detached HEAD → empty. Sets global
  `worktree_branch_out`. Used for naming and display; the doctor may use git
  directly instead (not a hot path).
- `session_name_for <path>` — moved here from the sessionizer (same
  contract: sets global `session_name`), with one new case: a path under
  `<repo>/.claude/worktrees/` names the session `<repo>_<branch>` where the
  branch has `/` → `-` (matching worktrunk's `sanitize`, so an agent worktree
  and a `wt switch -c` sibling for the same branch get the same session name)
  and then the usual `.` → `_`. Detached HEAD falls back to
  `<repo>_<basename>`. Legacy `.bare/` and plain-basename cases unchanged.

Consumers: `bin/tmux-sessionizer`, `bin/worktree-doctor`, and the two
worktrunk hooks `bin/wt-tmux-jump` / `bin/wt-tmux-cleanup`, which today derive
the tmux session name with their own `basename | tr . _` — switch both to
`session_name_for` so that `wt remove` on an agent worktree kills the session
Ctrl+F created for it (otherwise the basename-derived name misses and the
session leaks). `wt-tmux-cleanup`'s hub lookup (`$HOME/dev/$repo`) stays as is.

### Part A — sessionizer changes (`bin/tmux-sessionizer`)

- Source `bin/project-dirs-lib`; delete the local `search_dirs`, `.local`
  sourcing, `session_name_for`, and the candidate loop; call `project_dirs`.
  Behavior for every existing row kind must be byte-identical.
- **Row display for worktree rows.** The current fzf rows are the raw value
  the script maps back (a session name, or a `~/`-shortened path). An agent
  worktree path (`~/proj/.claude/worktrees/agent-a1b2c3…`) is unreadable, so
  rows become two tab-separated fields: `<key>\t<display>`, with fzf
  `--delimiter '\t' --with-nth 2` and `--preview '… {1}'`; the selection
  parser takes field 1 (`${selected%%$'\t'*}`). Key stays exactly what it is
  today (session name or path) so the mapping code below fzf is untouched.
  Display:
  - session rows and plain dir rows: unchanged text and colors;
  - linked-worktree dir rows (agent AND worktrunk siblings): the
    `~`-shortened repo path, then the branch, e.g.
    `~/proj  ⎇ feature/x`, in the existing cyan linked-worktree tint;
    agent worktrees add a dim `agent` tag so you can tell the two origins
    apart. Existing linked-worktree rows (depth-1 siblings) get the same
    treatment — one code path for "row is a linked worktree".
  - `parse_fzf_expect` unchanged (it splits key line vs. selection); the tab
    split happens after it.
- Rows of worktrees that already have a session show as session rows, as
  today, because `session_name_for` now yields the name Ctrl+F would create.
- Ephemerality caveat, documented not solved: the harness may remove an
  unchanged worktree after its agent exits, and `wt remove` removes any; a
  tmux session pointing at the vanished directory then shows as `✗ gone` in
  the dashboard and `X` prunes it. No new handling.

### Part B — `bin/worktree-doctor`

Read-only. `set -uo pipefail` (NOT `-e`: a repo that errors must not abort the
report; and never `| head`/`| tail` on the git/gh calls — see the
output-truncation rule). Exit 0 when nothing is removable, 1 when at least one
worktree is in a removable bucket (MERGED/ABANDONED/PRUNABLE) — the same
"exit 1 = something to act on" convention as `bin/doctor`.

Flow:
1. `source bin/project-dirs-lib`; `project_dirs`; keep the candidates that are
   *main* worktrees (`.git` is a directory) — these are the repos. Dedupe.
2. Once: `lsof -d cwd -Fpn` → the set of live cwd paths (Unix only; when
   `lsof` is missing, liveness is `unknown` and the report says so in its
   footer).
3. Per repo: `git -C <repo> worktree list --porcelain` — authoritative,
   catches agent dirs, siblings, hand-made worktrees anywhere, and
   `prunable` entries. Skip the main worktree line. Per worktree collect:
   - path, branch (or `detached`), `locked` reason if present (shown as a
     flag, never used for decisions);
   - `dirty`: `git -C <wt> status --porcelain` non-empty (untracked included;
     `.feature/` is already in `info/exclude` so it does not count);
   - `unpushed`: no `origin/<branch>`, or `rev-list origin/<branch>..HEAD`
     > 0;
   - `merged_local`: `git -C <repo> merge-base --is-ancestor HEAD <default>`
     where default = `origin/HEAD` symbolic-ref, falling back to
     `main`/`master`;
   - `pr`: `gh pr list --head <branch> --state all --json number,state,url
     --jq '.[0]'` run with cwd in the repo. `--offline` skips gh; gh missing,
     not authed, or network error → `pr=unknown` (per-worktree, never fatal);
   - `live`: some cwd from step 2 equals or is under the worktree path;
   - `age`: last commit's relative date (informational column only).
4. Classify (first match wins) and print.

Buckets → recommended action (the command is printed verbatim, per row):

| Bucket | Condition | Action |
|---|---|---|
| `LIVE` | a process has its cwd inside | keep — in use |
| `DIRTY` | uncommitted/untracked files | keep — inspect: `git -C <wt> status` |
| `PRUNABLE` | admin entry, directory gone | `git -C <repo> worktree prune` |
| `MERGED` | PR state MERGED, or `merged_local` | `wt -C <repo> remove <branch>` (deletes the merged branch too, fires the tmux cleanup hook) |
| `ABANDONED` | PR CLOSED and not merged | `wt -C <repo> remove -D <branch>` — confirm first, deletes an unmerged branch |
| `IN-REVIEW` | PR OPEN | keep — `/address-review` may need it |
| `PARKED` | no PR (or unknown) and `unpushed` | keep, surface — ship it or remove it deliberately |
| `SHIPPED?` | no PR / unknown, pushed, not merged | keep — remote has it; likely needs a PR or a merge you can't see offline |

Output: `bin/doctor`-style — a `== <repo>` section per repo that has any
non-main worktree, one line per worktree:
`  <BUCKET>  <branch>  <PR #n state | no PR | pr:unknown>  <flags: locked dirty unpushed>  <age>  <~path>`, followed on the next indented line by the
recommended command (or `keep — <reason>`). Repos with nothing to show are
skipped. Footer: counts per bucket, whether gh was consulted, whether lsof
ran. Flags:
- `--offline` — skip gh.
- `--all` — also list repos with zero extra worktrees (one `clean` line
  each), to prove coverage.
- no other flags in v1 (no `--json`, no `--fix`).

### Not in scope

- Any deletion, `--fix`, prompts, or a sweep schedule (next plan, after the
  report has been used for a while).
- Changing `/feature`, `/address-review`, or the harness's own auto-clean.
- Making dotfiles branches testable from a worktree (dotfiles deploys from
  the hub path by symlink; see the `gco` discussion — a hub checkout is the
  testing path there).

## Steps

1. Create `bin/project-dirs-lib` with `search_dirs` defaults + `.local`
   sourcing, `project_dirs`, `worktree_branch`, `session_name_for`. Move, do
   not copy: the sessionizer loses its own definitions in the same commit.
2. Rewire `bin/tmux-sessionizer` to the lib; add the two-field rows and the
   worktree display; adjust `--preview` to field 1 and the selection parse.
3. Rewire `bin/wt-tmux-jump` and `bin/wt-tmux-cleanup` to `session_name_for`.
4. Write `bin/worktree-doctor` per Part B. `chmod +x`.
5. Tests (offline, no tmux, both bash 3.2 and default bash via
   `tests/run.sh`):
   - `tests/test-project-dirs.sh`: build a throwaway tree under a temp dir
     with fake repos (`.git/` dir), an agent worktree (`.git` FILE with
     `gitdir:` pointing at a fake admin dir containing `HEAD`), a depth-0
     entry with a `.<branch>` sibling worktree and a non-worktree
     `.bak` sibling, and a legacy `.bare/` container; assert the enumeration
     order/contents and `session_name_for` for each kind (incl. detached
     HEAD fallback and `feature/x` → `repo_feature-x`). Point `search_dirs`
     at the temp tree by setting it before calling `project_dirs` (the lib
     must honor a pre-set array the same way the `.local` override does —
     define defaults only if unset).
   - `tests/test-worktree-doctor.sh`: factor classification into a pure
     function `classify_worktree <live> <dirty> <prunable> <pr_state>
     <unpushed> <merged_local>` → prints `<bucket>`; table-drive the cases
     above including precedence (LIVE beats DIRTY beats PRUNABLE …) and
     `pr_state=unknown` handling. Source the script's functions without
     running its main (guard main with `[[ "${BASH_SOURCE[0]}" == "$0" ]]`).
   - Add both to `tests/run.sh`.
6. Docs: `CLAUDE.md` — `bin/` bullet for `worktree-doctor`; sessionizer
   paragraph (worktree rows, two-field fzf rows, naming rule); `tests/`
   list; `other/tmux-sessionizer.local.example` wording. `bin/doctor`'s
   header is NOT touched (this is not a doctor section).
7. Manual verification (implementer, in the worktree; report results in
   the PR body): `bash -n` on every touched script; `bin/worktree-doctor
   --offline` and without `--offline` from the worktree against the real
   machine, confirm it prints, changes nothing (`git status` in a listed
   repo before/after), exits 1 while removable worktrees exist; the
   sessionizer's `--preview` on a two-field row. Do NOT run the sessionizer
   itself or anything that creates/switches tmux sessions (tmux-safety
   rule); the row-building can be exercised by calling `emit_rows`-level
   functions in a subshell if the implementer factors them, otherwise leave
   it to the hub after merge.

## Review checklist (for the reviewer seat)

- No second copy of `search_dirs`, the `.local` sourcing, or session naming
  anywhere — grep for `search_dirs=` and `tr . _`.
- Sessionizer hot path still fork-free before fzf draws (no `$(...)`, no
  `git`, no `basename` per candidate).
- bash 3.2 clean (`tests/run.sh` runs both).
- Nothing private in the plan/PR text: generic repo names only — this repo
  is public.
- No `set -e` in the doctor; no `| head`/`| tail` on git/gh output; gh/lsof
  absence degrades per-row, never aborts.
- Doctor performs zero writes: audit every `git`/`gh`/`wt` call is a
  read (`wt` is only ever *printed*, never executed).

## Assumptions

Every premise the plan leans on, checked against this machine before
implementation. VERIFIED = direct evidence quoted; ASSUMED = taken on faith,
with the fallback that covers it if wrong.

- VERIFIED — the sessionizer's `.local` contract is "may redefine
  `search_dirs` entirely": `bin/tmux-sessionizer` lines 88-90 (`# Machine-local
  override (untracked): may redefine search_dirs entirely.` then a guarded
  `source`), and `other/tmux-sessionizer.local.example` says the same
  ("redefining search_dirs here replaces them entirely"). The lib keeps this
  exact behavior; defining defaults only if unset additionally lets tests
  pre-set the array.
- VERIFIED — `bin/wt-tmux-jump` (line 16) and `bin/wt-tmux-cleanup` (line 15)
  both derive the session name with `basename "$path" | tr . _`; cleanup also
  computes the hub name via `tr . _` and the hub path as `$HOME/dev/$repo`
  (kept as is).
- VERIFIED — fzf `0.74.0 (Homebrew)`: `--help` lists `--with-nth`,
  `-d/--delimiter`, `--expect`; `{n}` field placeholders in `--preview` are a
  long-standing fzf feature (present since well before 0.74).
- VERIFIED — tmux `3.7b`. No new tmux commands are added by this plan; the
  only tmux interaction remains the existing `has-session`/`switch-client`
  paths.
- VERIFIED — `lsof -d cwd -Fpn` works on this macOS (`/usr/sbin/lsof`, exit 0,
  ~1.7k lines): output is `p<pid>` / `fcwd` / `n<path>` line triplets, so the
  live-cwd set is every line starting with `n`.
- VERIFIED — `wt v0.68.0` accepts `-C <path>` globally and `remove -D` /
  `--force-delete` ("Delete unmerged branches"); `wt remove` help says a
  detached worktree must be addressed by PATH, not branch — the doctor prints
  the path form for detached rows.
- VERIFIED — `git 2.50.1 (Apple Git-155)`; `git worktree list --porcelain`
  emits `worktree <path>` / `HEAD <sha>` / `branch refs/heads/<name>` /
  optional `locked <reason>` blocks separated by blank lines (observed on the
  dotfiles repo, including the harness's `locked claude agent agent-<id>
  (pid N start ...)` reason).
- ASSUMED — the `prunable <reason>` porcelain line (git docs: `prunable gitdir
  file points to non-existent location`) — no prunable entry exists on this
  machine to observe, so the parser matches the `prunable` keyword only and
  the test fixture is built from the documented format.
- VERIFIED — an agent worktree's `.git` is a FILE reading
  `gitdir: <repo>/.git/worktrees/<name>`, and that admin dir holds `HEAD`
  (`ref: refs/heads/<branch>`), so the fork-free `worktree_branch` lookup is
  sound. 13 such worktrees exist under `~/dev/*/.claude/worktrees/` and
  `~/dotfiles/.claude/worktrees/` right now; NO `~/dotfiles.*` worktrunk
  sibling exists, so the depth-0 sibling path is exercised only by the test's
  fake tree.
- VERIFIED — worktrunk's `sanitize` filter maps `/` → `-` (evidence:
  worktrunk.dev/config documents `sanitize` as "filesystem-safe: `/` and `\`
  become `-`", and `\` is illegal in a git refname, so only `/` can ever
  appear in a branch name — the two rules are equivalent). Hand-traced
  `feature/x` → `repo_feature-x`, `release/1.2` → `repo_release-1_2`, and a
  dotted repo `my.proj` + `feat/x` → `my_proj_feat-x` from both the sibling
  path and the branch form. Matters more now that round 2's fix also names
  worktrunk-sibling removals from the branch, not just agent worktrees.
- VERIFIED — `gh 2.96.0`, authenticated (`gh auth status` reports a login), so
  `gh pr list --head <branch> --state all --json number,state,url` is
  available in the non-`--offline` run; absence/no-auth still degrades to
  `pr:unknown` per row.
- ASSUMED — repos have an `origin/HEAD` symbolic ref for the default-branch
  lookup; the plan's fallback (`main`, then `master`) covers repos without
  one, and a repo with neither reports `merged_local` as false.
- VERIFIED — `bin/doctor` conventions to mirror: `set -uo pipefail` (no
  `-e`), `== <section>` headers, exit 1 when anything is flagged, exit 0 when
  clean.
- ASSUMED — passing `{1}` (the key field) to `--preview` keeps preview mode
  byte-identical: today `{}` is the whole row, which IS the key (session name
  or `~/`-path) since rows are single-field; after the change the key field
  holds exactly that same string.
- VERIFIED (scope) — the `/feature` harness's worktree-isolation guard in the
  implementing session refuses `git -C <other tree>` and bare `bash` in a
  command string. Manual verification of the doctor against the real machine
  (step 7) may therefore be blocked from inside the worktree; if so the
  implementer records it in `.feature/NOTES.md` and the PR body asks the hub
  to run `bin/worktree-doctor` once after merge instead of faking a result.

## Amendments (round 2, after review round 1)

Recorded here so the PR body carries them; both are deliberate.

1. **`wt-tmux-cleanup` gets the branch from worktrunk.** The review found
   that worktrunk's `post-remove`/`post-merge` hooks run AFTER the worktree
   directory is gone (`wt hook --help`: "the active worktree is gone, so the
   hook runs in the primary worktree"), so `session_name_for <path>` can no
   longer read `<wt>/.git` and falls back to `<repo>_agent-<id>` — the exact
   session leak step 3 set out to fix. Fix: `dots/worktrunk.toml` passes
   `{{ branch }}` as a third argument to `wt-tmux-cleanup` (post-remove and
   post-merge), and the lib grows `session_name_for_branch <repo-name>
   <branch>` (the same `/`→`-` then `.`→`_` rule, one home) which cleanup
   uses when the third argument is present, falling back to
   `session_name_for "$path"` when absent. `wt-tmux-jump` is unaffected
   (post-switch runs with the worktree present).
2. **Locked rows prefix the printed command with an unlock.** The design
   said `locked` is "shown as a flag, never used for decisions". That still
   holds for BUCKET decisions. But `wt remove` (verified against the wt
   binary) refuses a locked worktree, and every harness-made agent worktree
   stays locked after its agent exits — so the copy-paste command for the
   rows this tool exists for would fail as printed. Amendment: when a
   MERGED/ABANDONED row is `locked`, the printed action is
   `git -C <repo> worktree unlock <path> && wt -C <repo> remove ...`. The
   bucket itself is unchanged. Still printed only, never executed.
3. **`wt-tmux-cleanup` treats a `HEAD` branch arg as "no branch".**
   Round 2's branch-bearing fix (amendment 1) assumed the 3rd hook argument
   would be empty for a detached worktree; instead worktrunk renders it as
   the literal string `HEAD` (empirical, wt v0.68.0 — see
   `.feature/NOTES.md`), so the branch-derived name was always taken and the
   path-based fallback was dead code, leaking a detached agent worktree's
   session on removal. Fix: `bin/project-dirs-lib` gains
   `session_name_for_removed <repo-name> <path> <branch>`, which treats an
   empty OR `HEAD` branch as "no real branch" (falling back to
   `session_name_for "$path"`) and anything else as a real branch (via
   `session_name_for_branch`); `HEAD` is a safe sentinel because
   `git check-ref-format --branch HEAD` refuses it as an actual branch name.
