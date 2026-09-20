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

The body is written for the person deciding whether to merge, and answers three questions in that order: what is this and why, what must I judge, was it checked. Everything else belongs in the diff, the commit messages, or a collapsed block.

Write it in BULLETS, not paragraphs. Each bullet opens with the thing it is about — bolded when it names a symbol, a decision or a tradeoff — then the consequence. A paragraph is what a reviewer skims past; a bolded lead-in is what lets them find the one bullet that concerns them.

These sections, in this order, each DROPPED when it has nothing to say:

```
## What & why
<Two or three bullets: the problem, with the number, incident or evidence that shows it, and what the change does about it. Someone who stops here can decide whether to merge.>

## Reviewer should check
<What a human still has to judge, one bullet each: a tradeoff taken and the alternative rejected, an assumption never verified, a product decision made on the pipeline's own authority, a surface that could not be verified, or what this could break and the one fact that bounds it.>

## Verification
<One bullet per run that ACTUALLY happened: the command, then the outcome. Close with a `Not verified:` bullet naming what was never run — it is usually the most useful line in the section.>

<details><summary>Detail</summary>

<Evidence a reviewer may want and should not have to dig for: how a claim was established, the per-field or per-version verdicts behind it, rejected alternatives, follow-ups deliberately not done here. Tables and code blocks belong here. Link the issue, the failing run or the committed workplan rather than restating them.>

</details>

Generated with [Claude Code](https://claude.com/claude-code)
```

There is no word count. The bound is structural: at most three bullets per section, each one to three lines. A fourth bullet under "Reviewer should check" means the PR is too big, not that the list gets longer. Overflow goes into the collapsed block, never silently dropped — including anything a requester asked to have documented.

Keep the evidence and cut the prose. A number, a `file:line`, a tag or a version is what makes a bullet worth reading, and is the first thing a shortening pass wrongly deletes.

No commit SHAs, no file-by-file inventory, no list of test names — the diff and the checks tab already carry those. A repo whose CLAUDE.md prescribes its own PR body format, title types or PR mechanism wins over this section.

## 7. Return the PR URL to the user

Output the PR URL as a plain clickable link on its own line, e.g.:

https://github.com/owner/repo/pull/123

Do NOT wrap it in markdown link syntax like `[#123](url)` — output the raw URL so it renders as a clickable hyperlink.
