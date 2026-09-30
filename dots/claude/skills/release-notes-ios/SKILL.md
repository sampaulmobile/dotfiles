---
name: release-notes-ios
description: Draft the App Store "What's New" text for an iOS release from the PRs merged since the live build, and write it to the repo's fastlane release notes file without committing. Invoke only when explicitly asked (`/release-notes-ios [build]`).
---

Draft the App Store release notes for one iOS build. The output is an uncommitted file plus a report; the owner reviews, edits and commits.

## 1. Read the repo's conventions

Read the target repo's CLAUDE.md for exactly three facts:

- **iOS dir**: the directory holding `fastlane/` (and its Fastfile).
- **Live build**: how the build number currently live on the App Store is found (a command, or where it is recorded).
- **Build tag format**: the git tag each iOS build gets, with its build number in it (e.g. `prod/builds/ios/<n>`).

If any of the three is missing, stop. Name the missing fact and give the exact line to add to CLAUDE.md, e.g. `- iOS build tags: \`prod/builds/ios/<build_number>\``. Do not guess.

Run only the read-only command CLAUDE.md names for the live build. Never run a deploy, release, beta, `certs` or `nuke` lane, nor any script that uploads or submits.

## 2. Resolve the two builds

- **Release build**: the argument (`/release-notes-ios 183`). With no argument, the newest build tag by number: `git tag -l '<tag format with * for the number>' | sort -V | tail -1`.
- **Live build**: from step 1.

`git fetch --tags origin` first, then check that both tags exist. If the release build is not greater than the live build, stop and say so.

## 3. Collect the change set

The change set is the PRs merged between the two TAGS, never up to HEAD; the default branch may have moved past the release build.

```
git log --first-parent --merges --format='%H %s' <live tag>..<release tag>
```

Take the PR number from each `Merge pull request #<n>` subject. Read every PR's title first, in one pass with `gh pr view <n> --json number,title,labels`. Read a PR's body (`--json body`) only when its title leaves open whether the change is visible to a user. A range can hold 100+ PRs, so collect into a file in the scratchpad rather than printing them all.

## 4. Draft

Style rules:

User-visible changes only. Leave out anything a user would read as "wasn't that always true?" (a compliance or catch-up feature such as account deletion), anything that reads as "fixed bugs I never saw" (a fix for a state most users never hit, e.g. a notification tap landing on the wrong screen), any performance claim without a number, and everything internal (observability, analytics, tests, tooling, refactors, CI). At most 5 bullets, `•` bullets, one line each, plain words, no headers, no exclamation marks, no marketing voice. An App Store reviewer reads this first, so every bullet must be something visible on the build being submitted. Group small related fixes into one bullet ("Loading indicators and reliability fixes for flaky connections") rather than listing each.

## 5. Write and report, then stop

1. Write the bullets to `<iOS dir>/fastlane/metadata/en-US/release_notes.txt`, creating the directories if needed. The file holds the bullets and nothing else.
2. Print `git diff -- <that file>` (for a new, untracked file, print its contents instead).
3. Print the mapping:
   - each bullet, followed by the PR numbers and titles it came from;
   - every PR left out, with a reason of a few words (`internal: CI`, `never-seen fix`, `catch-up feature`, `perf, no number`).
4. Stop. No `git add`, no commit, no push.
