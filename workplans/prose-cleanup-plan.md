# Workplan: prose cleanup — apply the comments rule across the repo

## Goal

Bring the repo's existing comments, script headers and CLAUDE.md in line with
the global rule `dots/claude/rules/comments.md` (record only what code cannot
say; one home per fact; no ephemeral references; guard comments are
load-bearing; CLAUDE.md is operating knowledge, not build narrative). The
scripts were written by agents over many sessions and carry the density that
produced the rule: comment lines roughly equal to code lines in the newest
files, the same fact explained in a header, a function comment and CLAUDE.md,
and references to pipeline files that no longer exist.

This is a PROSE-ONLY change. No behavior changes, no refactors, no renames,
no "while I'm here" fixes. If a real bug is found, it is written down in the
PR body under `## Found, not fixed` and left alone.

Decisions already made (do not re-open):
- The rule is committed and live BEFORE this pass runs; the implementer and
  reviewer read it as the bar. This plan does not restate it.
- Guard/gotcha comments are kept unless the gotcha is verified gone. When in
  doubt, keep and shorten rather than delete.
- Skills (`dots/claude/skills/`), rules (`dots/claude/rules/`), `templates/`
  and `other/*.example` are OUT of scope: they are prompts and templates, not
  code comments, and are tuned separately.
- Memory files and the wiki are out of scope.

## Scope

In scope, in this priority order:

1. `CLAUDE.md` — the highest-value target: it is loaded into every session
   at the hub (~3.8k words today). Each entry becomes what a session needs to
   operate or safely modify the thing: what it is, where it lives, the
   invariants that must hold, the commands. Build history, review narrative,
   "used to work like X" and per-column implementation detail go. Facts that
   are the single source of truth for a script's contract (e.g. the
   sessionizer's naming rule, the dashboard's dedupe-by-requestId, the
   attention layer's flag semantics, the branch-naming line under
   Conventions) STAY, once, in their shortest form.
   Target: roughly half the words with no operating fact lost.
2. `bin/*` (every script, including the libs) — headers and comments per the
   rule. Known offenders to look at first, from the last review: the
   `project-dirs-lib` / `tmux-sessionizer` / `worktree-doctor` /
   `wt-tmux-jump` / `wt-tmux-cleanup` set (header restates function comments;
   the naming rule explained in three places; a `.feature/NOTES.md` reference
   that points at a deleted file), then `tmux-claude-lib`, `tmux-claude-lib-codex`,
   `tmux-claude-dashboard`, `tmux-claude-attention`, `claude-tokens`.
3. `tests/*.sh` and `tests/run.sh` — same treatment; test names and `ok`/`bad`
   messages are not comments and stay.
4. `notes/*.md` — only remove references to files that no longer exist and
   duplicated CLAUDE.md content; these are setup guides and may stay prose-heavy.

## Mechanics

- **Prose-only proof, per script.** For every changed file under `bin/` and
  `tests/`, the code must be byte-identical after stripping full-line
  comments and blank lines. The implementer adds `tests/check-prose-only.sh
  <base-ref>` (bash 3.2 clean, offline): for each file changed vs
  `<base-ref>`, compares `grep -vE '^[[:space:]]*#' | grep -vE '^[[:space:]]*$'`
  of both versions and fails on any difference, printing the file and the
  first differing line. Trailing (end-of-line) comments are NOT stripped by
  this check, so removing or editing one shows up as a code change — that is
  intended: edit end-of-line comments only where the whole line is a comment,
  or leave them. The shebang line is code. This script is committed (it is
  the tripwire for every future prose pass) and referenced from CLAUDE.md's
  `tests/` bullet.
- `tests/run.sh` must pass under both bashes before and after.
- `bash -n` on every touched script under both bashes.
- No `| head` / `| tail` on real commands (output-truncation rule); the guard
  hook will block it anyway.
- Public repo: the pass must not introduce private names, and should remove
  any it finds (report them in the PR body without repeating them).
- Commit in small units: one commit per script (or per closely related
  pair), CLAUDE.md on its own, tests on their own — so a bad edit can be
  reverted alone. Commit messages state what kind of prose was removed, and
  name any guard comment that was deleted plus the verification that let it go.

## Steps

1. Read `dots/claude/rules/comments.md`, this plan, and CLAUDE.md in full.
2. Write `tests/check-prose-only.sh`; add it to `tests/run.sh` in a mode that
   exercises it against a fixture (a temp git repo with one comment-only
   change and one code change; the check must accept the first and reject
   the second). Commit.
3. `bin/` pass, priority order above, running the prose-only check after
   each file and committing per file/pair.
4. `tests/` pass, same discipline.
5. CLAUDE.md rewrite. Method: for each bullet, ask "what would a session
   need to know to operate or safely change this?" and keep exactly that.
   Every command, path, key binding, invariant and gotcha that exists today
   must still be findable; the reviewer checks this by grepping the old
   CLAUDE.md for every backticked token and confirming each still appears
   (or was deliberately dropped and listed in the PR body).
6. `notes/` pass (light).
7. PR body: per-file before/after comment-line counts (and CLAUDE.md word
   count), the list of guard comments removed with their verification, the
   list of CLAUDE.md tokens deliberately dropped, `## Found, not fixed`.

## Review checklist (reviewer seat)

- `tests/check-prose-only.sh <default-branch>` passes for every changed
  script — no code changed, anywhere, at all.
- `tests/run.sh` passes under both bashes.
- Every guard/gotcha comment removed is named in a commit message with the
  verification that retired it; any removed without that is BLOCKING.
- No fact now has zero homes: for each deleted comment that stated a
  non-derivable fact, confirm the fact survives in CLAUDE.md or in another
  comment at the code it protects. Spot-check by picking ten deleted
  comment blocks from the diff.
- CLAUDE.md: every backticked token from the old version is present in the
  new one or listed as dropped in the PR body. Key bindings, script names,
  flags and paths must all survive.
- No references remain to `.feature/`, scratch dirs or session notes.
- The remaining comments follow the rule: none restate the code, none
  duplicate a header or CLAUDE.md, headers are purpose + constraints.
- Nothing private introduced.
