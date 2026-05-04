---
name: pr
description: Commit, fix lint issues, push, and create a PR
disable-model-invocation: true
---

Ship the current changes as a PR. Follow these steps exactly:

## 1. Ensure we are on a feature branch

Run `git branch --show-current`. If the branch is `main` or `master`, create a new feature branch with a descriptive name based on the work done (e.g. `add-graph-editing`, `fix-upload-bug`) and switch to it.

## 2. Understand the changes

Run `git status`, `git diff --stat`, and `git log --oneline -5` (for commit message style). Read through the changes to understand what was done and why.

## 3. Stage files

Only stage files that are part of the current work. Do NOT use `git add -A` or `git add .`. Add specific files by name. Skip anything accidental (.env, .DS_Store, credentials, etc).

## 4. Commit

Attempt the commit with a message following the repo's existing style. Use a HEREDOC format. Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`.

If pre-commit hooks fail and modify files (formatting, linting), re-stage the modified files and commit again as a NEW commit (do not amend). If there are lint/type errors that need manual fixes, fix them, re-stage, and try again. Repeat until the commit succeeds. Ignore pre-existing hook failures unrelated to our changes.

## 5. Push

Push with `git push -u origin <current-branch-name>`.

## 6. Create PR

Create a PR with `gh pr create`. Derive a concise title (under 70 chars) from the work done.

Use `git log main..HEAD` and `git diff main...HEAD` to understand the FULL scope of changes across all commits on this branch, not just the latest commit.

The PR body should use this format (via HEREDOC):

```
## Summary
<Describe what changed and why. Be specific — mention new files, new endpoints, new tests, key design decisions, and anything a reviewer needs to know. A few paragraphs is fine for substantial changes.>

## Changes
<Bulleted list of concrete changes: files added/modified, functions introduced, configs updated, etc.>

## Test plan
<Bulleted checklist of what was verified — tests run, manual checks, pre-commit passing, etc.>

Generated with [Claude Code](https://claude.com/claude-code)
```

## 7. Return the PR URL to the user

Output the PR URL as a plain clickable link on its own line, e.g.:

https://github.com/owner/repo/pull/123

Do NOT wrap it in markdown link syntax like `[#123](url)` — output the raw URL so it renders as a clickable hyperlink.
