#!/usr/bin/env bash
#
# bin/prs's two pure functions — fmt_age (seconds -> short age) and pr_tag
# (the one-tag-per-PR precedence) — plus which half --open-only / --merged-only
# print when the rows come from a snapshot. Offline: SOURCES bin/prs, which
# hands the helpers back and stops before any gh call (the BASH_SOURCE guard),
# and runs the script only against a throwaway HQ_SNAPSHOT_DIR under a fake
# HOME, so no gh call and no real project directory is reached.
#
#   tests/test-prs.sh        # or: bash tests/test-prs.sh

set -o pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/prs-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
# hq-snapshot resolves the directory at source time, so this is set first.
export HQ_SNAPSHOT_DIR="$work/snapshot"

# shellcheck source=/dev/null
source "$repo/bin/prs"

pass=0; fail=0
check() {
    local label="$1" got="$2" want="$3"
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-34s [%s]\n' "$label" "$got"; pass=$((pass + 1))
    else
        printf '  FAIL %-34s got [%s] want [%s]\n' "$label" "$got" "$want"; fail=$((fail + 1))
    fi
}

echo "fmt_age"
check "negative clamps"      "$(fmt_age -5)"       "just now"
check "under a minute"       "$(fmt_age 59)"       "just now"
check "minutes"              "$(fmt_age 300)"      "5m"
check "hours"                "$(fmt_age 7200)"     "2h"
check "days"                 "$(fmt_age 172800)"   "2d"
check "weeks"                "$(fmt_age 1300000)"  "2w"

echo "pr_tag precedence"
check "draft beats everything"       "$(pr_tag true CONFLICTING red APPROVED)"           "draft"
check "merge-conflict beats ci"         "$(pr_tag false CONFLICTING red APPROVED)"          "merge-conflict"
check "ci-red beats approval"        "$(pr_tag false MERGEABLE red APPROVED)"            "ci-red"
check "changes-requested"            "$(pr_tag false MERGEABLE green CHANGES_REQUESTED)" "changes-requested"
check "approved"                     "$(pr_tag false MERGEABLE green APPROVED)"          "approved"
check "review-required"              "$(pr_tag false MERGEABLE green REVIEW_REQUIRED)"   "review-required"
check "unknown mergeable, no review" "$(pr_tag false UNKNOWN none '')"                  "open"

echo "--open-only / --merged-only over a snapshot"
# The snapshot holds BOTH halves whatever the flags; the flags choose which of
# them the render prints, the same choice the live path makes by running only
# one search.
printf '%s\n' \
    "meta"$'\t'"author"$'\t'"@me" \
    "meta"$'\t'"since"$'\t'"$(date +%Y-%m-%d)" \
    "open"$'\t'"org/repo"$'\t'"11"$'\t'"false"$'\t'"MERGEABLE"$'\t'"green"$'\t'"APPROVED"$'\t'"900"$'\t'"an open one"$'\t'"https://example.invalid/11" \
    "merged"$'\t'"org/repo"$'\t'"12"$'\t'"09:30"$'\t'"a merged one"$'\t'"https://example.invalid/12" \
    | snapshot_write prs
run_prs() {
    HOME="$work/home" PROJECT_DIRS_LOCAL=/nonexistent NO_COLOR=1 \
        "$repo/bin/prs" --any-repo "$@" 2>&1
}
shows() {   # shows <label> <output> <needle> <yes|no>
    local got=no
    case "$2" in *"$3"*) got=yes ;; esac
    check "$1" "$got" "$4"
}
out=$(run_prs --open-only)
shows "--open-only keeps the open row"    "$out" "#11" yes
shows "--open-only drops the merged row"  "$out" "#12" no
out=$(run_prs --merged-only)
shows "--merged-only keeps the merged row" "$out" "#12" yes
shows "--merged-only drops the open row"   "$out" "#11" no
out=$(run_prs)
shows "no flag keeps the open row"    "$out" "#11" yes
shows "no flag keeps the merged row"  "$out" "#12" yes

echo; echo "passed $pass, failed $fail"
(( fail == 0 ))
