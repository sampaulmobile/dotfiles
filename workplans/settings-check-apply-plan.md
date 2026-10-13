# Workplan: `claude-settings-check --apply`

## Restatement

- Task: give `bin/claude-settings-check` an `--apply` mode that adds every
  gap it already reports to the live settings.json, strictly additively and
  safely, and make `bin/seed_other.sh` (write mode) use it.
- Done means: `--apply` adds exactly the reported gaps (hook into existing
  matcher group, or whole group), never touches existing values/order, writes
  through a symlink to its target via tmp+`mv` after validating, leaves a
  timestamped backup, refuses a broken live file; `seed_other.sh` applies,
  `--check`/doctor stay read-only and name the fix; tests cover it under both
  bashes; CLAUDE.md, the script header and `other/README.md` describe it.
- Assuming: the gap identities in the header are the right merge keys; jq
  re-serialisation of the live file is acceptable formatting.

## Digest

- Task: `claude-settings-check --apply [live] [example]` — additive merge of
  the reported gaps into the live file's resolved target; `seed_other.sh`
  (no `--check`) runs it; report mode prints a `fix:` line naming `--apply`.
- Done means: the brief's ACCEPTANCE; `tests/run.sh` green; shellcheck clean.
- Not doing: removing/changing/reordering anything in the live file; a
  three-way merge; touching the real `other/claude/settings.json` or
  `~/.claude/settings.json`; any change to `bin/doctor` (it already calls
  `seed_other.sh --check`, whose output will carry the fix line).
- Assuming: see Assumptions (backup file sync behaviour).
- Surface: `tests/test-settings-check.sh` via `tests/run.sh`; one hand-run
  `--apply` on a mktemp fixture copy (before/after check output).
- Touches: `bin/claude-settings-check`, `bin/seed_other.sh`,
  `tests/test-settings-check.sh` (+ fixtures as needed), `CLAUDE.md`,
  `other/README.md`.
- Question: none.

Reading the code changed: `other/README.md` (tracked) also says the check
"only reports" — it is in scope for the doc update. `bin/doctor` needs no
edit: the fix line belongs in the check's own report output, which doctor
already prints through `seed_other.sh --check`.

## Approach

One jq program, one set of definitions shared by check, apply and the
post-apply validation, so "what is a gap" exists once.

1. Refactor the jq `ids` def into a shell variable `JQ_DEFS` holding:
   - `entries`: the existing `flat` walk, but each emission is an object
     `{id: [path, label], p: <path array>, ...}` plus what is needed to add
     it — `leaf: <value>` for a scalar, `item: <element>` for an array
     element (permissions and other arrays), `hook: <hook obj>, group:
     <example group obj>` for a hooks entry. Labels are unchanged, so report
     output is byte-identical to today's.
   - `ids`: `[entries | .id]`.
   - `addentry($e)`: hook → find the first live group under `$e.p` whose
     `(.matcher // "") == ($e.group.matcher // "")`; if found append `$e.hook`
     to its `hooks` (`// []`), else append `$e.group` whole to the event
     array (`getpath // []`). Array item → `setpath(p; (getpath(p) // []) +
     [item])`. Scalar → `setpath(p; leaf)`. A parent of the wrong shape
     (string where an object is needed, object where an array is) makes jq
     error → apply fails, file untouched.
   - `apply($ex)`: `reduce ($ex | entries) as $e (.; if any(ids[]; . ==
     $e.id) then . else addentry($e) end)` — presence re-checked against the
     accumulating doc, so a whole group appended for its first missing hook
     is not appended again for its second.
   jq 1.6 is the floor: only 1.6 builtins.
2. Report mode (no `--apply`): unchanged semantics and exit codes; after the
   gap lines print `  fix: bin/claude-settings-check --apply (or
   bin/symlink_files.sh)`.
3. `--apply` mode (flag first: `claude-settings-check --apply [live]
   [example]`):
   - Same input validation (missing file / invalid JSON → exit 2, nothing
     written).
   - Resolve the live path through symlinks to its target with a portable
     `readlink` loop (no `readlink -f`, no `realpath` dependency).
   - Read the target ONCE into a variable (`orig`); compute `missing`; none →
     exit 0 silently, no backup, no write.
   - Compute `new` = `apply(example)` over `orig`. Validate `new` in-memory:
     parses, and `(example|ids) - (new|ids) == []` using the same defs
     (that is the "re-run of the check"). Any failure → message to stderr,
     exit 1, nothing written anywhere (no tmp file exists yet).
   - Re-read the target; if it no longer equals `orig` (Claude Code wrote it
     meanwhile) → refuse, exit 1, nothing written; re-running is the fix.
   - Backup: `cp -p target target.bak.<YYYYmmddTHHMMSSZ>`; if that name
     exists, append `.$$`. Never removed by the script. Backup failure →
     exit 1 before any write.
   - Write: `cp -p target target.tmp.$$` (keeps mode), `printf '%s\n' "$new"
     > tmp`, `mv tmp target`. On a write/mv failure the tmp file is LEFT and
     its path printed (append-only, like `bin/hq-snapshot`; the script never
     `rm`s outside the worktree). The live path, if a symlink, is never the
     `mv` destination.
   - Print one line per added entry (`  added  <path>  <label>`, same column
     layout as the report) plus the backup path, exit 0.
4. `bin/seed_other.sh`: write mode runs `claude-settings-check --apply`;
   `--check` runs the plain check (unchanged). A failed apply in write mode
   still exits 0 (so `symlink_files.sh` keeps linking) but the failure is
   printed; check mode exit logic unchanged. Header lines updated.
5. Header of `claude-settings-check`: purpose now "report, or with --apply
   add"; the `--apply` contract (additive only, symlink target, backup,
   validation, exit codes); drop "Nothing is written". No narrative.
6. Docs: CLAUDE.md Conventions line → gaps are reported by the check /
   doctor and added by `bin/claude-settings-check --apply`, which
   `bin/seed_other.sh` (so `bin/symlink_files.sh`) runs; `bin/doctor`
   bullet → note the fix it names. `other/README.md`'s "It only reports"
   paragraph → same. Point, don't restate the header.

## Tests (`tests/test-settings-check.sh`)

All runs on copies under the suite's own `mktemp -d` (never the live file).
Existing cases stay. New:
- report mode on the gappy fixture also prints the `fix:` line.
- apply on a copy of `settings-live-gappy.json`: exit 0; `added` lines for
  exactly the 5 gaps; a re-run of the check exits 0 silently; second apply
  prints nothing, exit 0, writes no second backup.
- hook into existing matcher group: the gappy fixture's `PreToolUse` `Bash`
  group gains the guard hook in its `hooks` list (group count still 1, the
  pre-existing hook still first).
- hook with a new matcher: a fixture (or jq-derived copy) whose example has a
  matcher absent from live → the whole group appended at the end of the
  event array.
- permissions entry appended after existing entries, existing order intact.
- scalar key added (`voice.enabled`, `statusLine.*`).
- preservation: jq comparison that the live-only keys (`model`, a synthetic
  `enabledPlugins`, the `env` block) and differing values (`effortLevel`,
  `voice.mode`) are identical before vs after, and that every pre-existing
  leaf keeps its value (`[paths(scalars)]` of before, each `getpath` equal).
- symlink: apply via a symlink to a fixture copy → the link is still a link
  pointing at the same target, the target gained the entries.
- backup: exactly one `*.bak.*` sibling of the target, byte-identical to the
  pre-apply file (`cmp`).
- non-JSON live file: apply exits nonzero, file byte-identical (`cmp`), no
  backup, no tmp file.
- wrong-shape conflict (live `voice` is a string): apply exits nonzero, file
  unchanged.
Fixtures stay synthetic; no value from any real settings file.

## Assumptions

- VERIFIED: `bin/doctor` reaches the check only via `seed_other.sh --check`
  (read `bin/doctor`), so a fix line in the check's report reaches doctor's
  output without a doctor edit.
- VERIFIED: `symlink_files.sh` runs `seed_other.sh` (write mode) only when not
  `--check` (line ~222), so apply happens on its run and never on doctor's.
- VERIFIED: jq on this machine is 1.6.
- ASSUMED: the backup sibling's sync behaviour in the private `other/` repo
  matches the live file's (the brief says settings.json is untracked there;
  `other/README.md`'s ignore list does not name it, and this machine has no
  `other/.git` to check). A backup holds nothing the live file does not.
  Verify with `git -C ~/dotfiles/other check-ignore -v
  claude/settings.json.bak.x` on a machine where the private repo exists.
- ASSUMED: jq's 2-space re-serialisation is close enough to Claude Code's own
  `JSON.stringify(…, null, 2)` that the rewrite is a content-only change.

## Out of scope

- Running `--apply` against any real settings file (owner does it after
  merge via `bin/symlink_files.sh`).
- Removing stale entries, value drift, `repo-props.toml`.
