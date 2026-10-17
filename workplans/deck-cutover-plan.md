# Workplan: cut the agent layer over to deck

## Restatement (from the request alone)

- Task: point dotfiles' agent-layer entry points (tmux keys, hooks,
  `/feature` Launch, the `wt` hooks, doctor) at `deck`, and delete the bash
  scripts deck has replaced, in one local branch.
- Done means: C-f/C-e/C-g run `deck`; the tmux server's PATH finds `deck`;
  `/feature` launches with `deck launch`; the hq skill carries the question
  marker; doctor checks deck; every ported bash script, its tests and its
  CLAUDE.md section are gone; tests green; the bindings parse on a throwaway
  tmux server.
- Assuming: deck already covers everything it is said to (tab tint, codex
  hook wiring, jump-to-attention), which the plan has to verify first.

## Digest

- **Task**: one local PR swapping tmux keys, `/feature` Launch, `wt-tmux-jump`
  and doctor onto deck, and `git rm`-ing the eight bash scripts deck replaces
  outright, with their tests, fixtures and CLAUDE.md sections.
- **Done means**: C-f (root + copy-mode-vi) → `tmux neww deck pick`; C-e →
  `run-shell -E "deck open feed"` behind the vim/fzf passthrough; C-g →
  `run-shell -E "deck open agents"`; zshrc puts `~/.local/bin` and
  `dotfiles/bin` on PATH before the tmux auto-launch; `/feature` step 6 runs
  `deck launch`; hq skill gains the `? <question>` marker; `wt-tmux-jump` is
  `deck pick <path>`; doctor checks deck + config symlink + `deck status`;
  `tests/run.sh` green; `list-keys` on a `-L` server shows the bindings.
- **Not doing**: anything under `other/` (the settings.json and
  settings.json.example changes are printed in the PR body), the live tmux
  server, the daemon, the deck repo (its `attention_cmd` still names
  `tmux-claude-attention`, which therefore stays). No Board key (no obvious
  free one; C-t is `switch-client -l`; the Board is `deck open board`). No
  trimming of `tmux-claude-lib`'s now-uncalled functions: the lib is
  retired whole with the statusbar in the follow-up.
- **Assuming** (all now VERIFIED, see Assumptions): deck does NOT set
  `@agent_status`, has no bell/notification, no jump-to-attention, no codex
  adapter, and `dots/codex/hooks.json` carries NO deck entries. So kept on
  bash: `tmux-claude-statusbar` (glyphs + tab tint), `tmux-claude-attention`
  (C-y, the client-attach clears, deck's own `g` via `attention_cmd`, the
  flags the statusbar/tint/deck read), `tmux-claude-notify` (bell),
  `tmux-claude-lib` + `-codex` (their library), `hq-snapshot` (sourced by
  the statusbar, attention, `worktrees`, `prs`; the hq skill reads its
  `pipelines.tsv`), and every hook that feeds them.
- **Surface**: `tests/run.sh`; `bash -n`; `tmux -L cutover-test-$$ -f
  dots/tmux.conf start-server` + `list-keys`; `deck launch --help`; grep of
  what `/feature` and `/hq` call.
- **Touches**: ~45 files. Deleted: `bin/{hq-inbox,hq-feed,hq-reap,
  tmux-claude-dashboard,tmux-sessionizer,tmux-task-session,claude-tokens,
  claude-review}`, `tests/{test-hq-inbox,test-hq-feed,test-hq-reap,
  test-dashboard,test-session-order,test-fzf-expect,test-task-session}.sh`,
  `tests/fixtures/{feed/,inbox-pipelines.tsv,inbox-prs.tsv,inbox-state/,
  inbox-threads/}`. Edited: `dots/tmux.conf`, `dots/zshrc`, `bin/hq-snapshot`
  (drop `inbox` + `turns` sources; its reap spawn becomes `deck reap
  --apply`), `bin/wt-tmux-jump`, `bin/doctor`, `bin/profile-lib`,
  `tests/run.sh`, `tests/test-hq-snapshot.sh`, `tests/fixtures/README.md`,
  `dots/claude/skills/{feature,hq}/SKILL.md`, `CLAUDE.md`, `README.md`,
  `sources/exports`, `notes/codex.md`, stale comments in kept scripts.
- **Question**: deck has not ported the tab tint, the bell, C-y or codex, so
  the brief's "remove the bash hook entries" and its delete list would break
  the statusbar it also says to keep. My plan keeps those scripts and every
  hook entry that feeds them (codex hooks.json unchanged; settings.json needs
  no change — its Stop hook already has `deck hook done`), and on the
  not-ported list deletes `hq-inbox` and `claude-review` (no consumer) but
  keeps `hq-make-decision` + `hq-decisions` (the `/feature` and `/hq` skills'
  decision records call them) and `worktrees`/`prs` (the brief says keep).
  Go with that, or remove the bash hooks anyway and accept a dead ✅/tint/
  C-y-done until deck owns them?

Reading the code changed: the brief's premises on codex dual-wiring, tab
tint and the inbox-log step (it is not in the tracked hq skill — it lives in
the private layer) were wrong; the delete set shrank from 16 to 8 scripts.

Gate (dotfiles-hub, decision cb5cf9): go as digested — keep the bash
statusbar, attention, notify, lib(+codex), hq-snapshot and every hook that
feeds them; delete only the 8 scripts. PR body gains the still-bash list.

## Goal

dotfiles stops owning the agent screens, picker, launcher, reaper and token
accounting; deck owns them. What deck has not yet ported stays on bash and
keeps working.

## Approach and steps

1. **PATH** (`dots/zshrc`): directly after the Homebrew `shellenv` line and
   before `# auto-launch tmux`, add
   `export PATH="$HOME/.local/bin:$HOME/dotfiles/bin:$PATH"`; delete the
   `export PATH="$HOME/dotfiles/bin:$PATH"` at the EXPORTS block (keep its
   section header only if other lines remain under it). `typeset -U path`
   (line 6) already dedupes the inner shell's re-run.
2. **tmux.conf**:
   - `bind-key -n C-f run-shell "tmux neww deck pick"` and the same in
     `-T copy-mode-vi`.
   - `bind-key -n C-g run-shell -E "deck open agents"`.
   - C-e: same `if-shell` vim/fzf test, else branch
     `'run-shell -E "deck open feed"'`.
   - C-y unchanged (deck has no jump-to-attention); C-Space, prefix+C,
     the client-attached/session-changed/window-changed hooks, the statusbar
     and the tint unchanged.
   - Rewrite the comments above C-f/C-g/C-e to state the new facts only
     (comments rule: no "was X, now deck"); C-y's comment no longer calls
     C-e its mirror if that wording breaks.
3. **hq-snapshot**: remove the `inbox` and `turns` sources (their
   collectors, helpers used only by them — `collect_inbox`, `thread_facts`,
   `pr_row_tag`, `inbox_slug`, `inbox_thread_file`, `turns_rows`,
   `collect_turns`, `snapshot_lines_preserve` if only turns uses it — the
   `INBOX_DIR` var, the `--check` inbox exemption, `usage` text). Verify by
   grep that no kept script calls a removed function before removing it. In
   `tick`, the reap spawn becomes `deck reap --apply` (bare name, PATH from
   step 1), and since deck does not write `$REAP_DIR/last-run`, the tick
   stamps it itself (`mkdir -p "$REAP_DIR"; touch "$REAP_DIR/last-run"`)
   immediately before spawning, so the 120s cadence holds. `command -v deck`
   guard: no deck → no spawn. Header/usage text updated. Removes nothing on
   disk (existing `inbox.tsv`/`turns.tsv` left as they are).
4. **wt-tmux-jump**: keep the `TMUX` and `CLAUDECODE` guards and the
   project-dirs-lib naming comment only if still true; body becomes
   `exec deck pick "$path"` (deck's `accept` builds or wakes the session by
   `session_name_for`, then switches the own client). Drop the
   `tmux-claude-lib` source. `wt-tmux-cleanup` and `dots/worktrunk.toml`
   unchanged (deck has no session kill outside reap; cleanup needs only
   project-dirs-lib).
5. **doctor**: new section `deck` before the brew one:
   - `command -v deck` else `deck not on PATH — fix: uv tool install -e
     <deck checkout>` and fail;
   - `[ -L "$HOME/.config/deck/config.toml" ]` else fail with the fix
     `ln -s <deck checkout>/config.toml ~/.config/deck/config.toml`;
   - `deck status` (its own check: exit 1 unless every collector is fresh,
     which includes no daemon holding the lock); on failure print its output
     indented and `fix: start the daemon (deck daemon)`.
   No private path or org name in the text (PUBLIC repo).
   The `status snapshot` section stays (hq-snapshot is kept).
6. **Deletions** (`git rm`, this worktree only): the eight scripts, seven
   test files and inbox/feed fixtures listed in the digest; the
   `tests/run.sh` suite entries; the fixtures README rows for deleted
   fixtures. Before deleting each test, confirm by reading that it tests
   only a deleted script (`test-fzf-expect`/`test-session-order` →
   sessionizer; `test-dashboard` → dashboard; `test-task-session` →
   tmux-task-session; `test-hq-feed` → hq-feed/turns; `test-hq-inbox`,
   `test-hq-reap`). A test of a KEPT lib function that a deleted test file
   also covered is not re-homed (the function is uncalled now).
   `tests/test-hq-snapshot.sh`: drop the turns/inbox cases, keep the rest.
7. **Skills**:
   - `feature/SKILL.md` Launch step 6: `deck launch --model <ORCH_MODEL>
     --effort <ORCH_EFFORT> "$WT" "$(cat "$LAUNCH_FILE")"`; the following
     paragraph names `deck launch` (prints the session name, creation-only,
     leaves an existing session alone, writes `.feature/launch-prompt.md` —
     all verified in deck's `launch.py`). "After a Launch": `bin/hq-reap`
     → `deck reap --apply` (run by the status bar's snapshot tick every ~2
     minutes), resume → `deck reap resume <session>`.
   - `hq/SKILL.md`: the reap bullet the same way; add the question marker:
     a turn that ends waiting on the owner's decision ends with a final line
     `? <one-line question>` (deck's `question_marker`, `^\? `, matched
     against the reply's last non-empty line, puts it in the Feed's ASKING
     bucket). The `pipelines.tsv` read stays. No inbox-log step exists in
     this file to drop.
   - `templates/hq/`: no change unless a reference to a deleted script is
     found (only `hq-make-decision`, kept).
8. **Docs**: CLAUDE.md — remove the bullets for the deleted scripts
   (`hq-inbox`, `hq-reap`, `hq-feed`, `tmux-sessionizer`,
   `tmux-claude-dashboard`, `tmux-task-session`, `claude-tokens`,
   `claude-review`) and their mentions elsewhere (tests list, profile-lib's
   `DASHBOARD_PROFILE`, Ctrl+Y/E/G/F keybinding lines, the task-session
   paragraph, the "Agents: claude + codex" sessionizer ctrl-x/Option+Enter
   line, `templates/` line if affected); trim the `hq-snapshot`,
   `statusbar`, `attention`, `project-dirs-lib` bullets to what is still
   true. Add ONE short `## deck` section: deck owns the Feed, Agents, Board,
   picker, launcher, reaper and stats; tmux keys and hooks call it by bare
   name off PATH; what stays on bash until deck ports it (statusbar + tint,
   attention flags + C-y, notify, codex) and that deck's `attention_cmd`
   calls `tmux-claude-attention`; pointer to deck's own docs, nothing
   restated. `README.md`, `sources/exports`, `notes/codex.md`: drop stale
   references. Kept scripts' comments that name deleted scripts are fixed.
9. Verification (implementer runs and attaches output): `tests/run.sh`;
   `bash -n` on every changed script; `tmux -L cutover-test-$$ -f
   <worktree>/dots/tmux.conf start-server \; list-keys` grep for C-f, C-e,
   C-g, C-y (then `tmux -L cutover-test-$$ kill-server` on THAT socket
   only); `deck launch --help`; `git grep` proving no tracked non-workplan
   file names a deleted script; a listing of the commands `/feature` and
   `/hq` now call.

## PR body material (for the owner, `--local`)

- Live settings.json: no change required (Stop already runs `deck hook
  done`, Notification `deck hook permission`). Suggested example update for
  `other/claude/settings.json.example` (owner applies; other/ untouched
  here): add the two deck hook entries beside the bash ones, exactly as live.
- Private `other/zshrc.local` `~/.local/bin` PATH line can go.
- The running tmux server keeps its old PATH: restart it, or `tmux
  set-environment -g PATH "$PATH"` from a new shell, before the bare
  `deck` bindings work.
- A short "Still bash, retires when deck ports it" list: tab tint via
  `@agent_status` (+ the statusbar glyphs), bell/notification, the C-y jump
  (and deck's `attention_cmd`), the codex adapter. Once deck ports them,
  statusbar/attention/notify/lib/hq-snapshot retire together.
- The private inbox recorder and the inbox-log step live in the private
  layer; remove them there.

## Test plan

`tests/run.sh` (both bashes) green after deletions; the trimmed
`test-hq-snapshot.sh` still covers writer/age/verdict/record formats; tmux
config parses on a throwaway socket; doctor's deck section run once live
(read-only: `command -v`, `test -L`, `deck status`).

## Out of scope

Anything in `other/`, `~/.claude`, the deck repo, the live tmux server, the
daemon. Retiring the statusbar/attention/notify/lib chain. A Board hotkey.
The window-hotkey PR. Removing `bin/worktrees`/`bin/prs`.

## Assumptions

- deck sets no `@agent_status` — VERIFIED: no match for `agent_status` in
  `src/deck` (grep, deck HEAD d59b50f).
- deck has no bell/notification — VERIFIED: no `osascript`/notification/bell
  in `src/deck`.
- deck's Feed `g` runs `tmux-claude-attention jump-to` — VERIFIED:
  `config.py` `attention_cmd = "tmux-claude-attention"`, `tui/jump.py`
  returns "attention command not found" and does not move when it is absent.
- `dots/codex/hooks.json` has no deck entries — VERIFIED by reading it.
- Live settings.json Stop already runs `deck hook done` — VERIFIED (`jq
  .hooks ~/.claude/settings.json`).
- `deck launch` writes `.feature/launch-prompt.md`, is creation-only, leaves
  an existing session — VERIFIED: `launch.py` header and `PROMPT_FILE`.
- `deck pick <dir>` builds or wakes then switches the own client —
  VERIFIED: `pick.accept`.
- Nothing in deck runs `reap --apply` on a schedule — VERIFIED: no `reap` in
  `daemon.py`; hence the tick spawn.
- `deck status` exits 1 unless every collector is fresh — VERIFIED: deck
  CLAUDE.md; ran it, exit 0 with `daemon lock: held`.
- The hq skill has no inbox-log step — VERIFIED: no `inbox` in
  `dots/claude/skills/hq/SKILL.md`.
- `hq-make-decision` is live — VERIFIED consumer: `feature/SKILL.md`
  "After a Launch" and `hq/SKILL.md` §3 call it.
- `run-shell -E` exists on tmux 3.7b — VERIFIED: `man tmux` `run-shell [-bCE]`; the throwaway-server
  `list-keys` proves the lines parse.
