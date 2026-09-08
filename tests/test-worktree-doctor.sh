#!/usr/bin/env bash
#
# classify_worktree/action_for/parse_porcelain_blocks — the pure functions
# behind bin/worktree-doctor's per-worktree buckets, commands and porcelain
# parsing. Offline: it SOURCES bin/worktree-doctor, which hands back all
# three (and usage) and stops before the report itself (the BASH_SOURCE
# guard near the top of that file), so no git, no gh, no lsof and no real
# machine worktree is ever touched.
#
#   tests/test-worktree-doctor.sh
#
# The classify_worktree case that matters is precedence: LIVE beats DIRTY
# beats PRUNABLE beats MERGED beats ABANDONED beats IN-REVIEW beats PARKED
# beats SHIPPED?, first match wins — so a merged worktree that's still dirty
# must report DIRTY (keep, inspect), never silently look removable.
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
source "$repo_dir/bin/worktree-doctor"

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

echo "── sourcing bin/worktree-doctor ran no report (main is guarded)"
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
action_for_ "merged, unlocked -> points at the sweep (the actor)" MERGED false \
    "bin/worktree-sweep --apply  (removes every MERGED row; dry-run without --apply, -v shows each command)"
action_for_ "merged, locked -> same (the sweep unlocks itself)" MERGED true \
    "bin/worktree-sweep --apply  (removes every MERGED row; dry-run without --apply, -v shows each command)"

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

echo "── derive_worktree_facts: f_merged_local (B6)"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/test-worktree-doctor.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT

wd="$tmp/repo"
mkdir -p "$wd"
git -C "$wd" init -q -b main 2>/dev/null || { echo "git init failed"; exit 1; }
git -C "$wd" config user.email test@example.invalid
git -C "$wd" config user.name "worktree-doctor test"
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

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
