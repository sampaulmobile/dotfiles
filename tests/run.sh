#!/usr/bin/env bash
#
# Run every test in this directory. All of them are offline and side-effect
# free: no tmux server is started or touched, no agent is launched, nothing
# outside a mktemp dir is written.
#
#   tests/run.sh
#
# macOS ships bash 3.2 as /bin/bash and the library must keep working there,
# so each suite runs under /bin/bash as well as the default bash on PATH.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

suites=(test-classify.sh test-notify.sh test-codex-rollout.sh test-agent-ttys.sh
        test-fzf-expect.sh test-guard-pipe-truncate.sh test-settings-check.sh
        test-project-dirs.sh test-worktree-doctor.sh test-check-prose-only.sh)
shells=(/bin/bash bash)

failed=0
for shell in "${shells[@]}"; do
    command -v "$shell" >/dev/null 2>&1 || continue
    # single quotes on purpose: $BASH_VERSION must expand in the TARGET shell
    # shellcheck disable=SC2016
    ver=$("$shell" -c 'echo $BASH_VERSION')
    for suite in "${suites[@]}"; do
        printf '\n═══ %s (%s %s)\n' "$suite" "$shell" "$ver"
        "$shell" "$here/$suite" || failed=1
    done
done

echo
if (( failed )); then
    echo "SOME TESTS FAILED"
    exit 1
fi
echo "all tests passed"
