# Output truncation (don't lose long-running job output)

- NEVER pipe an expensive or long-running command (test suites, builds,
  deploys, `cdk`/`flutter`/`uv run`/`npm`/`make`, full `redis-cli SCAN`, load
  tests, anything that does real work) directly into `head`/`tail`/a `sed`
  range. You throw away the rest of the output, and with `set -o pipefail`
  the closed pipe (SIGPIPE) can abort the job itself.
- Instead capture the FULL output to a file, then slice the file — this loses
  nothing and is cheap to re-inspect:
  `./bin/pytest.sh > /tmp/out.log 2>&1; tail -60 /tmp/out.log`
  (or `<cmd> 2>&1 | tee /tmp/out.log | tail -60`).
- `head`/`tail` piped directly is only fine on cheap, instantly-repeatable
  sources: `cat` of a file, `ls`, `git log`, an already-saved log.
- Inside scripts: never combine `set -o pipefail` with a `| head`/`| tail`
  stage — `head` closing the pipe early SIGPIPEs the upstream, pipefail
  promotes it to a failure, and `set -e` aborts the script mid-run.
- Enforcement: a global PreToolUse(Bash) hook
  (`~/dotfiles/bin/claude-guard-pipe-truncate`) blocks these patterns in the
  command string and in any executed `.sh` file. The hook is a backstop, not
  a licence to lean on it — follow the rule directly.
