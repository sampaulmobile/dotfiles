#!/usr/bin/env bash
#
# classify_worktree/action_for/parse_porcelain_blocks — the pure functions
# behind bin/worktrees's per-worktree buckets, commands and porcelain
# parsing. Offline: it SOURCES bin/worktrees, which hands back all
# three (and usage) and stops before the report itself (the BASH_SOURCE
# guard near the top of that file), so no git, no gh, no lsof and no real
# machine worktree is ever touched.
#
#   tests/test-worktrees.sh
#
# The classify_worktree case that matters is precedence: LIVE beats DIRTY
# beats PRUNABLE beats MERGED beats ABANDONED beats IN-REVIEW beats PARKED
# beats SHIPPED?, first match wins — so a merged worktree that's still dirty
# must report DIRTY (keep, inspect), never silently look removable. The one
# sanctioned look-through is merged_under_untracked: dirt that is untracked
# files alone is worktree-unique data like the gitignored guard's, so sweep
# treats it as a guard SKIP that --force drops; any modified/staged tracked
# file keeps the row DIRTY and out of the sweep.
# action_for's case that matters is the locked-unlock prefix landing on
# MERGED/ABANDONED only, never changing any other bucket's command.
# parse_porcelain_blocks's case that matters is a real parser bug this PR
# fixed (a stray `have_block || return 0` silently ran "have_block" as a
# command instead of testing the variable, and every block was dropped) —
# this fixture is the regression test that bug needed.
#
# derive_worktree_facts's f_merged_local case runs against a real throwaway
# git repo (mktemp, like tests/test-check-prose-only.sh): a branch that never
# diverged from default (HEAD == default's own commit) must never count as
# merged_local (B6) even though `merge-base --is-ancestor` is trivially true
# for it; a branch with its own commit, folded into default by a real local
# merge, still must.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo_dir/bin/worktrees"

pass=0
fail=0

# case_ <label> <live> <dirty> <prunable> <pr_state> <unpushed> <merged_local> <want-bucket>
case_() {
    local label="$1" live="$2" dirty="$3" prunable="$4" pr_state="$5" unpushed="$6" merged_local="$7" want="$8"
    local got
    got=$(classify_worktree "$live" "$dirty" "$prunable" "$pr_state" "$unpushed" "$merged_local")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-46s -> %s\n' "$label" "$got"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-46s -> got [%s] want [%s]\n' "$label" "$got" "$want"
        fail=$(( fail + 1 ))
    fi
}

echo "── sourcing bin/worktrees ran no report (main is guarded)"
if declare -f classify_worktree >/dev/null && declare -f usage >/dev/null \
    && declare -f action_for >/dev/null && declare -f parse_porcelain_blocks >/dev/null; then
    printf '  ok   %s\n' "functions available after sourcing"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n' "classify_worktree/usage/action_for/parse_porcelain_blocks not defined by sourcing"
    fail=$(( fail + 1 ))
fi

echo "── one bucket at a time (everything else false/none)"
case_ "live"                        true  false false none    false false LIVE
case_ "dirty"                       false true  false none    false false DIRTY
case_ "prunable"                    false false true  none    false false PRUNABLE
case_ "merged (pr state)"           false false false MERGED  false false MERGED
case_ "merged (local ancestor)"     false false false none    false true  MERGED
case_ "abandoned (pr closed)"       false false false CLOSED  false false ABANDONED
case_ "in-review (pr open)"         false false false OPEN    false false IN-REVIEW
case_ "parked (no PR, unpushed)"    false false false none    true  false PARKED
case_ "parked (pr unknown, unpushed)" false false false unknown true false PARKED
case_ "shipped? (no PR, pushed)"    false false false none    false false "SHIPPED?"
case_ "shipped? (pr unknown, pushed)" false false false unknown false false "SHIPPED?"

echo "── precedence: first match wins"
case_ "live beats everything"       true  true  true  MERGED  true  true  LIVE
case_ "dirty beats prunable+merged" false true  true  MERGED  true  true  DIRTY
case_ "prunable beats merged"       false false true  CLOSED  false false PRUNABLE
case_ "merged beats abandoned"      false false false CLOSED  false true  MERGED
case_ "merged (local) beats in-review" false false false OPEN false true  MERGED
case_ "abandoned beats in-review"   false false false CLOSED  false false ABANDONED
case_ "in-review beats parked"      false false false OPEN    true  false IN-REVIEW
case_ "parked beats shipped?"       false false false none    true  false PARKED

# action_for_ <label> <bucket> <locked> <want>
#   repo/path/branch are fixed dummy strings — only bucket/locked vary.
action_for_() {
    local label="$1" bucket="$2" locked="$3" want="$4"
    local got
    got=$(action_for "$bucket" /repo /repo/wt branchname "$locked")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %s\n' "$label"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %s\n       got  [%s]\n       want [%s]\n' "$label" "$got" "$want"
        fail=$(( fail + 1 ))
    fi
}

echo "── action_for: locked prefixes MERGED/ABANDONED with an unlock, nothing else"
action_for_ "merged, unlocked -> points at the sweep verb (the actor)" MERGED false \
    "worktrees sweep --apply  (removes every MERGED row; dry-run without --apply, -v shows each command)"
action_for_ "merged, locked -> same (the sweep unlocks itself)" MERGED true \
    "worktrees sweep --apply  (removes every MERGED row; dry-run without --apply, -v shows each command)"

echo "── where_for: agent / wt tag, else the shortened path"
for probe in "/r/proj/.claude/worktrees/agent-1|agent" "/r/proj.feat-x|wt" "/r/elsewhere/proj|/r/elsewhere/proj"; do
    if [[ "$(where_for "${probe%%|*}" /r/proj)" == "${probe##*|}" ]]; then
        printf '  ok   %s -> %s\n' "${probe%%|*}" "${probe##*|}"; pass=$(( pass + 1 ))
    else
        printf '  FAIL %s got [%s] want [%s]\n' "${probe%%|*}" "$(where_for "${probe%%|*}" /r/proj)" "${probe##*|}"; fail=$(( fail + 1 ))
    fi
done

echo "── shorten: repo-relative inside the repo, ~-shortened elsewhere"
if [[ "$(shorten /r/proj/.claude/worktrees/agent-1 /r/proj)" == ".claude/worktrees/agent-1" ]]; then
    printf '  ok   %s\n' "path under the repo -> relative to it"; pass=$(( pass + 1 ))
else
    printf '  FAIL %s got [%s]\n' "repo-relative shorten" "$(shorten /r/proj/.claude/worktrees/agent-1 /r/proj)"; fail=$(( fail + 1 ))
fi
if [[ "$(HOME=/h shorten /h/dev/proj.feat-x /h/dev/proj)" == "~/dev/proj.feat-x" ]]; then
    printf '  ok   %s\n' "sibling worktree -> ~-shortened"; pass=$(( pass + 1 ))
else
    printf '  FAIL %s got [%s]\n' "sibling shorten" "$(HOME=/h shorten /h/dev/proj.feat-x /h/dev/proj)"; fail=$(( fail + 1 ))
fi
action_for_ "abandoned, unlocked -> plain wt remove -D" ABANDONED false \
    "wt -C /repo remove -D branchname  (confirm first — deletes an unmerged branch)"
action_for_ "abandoned, locked -> unlock && wt remove -D" ABANDONED true \
    "git -C /repo worktree unlock /repo/wt && wt -C /repo remove -D branchname  (confirm first — deletes an unmerged branch)"
action_for_ "live, locked -> bucket unaffected, no unlock prefix" LIVE true \
    "keep — in use"
action_for_ "prunable, locked -> bucket unaffected, no unlock prefix" PRUNABLE true \
    "git -C /repo worktree prune"

echo "── parse_porcelain_blocks: fixture (worktree/HEAD/branch/locked/prunable/detached, main-worktree skip, trailing flush)"
# on_worktree_block is what the real script defines AFTER the BASH_SOURCE
# guard (never reached by sourcing), so this test's own definition is the
# only one in play — it just records its arguments instead of touching
# git/gh, exercising the parser in total isolation from the real machine.
pb_calls=()
on_worktree_block() {
    pb_calls+=("$1|$2|$3|$4|$5")
}

pb_fixture=$(cat <<'FIXTURE'
worktree /repo
HEAD aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
branch refs/heads/main

worktree /repo/wt1
HEAD bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
branch refs/heads/feature/x

worktree /repo/wt2
HEAD cccccccccccccccccccccccccccccccccccccccc
detached

worktree /repo/wt3
HEAD dddddddddddddddddddddddddddddddddddddddd
branch refs/heads/locked-branch
locked custom lock reason

worktree /repo/wt4
HEAD 0000000000000000000000000000000000000000
prunable gitdir file points to non-existent location
FIXTURE
)

parse_porcelain_blocks /repo <<< "$pb_fixture"

pb_want=(
    "/repo/wt1|feature/x|false|false|bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    "/repo/wt2||false|false|cccccccccccccccccccccccccccccccccccccccc"
    "/repo/wt3|locked-branch|true|false|dddddddddddddddddddddddddddddddddddddddd"
    "/repo/wt4||false|true|0000000000000000000000000000000000000000"
)
pb_got_joined=$(printf '%s\n' "${pb_calls[@]}")
pb_want_joined=$(printf '%s\n' "${pb_want[@]}")
if [[ "$pb_got_joined" == "$pb_want_joined" ]]; then
    printf '  ok   %s\n' "main worktree skipped; branch/detached/locked/prunable blocks all parsed; trailing block flushed"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       want:\n%s\n       got:\n%s\n' "parse_porcelain_blocks fixture" "$pb_want_joined" "$pb_got_joined"
    fail=$(( fail + 1 ))
fi

echo "── summarize_at_risk: collapse to one line per top-level component"
# 3 data-test files + a root file + a two-file dir -> a data-test count line,
# the bare root file verbatim, and a logs count line; order = first appearance.
sar_in=$'data-test/a/users.yaml\ndata-test/b/users.yaml\ndata-test/c/x.json\n.env\nlogs/app.jsonl\nlogs/err.log'
sar_want=$'        data-test/  (3 files)\n        .env\n        logs/  (2 files)'
sar_got=$(printf '%s\n' "$sar_in" | summarize_at_risk)
if [[ "$sar_got" == "$sar_want" ]]; then
    printf '  ok   %s\n' "3 data-test + a root file + a 2-file dir -> 3 collapsed lines"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       want:\n%s\n       got:\n%s\n' "summarize_at_risk collapse" "$sar_want" "$sar_got"
    fail=$(( fail + 1 ))
fi
# A blank line is dropped; a single file under a dir still reads "(1 file)".
sar_got2=$(printf '%s\n' $'data/only.yaml\n\n' | summarize_at_risk)
if [[ "$sar_got2" == "        data/  (1 file)" ]]; then
    printf '  ok   %s\n' "blank line dropped; singular 'file'"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       got [%s]\n' "summarize_at_risk singular/blank" "$sar_got2"
    fail=$(( fail + 1 ))
fi

echo "── derive_worktree_facts: f_merged_local (B6)"
dtmp=$(mktemp -d "${TMPDIR:-/tmp}/test-worktrees.XXXXXX") || exit 1
trap 'rm -rf "$dtmp"' EXIT

wd="$dtmp/repo"
mkdir -p "$wd"
git -C "$wd" init -q -b main 2>/dev/null || { echo "git init failed"; exit 1; }
git -C "$wd" config user.email test@example.invalid
git -C "$wd" config user.name "worktrees test"
echo one > "$wd/f"
git -C "$wd" add f
git -C "$wd" commit -qm one

GH_OK=false
repo="$wd"
default_ref="main"

zero_sha=$(git -C "$wd" rev-parse main)
derive_worktree_facts "$wd" "zero-commit-branch" false "$zero_sha"
if [[ "$f_merged_local" == false ]]; then
    printf '  ok   %s\n' "branch never diverged (HEAD == default) -> not merged_local"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       got f_merged_local=%s want false\n' "branch never diverged" "$f_merged_local"
    fail=$(( fail + 1 ))
fi

git -C "$wd" checkout -qb real main
echo two >> "$wd/f"
git -C "$wd" add f
git -C "$wd" commit -qm two
real_sha=$(git -C "$wd" rev-parse real)
git -C "$wd" checkout -q main
git -C "$wd" merge -q --no-ff real -m merge

derive_worktree_facts "$wd" "real" false "$real_sha"
if [[ "$f_merged_local" == true ]]; then
    printf '  ok   %s\n' "branch with its own commit, folded in by a real merge -> merged_local"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       got f_merged_local=%s want true\n' "genuinely merged branch" "$f_merged_local"
    fail=$(( fail + 1 ))
fi

# main has moved on (the merge commit); a branch created back at "one" with
# no commits of its own is an ancestor of main AND differs from main's current
# commit — only its reflog (creation point == HEAD) says it never had work.
git -C "$wd" branch stale "$zero_sha"
derive_worktree_facts "$wd" "stale" false "$zero_sha"
if [[ "$f_merged_local" == false ]]; then
    printf '  ok   %s\n' "zero-commit branch whose base default has since advanced -> not merged_local (reflog)"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n       got f_merged_local=%s want false\n' "zero-commit branch, default advanced" "$f_merged_local"
    fail=$(( fail + 1 ))
fi

# ============================================================================
# sweep half
# parse_copy_ignored_excludes / classify_ignored_file / worktree_ignored_at_risk
# / sweep_is_removable — the pure guard behind bin/worktrees (sweep half)'s "safe to
# delete this gitignored entry?" and "safe to remove this worktree?" decisions.
# Offline: it SOURCES bin/worktrees (sweep half), whose BASH_SOURCE guard hands back
# the guard functions and stops before the sweep (no wt, no gh, no real
# machine worktree). Most cases use plain files under a mktemp dir; the
# worktree_ignored_at_risk integration cases need a real (throwaway) git repo
# to exercise actual `git ls-files` behavior, built the same way as
# tests/test-check-prose-only.sh's fixture.
#
#   tests/test-worktrees.sh
#
# The classify_ignored_file cases that matter: a regenerable cache (a segment
# in sweep_excludes, at any depth) is safe-cache and never content-checked
# (L2: only when that segment names a DIRECTORY — a gitignored FILE that
# happens to share a cache's name is not); a plain file is safe-copy ONLY when
# byte-identical to the hub's copy (a copied-in file the worktree later
# edited must fall through to at-risk, or the sweep would silently drop the
# edit); a file absent from the hub is at-risk; a non-cache, non-.feature/
# ignored DIRECTORY is "recurse", never dropped as a whole unit (B7) — the
# caller (worktree_ignored_at_risk) must expand it and compare its files
# individually. The parse_copy_ignored_excludes case that matters: the
# exclude list is READ from worktrunk.toml (multi-line or inline array),
# never copied — an absent section yields nothing, which degrades the guard
# to pure content comparison (more skips, never an unsafe removal); a
# trailing `#` comment (even one that itself contains quoted words, or looks
# like a `[step.copy-ignored]` header) must never contribute tokens (B2). The
# worktree_ignored_at_risk cases that matter: a `git ls-files` failure fails
# CLOSED — printed as at-risk, never silently "nothing found" (B1); a
# byte-identical nested file inside a non-cache directory is safe, one that
# differs or is missing from the hub is at-risk BY ITS OWN PATH, not the
# directory's (B7); a non-ASCII filename byte-identical to the hub is safe
# even though plain `ls-files` would octal-quote it (L5, needs `-z`).
# sweep_is_removable's case that matters: MERGED is removable only when the
# worktree has no local-only commits (B3).

ok()   { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad()  { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp" "$dtmp"' EXIT

ok()   { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad()  { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

echo "── sourcing bin/worktrees ran no sweep either (main is guarded)"
if declare -f parse_copy_ignored_excludes >/dev/null \
    && declare -f classify_ignored_file >/dev/null \
    && declare -f worktree_ignored_at_risk >/dev/null; then
    ok "guard functions available after sourcing"
else
    bad "functions not defined by sourcing" "parse_copy_ignored_excludes/classify_ignored_file/worktree_ignored_at_risk missing"
fi

echo "── parse_copy_ignored_excludes: reads the [step.copy-ignored] exclude array"
multiline="$tmp/multiline.toml"
cat > "$multiline" <<'TOML'
post-switch = "x"
[step.copy-ignored]
exclude = [
  "node_modules",
  ".venv",
  "build",
]
[other.section]
exclude = ["should-not-appear"]
TOML
got=$(parse_copy_ignored_excludes "$multiline" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv,build," ]]; then
    ok "multi-line array parsed; later section's exclude ignored"
else
    bad "multi-line array" "got [$got] want [node_modules,.venv,build,]"
fi

inline="$tmp/inline.toml"
cat > "$inline" <<'TOML'
[step.copy-ignored]
exclude = ["node_modules", ".venv"]
TOML
got=$(parse_copy_ignored_excludes "$inline" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv," ]]; then
    ok "inline array parsed"
else
    bad "inline array" "got [$got] want [node_modules,.venv,]"
fi

got=$(parse_copy_ignored_excludes "$tmp/does-not-exist.toml"; echo "rc=$?")
if [[ "$got" == "rc=0" ]]; then
    ok "missing toml -> empty, rc 0 (guard falls back to content compare)"
else
    bad "missing toml" "got [$got]"
fi

nosection="$tmp/nosection.toml"
printf 'post-switch = "x"\n' > "$nosection"
got=$(parse_copy_ignored_excludes "$nosection")
if [[ -z "$got" ]]; then
    ok "no [step.copy-ignored] section -> empty"
else
    bad "no section" "got [$got]"
fi

echo "── parse_copy_ignored_excludes: B2 — a trailing comment contributes nothing"
commented="$tmp/commented.toml"
cat > "$commented" <<'TOML'
# [step.copy-ignored]
exclude = ["decoy"]
[step.copy-ignored]
exclude = [
  "node_modules",  # was "cache" before
  ".venv",
]
TOML
got=$(parse_copy_ignored_excludes "$commented" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv," ]]; then
    ok "commented-out header ignored; trailing comment's quoted words never harvested"
else
    bad "commented exclude line" "got [$got] want [node_modules,.venv,]"
fi

indented="$tmp/indented.toml"
printf '  [step.copy-ignored]\n  exclude = ["dist"]\n' > "$indented"
got=$(parse_copy_ignored_excludes "$indented" | tr '\n' ',')
if [[ "$got" == "dist," ]]; then
    ok "indented table header (legal TOML) still matched"
else
    bad "indented header" "got [$got] want [dist,]"
fi

echo "── classify_ignored_file: cache / copied-in / at-risk"
# A hub and a worktree with a spread of gitignored entries.
hub="$tmp/hub"; wt="$tmp/wt"
mkdir -p "$hub" "$wt"
sweep_excludes=("node_modules" ".venv" "build")

# identical copied-in file
printf 'SHARED=1\n' > "$hub/.env"
printf 'SHARED=1\n' > "$wt/.env"
# copied-in file the worktree then edited
printf 'A=1\n' > "$hub/.config"
printf 'A=1\nB=2\n' > "$wt/.config"
# file unique to the worktree
printf 'data\n' > "$wt/local.db"

# case_ <label> <relpath> <want>
case_() {
    local label="$1" rel="$2" want="$3" got
    got=$(classify_ignored_file "$rel" "$wt" "$hub")
    if [[ "$got" == "$want" ]]; then
        ok "$label -> $got"
    else
        bad "$label" "got [$got] want [$want]"
    fi
}

case_ "cache dir (top level)"        "node_modules/"          safe-cache
case_ "cache dir (nested segment)"   "packages/x/.venv/"      safe-cache
case_ "file identical to hub"        ".env"                   safe-copy
case_ "copied-in file since edited"  ".config"                at-risk
case_ "file absent from hub"         "local.db"               at-risk
case_ "non-cache directory (not .feature/)" "data-test/"       recurse
case_ ".feature/ pipeline state"     ".feature/"               safe-cache

echo "── _seg_is_cache (L2): gitignore-style trailing slash; files never match"
sweep_excludes=("node_modules" ".venv" "build/")
case_ "exclude entry with trailing slash still matches a dir"  "build/"  safe-cache
printf 'not a cache\n' > "$hub/build"
printf 'not a cache\n' > "$wt/build"
case_ "gitignored FILE named like a cache dir is not safe-cache" "build" safe-copy
sweep_excludes=("node_modules" ".venv" "build")

echo "── worktree_ignored_at_risk: real-git integration (B1, B7, L5)"
gitwt="$tmp/gitwt"
mkdir -p "$gitwt"
git -C "$gitwt" init -q -b main 2>/dev/null || { echo "git init failed"; exit 1; }
git -C "$gitwt" config user.email test@example.invalid
git -C "$gitwt" config user.name "worktrees test"
printf '*\n' > "$gitwt/.gitignore"
git -C "$gitwt" add -f .gitignore
git -C "$gitwt" commit -qm baseline

# a non-cache directory, byte-identical to the hub -> whole dir is safe
mkdir -p "$gitwt/mydir" "$hub/mydir"
printf 'same\n' > "$gitwt/mydir/file.txt"
printf 'same\n' > "$hub/mydir/file.txt"

# a non-cache directory with one file that differs from the hub (B7: the
# AT-RISK entry must be the nested file's own path, not the directory's)
mkdir -p "$gitwt/mydir2" "$hub/mydir2"
printf 'same\n' > "$gitwt/mydir2/same.txt"
printf 'same\n' > "$hub/mydir2/same.txt"
printf 'worktree edit\n' > "$gitwt/mydir2/changed.txt"
printf 'hub original\n' > "$hub/mydir2/changed.txt"

# .feature/ pipeline state, no hub counterpart at all -> always safe
mkdir -p "$gitwt/.feature"
printf 'scratch state\n' > "$gitwt/.feature/notes.md"

# a non-ASCII filename byte-identical to the hub (L5: plain `ls-files`
# octal-quotes this under core.quotePath, breaking a naive hub lookup)
printf 'café\n' > "$gitwt/café.env"
printf 'café\n' > "$hub/café.env"

at_risk=$(worktree_ignored_at_risk "$gitwt" "$hub")
if [[ "$at_risk" == *"mydir2/changed.txt"* ]]; then
    ok "nested at-risk file surfaced by its own path (mydir2/changed.txt)"
else
    bad "nested at-risk file" "got [$at_risk], want it to contain mydir2/changed.txt"
fi
if [[ "$at_risk" != *"mydir/file.txt"* && "$at_risk" != *"mydir2/same.txt"* ]]; then
    ok "nested files identical to the hub are not at-risk"
else
    bad "identical nested files wrongly at-risk" "got [$at_risk]"
fi
if [[ "$at_risk" != *".feature"* ]]; then
    ok ".feature/ pipeline state is never at-risk"
else
    bad ".feature/ wrongly at-risk" "got [$at_risk]"
fi
if [[ "$at_risk" != *"café.env"* ]]; then
    ok "byte-identical non-ASCII filename (café.env) is not at-risk"
else
    bad "café.env wrongly at-risk" "got [$at_risk]"
fi

echo "── worktree_ignored_at_risk: B1 — a git failure fails CLOSED"
notarepo="$tmp/notarepo"
mkdir -p "$notarepo"
at_risk=$(worktree_ignored_at_risk "$notarepo" "$hub")
if [[ -n "$at_risk" ]]; then
    ok "git ls-files failure (not a git repo) -> non-empty at-risk output, never silently safe"
else
    bad "git failure should fail closed" "got empty at-risk output"
fi

echo "── sweep_is_removable (B3): MERGED is removable only without local-only commits"
if sweep_is_removable MERGED false; then
    ok "MERGED, not unpushed -> removable"
else
    bad "MERGED not-unpushed" "expected removable"
fi
if ! sweep_is_removable MERGED true; then
    ok "MERGED, but unpushed local commits -> NOT removable"
else
    bad "MERGED unpushed" "expected NOT removable"
fi
if ! sweep_is_removable PARKED false; then
    ok "non-MERGED bucket -> never removable here"
else
    bad "PARKED bucket" "expected NOT removable"
fi
if sweep_is_removable MERGED true MERGED abc123 abc123; then
    ok "merged PR, worktree AT the PR head -> removable even with origin/<branch> gone"
else
    bad "MERGED at PR head" "expected removable"
fi
if ! sweep_is_removable MERGED false MERGED abc123 def456; then
    ok "merged PR, worktree NOT at the PR head -> NOT removable even when nothing is unpushed"
else
    bad "MERGED off PR head" "expected NOT removable"
fi
if sweep_is_removable MERGED false MERGED "" def456; then
    ok "merged PR but head unknown -> falls back to the unpushed rule"
else
    bad "MERGED unknown head" "expected removable via unpushed rule"
fi
# merged_local (6th arg): contained in the local default ref vouches on its
# own — an unpushed branch name over commits already in main is a stale label.
if sweep_is_removable MERGED true none "" abc123 true; then
    ok "merged_local=true, unpushed, no PR -> removable (contained in main)"
else
    bad "MERGED merged_local unpushed" "expected removable"
fi
if sweep_is_removable MERGED false MERGED abc123 def456 true; then
    ok "merged_local=true overrides a PR-head mismatch -> removable"
else
    bad "MERGED merged_local past PR-head mismatch" "expected removable"
fi
if ! sweep_is_removable MERGED true none "" abc123 false; then
    ok "merged_local=false, unpushed, no PR -> NOT removable (unchanged)"
else
    bad "MERGED not-merged_local unpushed" "expected NOT removable"
fi

echo "── sweep_would_kill_own_session (P3): only the session named after the worktree"
# shellcheck source=/dev/null
source "$repo_dir/bin/project-dirs-lib"
tmux() { printf '%s\n' "$STUB_SESSION"; }
session_name_for_branch myrepo feat/x
p3_name="$session_name"
if TMUX=stub STUB_SESSION="$p3_name" sweep_would_kill_own_session /r/myrepo /r/myrepo.feat-x feat/x; then
    ok "current session is the worktree's own -> detected"
else
    bad "P3 same session" "expected detection for session [$p3_name]"
fi
if ! TMUX=stub STUB_SESSION=elsewhere sweep_would_kill_own_session /r/myrepo /r/myrepo.feat-x feat/x; then
    ok "current session is another -> not detected"
else
    bad "P3 other session" "expected no detection"
fi
if ! TMUX= STUB_SESSION="$p3_name" sweep_would_kill_own_session /r/myrepo /r/myrepo.feat-x feat/x; then
    ok "outside tmux -> not detected"
else
    bad "P3 no tmux" "expected no detection"
fi
unset -f tmux

echo "── sweep_remove_cmd (L1): dry-run rendering matches what remove_worktree runs"
got=$(sweep_remove_cmd /repo /repo/wt branchname false)
want='wt -C /repo remove --foreground --no-delete-branch branchname && git -C /repo branch -D branchname'
if [[ "$got" == "$want" ]]; then
    ok "unlocked, branch present -> plain remove + branch delete"
else
    bad "sweep_remove_cmd unlocked" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd /repo /repo/wt branchname true)
want='git -C /repo worktree unlock /repo/wt && wt -C /repo remove --foreground --no-delete-branch branchname && git -C /repo branch -D branchname'
if [[ "$got" == "$want" ]]; then
    ok "locked -> unlock prefix, same remove + branch delete"
else
    bad "sweep_remove_cmd locked" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd /repo /repo/wt "" false)
want='wt -C /repo remove --foreground --no-delete-branch /repo/wt'
if [[ "$got" == "$want" ]]; then
    ok "detached (no branch) -> targets by path, no branch delete"
else
    bad "sweep_remove_cmd detached" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd "/my repo" "/my repo/wt x" "" true)
want='git -C /my\ repo worktree unlock /my\ repo/wt\ x && wt -C /my\ repo remove --foreground --no-delete-branch /my\ repo/wt\ x'
if [[ "$got" == "$want" ]]; then
    ok "paths with spaces are shell-quoted (paste-safe)"
else
    bad "sweep_remove_cmd quoting" "got [$got] want [$want]"
fi

got=$(sweep_remove_cmd /repo /repo/wt branchname false true)
want='wt -C /repo remove --foreground --no-delete-branch -f branchname && git -C /repo branch -D branchname'
if [[ "$got" == "$want" ]]; then
    ok "dirty (untracked-only, --force) -> wt remove -f, same branch delete"
else
    bad "sweep_remove_cmd dirty" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd /repo /repo/wt branchname false false)
if [[ "$got" != *" -f "* ]]; then
    ok "dirty=false -> no -f (the default stays the dirty-refusing remove)"
else
    bad "sweep_remove_cmd dirty=false" "got [$got], must not carry -f"
fi

echo "── porcelain_untracked_only: untracked entries alone, and nothing else, count"
if porcelain_untracked_only $'?? uv.lock\n?? reports/'; then
    ok "all ?? lines -> true"
else
    bad "porcelain untracked" "expected true for two ?? lines"
fi
if ! porcelain_untracked_only $'?? uv.lock\n M src/app.py'; then
    ok "a modified tracked file among them -> false"
else
    bad "porcelain modified" "expected false when a line is not ??"
fi
if ! porcelain_untracked_only $'A  new.py'; then
    ok "staged-only -> false (tracked now, not untracked)"
else
    bad "porcelain staged" "expected false for a staged add"
fi
if ! porcelain_untracked_only ""; then
    ok "empty porcelain (clean) -> false, never 'untracked-only'"
else
    bad "porcelain empty" "expected false for empty input"
fi

echo "── merged_under_untracked: the sweep's look-through and the report's -v hint"
f_dirty=true; f_untracked_only=true; f_pr_state=MERGED; f_unpushed=false; f_merged_local=false
if merged_under_untracked false; then
    ok "dirty, untracked-only, PR merged -> looks through to MERGED"
else
    bad "look-through merged PR" "expected true"
fi
f_pr_state=OPEN
if ! merged_under_untracked false; then
    ok "dirty, untracked-only, PR open -> not merged, stays DIRTY"
else
    bad "look-through open PR" "expected false"
fi
f_pr_state=MERGED; f_untracked_only=false
if ! merged_under_untracked false; then
    ok "dirty with modified tracked files, PR merged -> stays DIRTY"
else
    bad "look-through modified" "expected false when dirt is not untracked-only"
fi
f_untracked_only=true; f_pr_state=none; f_merged_local=true
if merged_under_untracked false; then
    ok "dirty, untracked-only, folded into local default -> MERGED"
else
    bad "look-through merged_local" "expected true"
fi
f_dirty=false
if ! merged_under_untracked false; then
    ok "not dirty at all -> false (a clean MERGED row is not this case)"
else
    bad "look-through clean" "expected false"
fi
unset f_dirty f_untracked_only f_pr_state f_unpushed f_merged_local
got=$(action_for DIRTY /repo /repo/wt branchname false true)
if [[ "$got" == "worktrees sweep --force --apply"* ]]; then
    ok "action_for DIRTY sweepable -> points at sweep --force"
else
    bad "action_for DIRTY sweepable" "got [$got]"
fi
got=$(action_for DIRTY /repo /repo/wt branchname false)
if [[ "$got" == "keep — inspect: git -C /repo/wt status" ]]; then
    ok "action_for DIRTY default -> keep, inspect (unchanged)"
else
    bad "action_for DIRTY default" "got [$got]"
fi

echo "── B5: a clean --apply run (no removals, no failures) exits 0"
if ! command -v wt >/dev/null 2>&1; then
    ok "skipped (wt not on PATH)"
elif ! command -v lsof >/dev/null 2>&1; then
    ok "skipped (lsof not on PATH — --apply refuses to run without it)"
else
    # No projects at all: the run goes straight to the summary/exit path.
    b5_conf="$tmp/b5-search-dirs.sh"
    printf 'search_dirs=()\n' > "$b5_conf"
    b5_out=$(PROJECT_DIRS_LOCAL="$b5_conf" HOME="$tmp" bash "$repo_dir/bin/worktrees" sweep --apply --offline 2>&1)
    b5_rc=$?
    if [[ $b5_rc -eq 0 ]]; then
        ok "clean --apply run (0 repos, 0 removals, 0 failures) exits 0"
    else
        bad "clean --apply run exit code" "got rc=$b5_rc, want 0; output:
$b5_out"
    fi
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
