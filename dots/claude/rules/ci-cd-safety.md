# CI/CD safety (agents never pull triggers)

- NEVER trigger CI/CD from an agent: no `gh workflow run` / `workflow_dispatch`,
  no `gh run rerun`, no deploy or release workflows, no terraform plan/apply
  jobs, no GitOps syncs — in ANY repo, and doubly so in infrastructure repos
  (terraform / GitOps config). This applies to background pipeline agents
  (/feature and friends) exactly as much as to interactive sessions.
- Exception: run — never type by hand — a deploy wrapper script, and only
  the exact invocation the repo it deploys names in its own CLAUDE.md as
  sanctioned (the script is checked into that repo; it may accept other
  invocations the repo does not vouch for). The script must enforce an
  environment boundary in code: every environment beyond the one it
  deliberately leaves unguarded for automation refuses outright, before
  prompting, with no terminal attached — the unguarded path itself runs
  headless, which is what makes it usable here. Not license for anything
  the script calls internally (`gh workflow run` included) or any other
  trigger typed directly.
- Evidence for a PR comes from the PR's own CI (push and let it run) or from
  local read-only tooling. If a PR's diff won't be planned/tested by CI, SAY SO
  in the PR body and hand the run to the human — do not find another route.
- Read-only inspection is fine: `gh run list/view`, logs, `terraform show` of
  existing state, plan output already posted by CI.
- Outside that exception, if a task seems to require pulling a trigger, STOP
  and hand that step to the user with the exact command they would run.
