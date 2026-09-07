#!/usr/bin/env bash
#
# classify_worktree — the pure classification function behind
# bin/worktree-doctor's per-worktree buckets. Offline: it SOURCES
# bin/worktree-doctor, which hands back classify_worktree (and usage) and
# stops before the report itself (the BASH_SOURCE guard near the top of
# that file), so no git, no gh, no lsof and no real machine worktree is
# ever touched.
#
#   tests/test-worktree-doctor.sh
#
# The case that matters is precedence: LIVE beats DIRTY beats PRUNABLE
# beats MERGED beats ABANDONED beats IN-REVIEW beats PARKED beats SHIPPED?,
# first match wins — so a merged worktree that's still dirty must report
# DIRTY (keep, inspect), never silently look removable.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/worktree-doctor"

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
if declare -f classify_worktree >/dev/null && declare -f usage >/dev/null; then
    printf '  ok   %s\n' "functions available after sourcing"
    pass=$(( pass + 1 ))
else
    printf '  FAIL %s\n' "classify_worktree/usage not defined by sourcing"
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

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
