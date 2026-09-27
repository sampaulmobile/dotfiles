---
name: handoff
description: Wrap up this session for a /clear — persist what is in flight, then write a self-contained prompt that lets a fresh session pick up exactly where this one left off, and put it on the clipboard.
disable-model-invocation: true
---

Hand this session off to a fresh one. The user is about to `/clear` (or open a
new session); after that, nothing in this conversation exists except what you
write down now. An optional argument names what the next session should focus
on.

## 1. Persist what is in flight

- **Running work.** List background shells, subagents, monitors and scheduled
  wakeups this session started. A cleared session never receives their
  notifications: wait for any that finish in a minute or two, and record the
  rest (what it is, how to check on it, where its output lands) for step 2.
- **Files.** Edits on disk survive a clear, so leave the working tree as it is:
  do not commit, push, stash or revert to "tidy up" — those still need the
  user's say-so. If an edit stopped halfway and a file is broken, say which and
  how in the handoff.
- **Durable knowledge.** Anything worth keeping beyond the NEXT session goes to
  its normal home now: memory (user preferences and corrections stated here),
  the repo's CLAUDE.md or code comments (repo facts), the wiki (cross-repo
  facts, per the knowledge rule). The handoff is for resuming the task, not an
  archive.

## 2. Write the handoff

Write it to `handoff.md` in this session's scratchpad directory. It must read
correctly to a session that has seen none of this conversation — no "as
discussed", no "the fix above". Point at files and line numbers instead of
pasting their contents. Sections, each omitted when empty:

- **Goal** — what the user is trying to get done, in their terms.
- **Where things stand** — repo, worktree path, branch, PR; commits made this
  session; uncommitted files (`git status --short`); what is done and verified.
- **Decisions and constraints** — choices the user made or approved and
  preferences they stated, so the next session does not re-litigate them.
- **Tried and ruled out** — dead ends and why, so they are not retried.
- **Still running** — from step 1.
- **Next steps** — ordered and concrete; the first one is what to do right now.
  Mark anything that needs the user's approval before it runs (commit, push,
  deploy, delete).
- **Open questions** — for the user, not guesses to act on.

Keep it as short as it can be while still complete; the next session pays for
every line.

## 3. Hand it over

- `pbcopy < <scratchpad>/handoff.md` (skip silently where `pbcopy` does not
  exist).
- Print the handoff in one fenced block, then a single line:
  `Copied to clipboard — /clear, then paste. Also saved at <path>.`

Do nothing after that; the user clears the session.
