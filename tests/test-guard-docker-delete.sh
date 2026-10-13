#!/usr/bin/env bash
#
# bin/claude-guard-docker-delete is a PreToolUse(Bash) hook that denies
# docker commands that destroy volumes or prune docker state. This feeds it
# hook payloads and checks whether it denies, in the command string and in
# any executed .sh file.
#
#   tests/run.sh          (or run this file directly with bash)

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
guard="$repo/bin/claude-guard-docker-delete"

work=$(mktemp -d "${TMPDIR:-/tmp}/docker-guard-test.XXXXXX")
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

echo "blocked: compose down/rm with -v or --volumes"
expect deny  'docker compose -f docker-compose.yml down -v'
expect deny  'docker compose down --volumes'
expect deny  'docker compose down --remove-orphans -v'               # reordered flag
expect deny  'docker compose -v down'                                 # flag before subcommand
expect deny  'docker-compose down -v'                                 # standalone binary spelling
expect deny  'docker compose rm -v -f web'
expect deny  'docker-compose rm -v'
expect deny  'DOCKER COMPOSE DOWN -V'                                 # case-insensitive
expect deny  'echo hi && docker compose down -v'                      # chained, second command bad

echo "blocked: volume rm/prune, container rm -v, and the prune family"
expect deny  'docker volume rm myvol'
expect deny  'docker volume prune -f'
expect deny  'docker system prune -af'
expect deny  'docker image prune -a'
expect deny  'docker container prune'
expect deny  'docker builder prune'
expect deny  'docker network prune'
expect deny  'docker rm -v mycontainer'
expect deny  'docker rm --volumes mycontainer'

echo "allowed: the forms the blocked ones are mistaken for"
expect allow 'docker compose down'                                    # no -v: fine
expect allow 'docker compose up -d'
expect allow 'docker compose ps'
expect allow 'docker compose logs -f web'
expect allow 'docker compose config'
expect allow 'docker volume ls'
expect allow 'docker volume inspect myvol'
expect allow 'docker system df'
expect allow 'docker images'
expect allow 'rm -v /tmp/somefile'                                    # coreutils rm, no docker at all
expect allow 'docker run --rm -v /host/data:/data myimage'            # -v is a volume MOUNT here
expect allow 'docker run -v /data:/data myimage rm -v /data/old'      # rm is the CONTAINER's own command
expect allow 'docker exec mycontainer rm -v /tmp/file.txt'            # same, via exec
expect allow ''

echo "executed .sh files are scanned"
printf '#!/bin/bash\ndocker compose down -v\n' > "$work/teardown.sh"
printf '#!/bin/bash\ndocker compose down\n'    > "$work/fine.sh"
expect deny  './teardown.sh'
expect deny  'bash teardown.sh'
expect allow './fine.sh'
expect allow './missing.sh'

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
