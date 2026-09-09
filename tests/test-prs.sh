#!/usr/bin/env bash
#
# bin/prs's two pure functions: fmt_age (seconds -> short age) and pr_tag
# (the one-tag-per-PR precedence). Offline: SOURCES bin/prs, which hands the
# helpers back and stops before any gh call (the BASH_SOURCE guard).
#
#   tests/test-prs.sh        # or: bash tests/test-prs.sh

set -o pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
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

echo; echo "passed $pass, failed $fail"
(( fail == 0 ))
