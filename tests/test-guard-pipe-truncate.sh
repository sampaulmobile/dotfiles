#!/usr/bin/env bash
#
# bin/claude-guard-pipe-truncate is a PreToolUse(Bash) hook that denies
# "expensive command | head/tail" (rule A) and "pipefail + | head/tail"
# (rule B), in the command string and in any executed .sh file. This feeds
# it hook payloads and checks whether it denies. The regex has been rewritten
# twice for false positives/negatives; every case below is a shape that has
# actually mattered, so keep them all green.
#
#   tests/run.sh          (or run this file directly with bash)
#
# Run it via run.sh from inside Claude Code: the guard scans any .sh file a
# Bash command names, and this file contains `pipefail` and `| head` as test
# data, so a command that names it directly is itself denied by rule B.

set -o pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
guard="$repo/bin/claude-guard-pipe-truncate"

work=$(mktemp -d "${TMPDIR:-/tmp}/guard-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0

# verdict <command> -> prints "deny" or "allow"
verdict() {
    local out
    out=$(jq -nc --arg c "$1" --arg d "$work" '{tool_input:{command:$c},cwd:$d}' | "$guard" 2>/dev/null)
    if [[ "$out" == *'"permissionDecision":"deny"'* ]]; then echo deny; else echo allow; fi
}

# expect <deny|allow> <command>
expect() {
    local want="$1" cmd="$2" got
    got=$(verdict "$cmd")
    if [[ "$got" == "$want" ]]; then
        printf '  ok   %-5s %s\n' "$want" "${cmd//$'\n'/⏎}"
        pass=$(( pass + 1 ))
    else
        printf '  FAIL %-5s %s\n       got: %s\n' "$want" "${cmd//$'\n'/⏎}" "$got"
        fail=$(( fail + 1 ))
    fi
}

echo "rule A: expensive command piped straight into head/tail"
expect deny  'uv run pytest | head -20'
expect deny  'uv run pytest 2>&1 | tail -20'                  # the 2>&1 & must not break the match
expect deny  'uv run pytest tests/ -q 2>&1 | tail -40'
expect deny  'npm test 2>&1 | tail -5'
expect deny  'cd repo && pytest | tail'
expect deny  'FOO=1 pytest | tail'                            # env assignment prefix
expect deny  'time uv run pytest | tail'                      # time/sudo prefix
expect deny  './bin/pytest.sh | head'                         # path prefix + script suffix
expect deny  'make test | tail -3'
expect deny  'docker build . | tail'
expect deny  'cargo test 2>&1 | tail'
expect deny  'if pytest | head -1; then echo ok; fi'          # shell keyword prefix
expect deny  $'uv run pytest \\\n  -q | tail'                 # backslash continuation
expect deny  $'uv run pytest |\n  tail -5'                    # pipe continuation

echo "rule A: not the footgun"
expect allow 'cat pytest.sh | head'                           # expensive word as an argument
expect allow 'gh pr create --body "run uv run pytest"; git log | head'   # quoted body, unrelated head
expect allow $'uv run pytest\ngit log | head'                 # separate lines, separate commands
expect allow 'docker ps | head'                               # cheap subcommand
expect allow 'go version | head -1'
expect allow 'gofmt -l . | head'                              # go is a prefix, not the command
expect allow 'uvicorn app:app | head'
expect allow 'uv pip list | head'
expect allow 'uv run pytest 2>&1 | tee out.log | tail -20'    # tee keeps the full output
expect allow 'uv run pytest > out.log 2>&1; tail -60 out.log' # file capture, then slice
expect allow 'git log --oneline | head -5'
expect allow ''

echo "rule B: pipefail + head/tail"
expect deny  'set -o pipefail; ./run.sh | tail -3'
expect deny  'set -euo pipefail; ls | head'
expect deny  'set -e -o pipefail; ./run.sh | head'
expect allow 'set -euo pipefail; ls'
expect allow 'echo "we avoid pipefail here"; git log | head -3'   # the word alone is not the footgun
expect allow 'grep -n pipefail bin/*.sh | head'

echo "executed .sh files are scanned"
printf '#!/bin/bash\nset -euo pipefail\nfind . | head -1\n' > "$work/recon.sh"
printf '#!/bin/bash\nuv run pytest 2>&1 | tail -20\n'       > "$work/quick.sh"
printf '#!/bin/bash\nuv run pytest > out.log 2>&1\n'        > "$work/fine.sh"
printf '#!/bin/bash\n# no pipefail on purpose, see above\nls | head\n' > "$work/comment.sh"
expect deny  './recon.sh'                                     # rule B inside the script
expect deny  'bash quick.sh'                                  # rule A inside the script
expect allow './fine.sh'
expect allow './missing.sh'
expect allow './comment.sh'                                   # pipefail only in a comment

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
