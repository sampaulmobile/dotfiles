---
name: pr
description: Ship the current changes as a PR — commit, fix lint issues, push, create the PR. Invoke only when explicitly asked to ship/open a PR, or as the final step of the feature pipeline.
---

Ship the current changes as a PR. Follow these steps exactly:

## 1. Ensure we are on a feature branch

Run `git branch --show-current`. If the branch is `main` or `master`, create a new feature branch with a descriptive name based on the work done (e.g. `add-graph-editing`, `fix-upload-bug`) and switch to it.

## 2. Understand the changes

Run `git status`, `git diff --stat`, and `git log --oneline -5` (for commit message style). Read through the changes to understand what was done and why.

## 3. Stage files

Only stage files that are part of the current work. Do NOT use `git add -A` or `git add .`. Add specific files by name. Skip anything accidental (.env, .DS_Store, credentials, etc).

## 4. Commit

Attempt the commit with a message following the repo's existing style. Write the message to a file under `/tmp` and use `git commit -F <file>` — file-based messages avoid all shell-quoting issues. (If the repo's CLAUDE.md prescribes a specific commit-message mechanism, e.g. multiple `-m` flags, the repo's convention wins.)

If pre-commit hooks fail and modify files (formatting, linting), re-stage the modified files and commit again as a NEW commit (do not amend). If there are lint/type errors that need manual fixes, fix them, re-stage, and try again. Repeat until the commit succeeds. Ignore pre-existing hook failures unrelated to our changes.

## 5. Push

Push with `git push -u origin <current-branch-name>`.

## 6. Create PR

Create a PR with `gh pr create`. The title is conventional — `<type>: <subject>`, under 70 chars, `type` ∈ `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`.

Determine the default branch first: `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||'` (fall back to `main`). Then use `git log <default>..HEAD` and `git diff <default>...HEAD` to understand the FULL scope of changes across all commits on this branch, not just the latest commit.

Write the PR body to a file under `/tmp` and pass it with `--body-file <file>` — NEVER pass a multi-line body inline or via HEREDOC; shell quoting mangles backticks, `$`, and code fences, which then requires ugly `gh pr edit` / API-PATCH repair after the fact.

The body is written for the person deciding whether to merge, and it is sized to the diff, not to the template. It opens with a TL;DR they can stop after; everything below it is only what they still have to judge or could not see in the diff.

These sections, in this order, each DROPPED when it has nothing to say:

```
## TL;DR
<Two to four sentences: what changed and why, for a reader who has not opened the diff; how it was verified; the one thing they must judge, if there is one. Reading only this is enough to decide whether to merge.>

## Reviewer should check
<At most three one-line bullets: an assumption never verified, a product decision taken here, a surface that could not be verified. A fourth means the PR is too big.>

## Verification
<One line per run that actually happened: the command, then the outcome. Skip what the checks tab already shows.>

<details><summary>Detail</summary>

<Why this shape of fix and what was rejected; blast radius and the one fact that bounds it; anything a requester asked to have documented. Link the evidence — the issue, the failing run, the committed workplan — instead of restating it.>

</details>

Generated with [Claude Code](https://claude.com/claude-code)
```

The budget is in WORDS, because a line cap only produces long lines. Count before posting and cut until it passes:

- TL;DR: 80 words or fewer.
- Visible body, everything above `<details>`: 150 words or fewer; 100 when the diff is under 20 changed lines (`git diff --shortstat <default>...HEAD`). Check with `sed -n '1,/<details>/p' <file> | wc -w` (plain `wc -w` when there is no `<details>` block).
- Whole body, `<details>` included: 450 words or fewer, `wc -w <file>`. A collapsed block is cheap to skip but not free to write, so it is bounded too.

Overflow is not a reason to exceed the budget. A pipeline run has a committed workplan that already carries the assumptions and the test plan: link it. Everything else goes in the commit messages or the issue. A requester's instruction to document something does not suspend the budget: it goes in the collapsed block, within its cap.

No commit SHAs, no file-by-file inventory, no list of test names, no per-item verdict tables — the diff and the checks tab already carry those. A repo whose CLAUDE.md prescribes its own PR body format, title types or PR mechanism wins over this section.

## 7. Return the PR URL to the user

Output the PR URL as a plain clickable link on its own line, e.g.:

https://github.com/owner/repo/pull/123

Do NOT wrap it in markdown link syntax like `[#123](url)` — output the raw URL so it renders as a clickable hyperlink.
