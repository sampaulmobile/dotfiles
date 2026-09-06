---
name: address-review
description: Fetch unresolved GitHub PR review feedback and address it — fix, commit, push, and reply to each thread.
disable-model-invocation: true
---

Address human review feedback on a PR. Argument: a PR number, a branch name, or nothing.

## 0. Resolve the target PR (when no argument given)

1. If the current branch has an open PR (`gh pr view`), use it.
2. Otherwise scan the user's open PRs in this repo:
   `gh pr list --author "@me" --state open --json number,title,headRefName,reviewDecision,updatedAt`
   and check each for ACTIONABLE feedback (unresolved review threads with a
   human comment newer than our last reply, changes-requested reviews, or
   unaddressed bot findings — same definitions as step 1 below).
3. Exactly one PR with actionable feedback → proceed on it, saying which.
   Several → show a one-line-each list of them and ask which (or all).
   None → report "no open PRs of yours have unaddressed feedback" and stop.
4. `--all` flag: process every open PR of the user's that has actionable
   feedback, sequentially, without asking.

## 1. Gather the feedback (in the current session)

- `gh pr view <n> --json number,title,body,headRefName,reviews,url` for PR metadata and review bodies.
- Unresolved inline threads via GraphQL:

```
gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100){nodes{isResolved isOutdated path line comments(first:20){nodes{databaseId author{login} body diffHunk}}}}}}}' -f owner=<owner> -f repo=<repo> -F pr=<n>
```

- Keep only threads with `isResolved: false`, and of those, skip threads already handled on a previous pass — i.e. the latest comment is the PR author's reply referencing a fix commit (or answering/declining) with no newer human comment after it. Only new human feedback is actionable. Also collect review-level bodies (request-changes text, general comments) that ask for something.
- Also fetch plain PR comments (`gh pr view <n> --json comments`) to catch automated reviewers (e.g. a Claude GitHub Action, CI annotation bots) that post findings as issue comments rather than reviews. From those, keep only actionable findings that are not already addressed: use just the LATEST comment per bot author (older ones are usually superseded), and ignore pure status/success messages ("review complete", "task finished", CI links with no findings).
- If nothing is unresolved, no review asks for changes, and no bot comment carries unaddressed findings, tell the user and stop.

## 2. Spawn the fix agent

Spawn ONE background agent (`subagent_type: "high"`, `model: "sonnet"`; use `model: "opus"` if the feedback is architectural — the `high` preset pins effort, the model rides as an Agent `model:` override; if the preset is missing, a plain `model: sonnet` agent works). All context it needs lives on GitHub and the branch — pass it the PR number, the branch name, and the collected feedback verbatim. Its prompt must tell it to:

- Find a checkout of the branch: `git worktree list`, use the worktree that has it checked out; otherwise create one as a sibling of the repo (`git worktree add <repo-dir>.<branch-slug> <branch>`, slashes in the branch sanitized to dashes) and work there.
- Read the workplan doc (`workplans/`) and the PR body for context; read `.feature/NOTES.md` if present and append to it as it works.
- Address EVERY unresolved thread and change request: make the fix, or — if it disagrees, or the comment is a question — prepare a reasoned reply instead of a change. Never silently skip one.
- Bot/automation findings are input feedback too, with two differences: triage them on merit (fix real correctness/security findings; it is fine to decline noise or style nits from a bot, briefly noting why in the summary), and when human feedback conflicts with a bot's, the human wins. There is no thread to reply into for issue-comment findings — cover their disposition in the summary comment instead.
- Run the tests/linters relevant to what it touched.
- Commit specific files with clear messages (never `git add -A`); push to the same branch. The commit body is where the what/why of each fix lives — say which feedback it addresses.
- Reply to each inline thread with a ONE-LINE pointer, e.g. `Done in <short-sha>.` (at most add a short clause if the fix took a different shape than asked):
  `gh api repos/<owner>/<repo>/pulls/<n>/comments/<databaseId>/replies -f body='...'`
  Elaborate only when the thread was a question (answer it) or you're declining a change (give the reasoning). Do NOT duplicate the commit message into the thread, and do NOT resolve threads — the human reviewer resolves them on re-review.
- Do NOT post a PR-level summary comment when every item was an inline thread — the thread replies are the record. Post one only if some feedback had no thread to reply into (review-body asks, bot findings) and needs its disposition recorded.
- Report back: commits pushed, threads addressed (fix vs. reply-only), and anything it could not address and why.

## 3. Relay

Give the user the agent's summary and the PR URL. Re-review and thread resolution happen on GitHub.
