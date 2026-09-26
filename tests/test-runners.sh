#!/usr/bin/env bash
#
# bin/runners' pure helpers, sourced: which runners `start N` / `stop N` act
# on, the release asset name per platform, and the env scrub handed to run.sh.
# Offline: no gh, no pgrep, no runner directories, nothing started.
#
#   tests/test-runners.sh

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

PROJECT_DIRS_LOCAL=/nonexistent
# shellcheck source=/dev/null
source "$repo/bin/runners"

pass=0
fail=0
check() {
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"; pass=$(( pass + 1 ))
    else
        printf '  FAIL %s\n       want: %s\n       got:  %s\n' "$1" "$2" "$3"; fail=$(( fail + 1 ))
    fi
}
plan() { "$@" | tr '\n' ',' ; }

echo "── plan_start"
check "nothing set up: create 1"            "create 1,"                  "$(plan plan_start 1)"
check "nothing set up, start 3"             "create 1,create 2,create 3," "$(plan plan_start 3)"
check "1 running: create 2"                 "create 2,"                  "$(plan plan_start 1 1:running)"
check "both stopped: start 1 only"          "start 1,"                   "$(plan plan_start 1 1:stopped 2:stopped)"
check "stopped before new"                  "start 2,create 3,"          "$(plan plan_start 2 1:running 2:stopped)"
check "unconfigured reused before new"      "start 1,create 2,create 4," "$(plan plan_start 3 1:stopped 2:unconfigured 3:running)"
check "fills the lowest gap"                "create 2,create 4,"         "$(plan plan_start 2 1:running 3:running)"
check "numeric, not lexical"                "start 2,start 10,"          "$(plan plan_start 2 2:stopped 10:stopped)"

echo "── plan_stop"
check "nothing running"                     ""                           "$(plan plan_stop all 1:stopped)"
check "all"                                 "stop 3,stop 1,"             "$(plan plan_stop all 1:running 2:stopped 3:running)"
check "highest first"                       "stop 3,"                    "$(plan plan_stop 1 1:running 2:stopped 3:running)"
check "more than running"                   "stop 2,stop 1,"             "$(plan plan_stop 5 1:running 2:running)"
check "unconfigured never stopped"          "stop 1,"                    "$(plan plan_stop all 1:running 2:unconfigured)"

echo "── runner_asset"
check "macOS arm"                           "osx-arm64"                  "$(runner_asset Darwin arm64)"
check "macOS intel"                         "osx-x64"                    "$(runner_asset Darwin x86_64)"
check "linux aarch64"                       "linux-arm64"                "$(runner_asset Linux aarch64)"
check "unsupported"                         ""                           "$(runner_asset FreeBSD amd64)"

echo "── runner_env_args: the env scrub applied to run.sh"
# The case that matters: AWS_PROFILE must be dropped, or a job that configures
# static AWS credentials fails because the SDK prefers the inherited profile.
runner_env_args
args=" ${runner_env_args_out[*]} "
for v in AWS_PROFILE AWS_DEFAULT_PROFILE AWS_REGION AWS_DEFAULT_REGION \
         AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
    case "$args" in
        *" -u $v "*) printf '  ok   %s is stripped\n' "$v"; pass=$(( pass + 1 )) ;;
        *) printf '  FAIL %s is NOT stripped\n' "$v"; fail=$(( fail + 1 )) ;;
    esac
done
# Every entry must arrive as a `-u <name>` pair, or `env` would read a bare
# name as the command to run.
check "one -u per stripped name"  "$(( ${#runner_env_strip[@]} * 2 ))"  "${#runner_env_args_out[@]}"
pairs_ok=true
for (( i = 0; i < ${#runner_env_args_out[@]}; i += 2 )); do
    [[ "${runner_env_args_out[i]}" == -u ]] || pairs_ok=false
done
check "every even element is -u"  "true"  "$pairs_ok"
# PATH and HOME are deliberately NOT stripped: a job needs the tools and the
# home directory the runner was installed under.
keeps_ok=true
case "$args" in *" -u PATH "*|*" -u HOME "*) keeps_ok=false ;; esac
check "PATH and HOME are kept"    "true"  "$keeps_ok"
check "idempotent across calls"   "${#runner_env_args_out[@]}"  "$(runner_env_args; echo ${#runner_env_args_out[@]})"

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
