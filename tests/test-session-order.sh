#!/usr/bin/env bash
#
# order_sessions_hub_first over the session lists Ctrl+F can be handed.
# Offline: it SOURCES bin/tmux-sessionizer, which hands back the helpers and
# stops before the picker (the BASH_SOURCE guard near the top of that file),
# so no fzf and no tmux server are involved.
#
#   tests/test-session-order.sh     # or: bash tests/test-session-order.sh
#
# The cases that matter: a hub whose worktree sessions were visited more
# recently must still come out first (fzf scores them identically for a
# repo-name query, so this order IS the ranking); a repo whose own name
# contains an underscore must not be mistaken for a worktree of a hub that is
# not there; sessions of unrelated repos must keep MRU order; and no name may
# ever precede one it hangs off, or the promotion would just move the
# inversion down a level.

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/tmux-sessionizer"

pass=0
fail=0

# expect <label> <space-separated input, MRU order> <space-separated want>
expect() {
    local label="$1" in="$2" want="$3" got
    got=$(printf '%s\n' $in | order_sessions_hub_first | tr '\n' ' ')
    got="${got% }"
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %s\n' "$label"
        pass=$((pass + 1))
    else
        printf '  FAIL %s\n       got  [%s]\n       want [%s]\n' "$label" "$got" "$want"
        fail=$((fail + 1))
    fi
}

echo "── hub promotion"
expect "hub below its own worktrees is promoted above them" \
    "myapp_fix myapp_feat myapp dotfiles" \
    "myapp myapp_fix myapp_feat dotfiles"
expect "worktrees keep MRU order among themselves" \
    "myapp_b myapp_a myapp" \
    "myapp myapp_b myapp_a"
expect "hub already on top is left alone" \
    "myapp myapp_feat dotfiles" \
    "myapp myapp_feat dotfiles"

echo "── names that only look like worktrees"
expect "underscore in a repo name, no hub of that prefix listed" \
    "web_shop dotfiles" \
    "web_shop dotfiles"
expect "underscore repo WITH that prefix listed reads as its worktree" \
    "web_shop web" \
    "web web_shop"

echo "── everything else keeps its place"
expect "unrelated sessions keep MRU order" \
    "base hq dotfiles myapp" \
    "base hq dotfiles myapp"
expect "worktrees with no hub session listed are untouched" \
    "myapp_a myapp_b dotfiles" \
    "myapp_a myapp_b dotfiles"
expect "a promoted group sits where its most recent member sat" \
    "dotfiles myapp_feat myapp base" \
    "dotfiles myapp myapp_feat base"

echo "── a name never precedes one it hangs off"
expect "chain orders root, then middle, then leaf" \
    "a_b_c a_b a dotfiles" \
    "a a_b a_b_c dotfiles"
expect "chain out of order still nests correctly" \
    "a_b_c a a_b" \
    "a a_b a_b_c"

echo "── degenerate input"
expect "one session" "solo" "solo"
if [[ -z "$(printf '' | order_sessions_hub_first)" ]]; then
    printf '  ok   empty input -> empty output\n'
    pass=$((pass + 1))
else
    printf '  FAIL empty input produced output\n'
    fail=$((fail + 1))
fi
if [[ -z "$(printf '\n\n' | order_sessions_hub_first)" ]]; then
    printf '  ok   blank lines are dropped\n'
    pass=$((pass + 1))
else
    printf '  FAIL blank lines survived\n'
    fail=$((fail + 1))
fi

echo
if (( fail )); then
    printf 'FAILED: %d failed, %d passed\n' "$fail" "$pass"
    exit 1
fi
printf 'ok: %d passed\n' "$pass"
