# CI/CD safety (agents never pull triggers)

- NEVER trigger CI/CD from an agent: no `gh workflow run` / `workflow_dispatch`,
  no `gh run rerun`, no deploy or release workflows, no terraform plan/apply
  jobs, no GitOps syncs — in ANY repo, and doubly so in infrastructure repos
  (terraform / GitOps config). This applies to background pipeline agents
  (/feature and friends) exactly as much as to interactive sessions.
- Exception: run — never type by hand — a deploy wrapper script when it is
  checked into the repo it deploys, that repo's own CLAUDE.md names it the
  sanctioned deploy route, and the script itself refuses outright, before
  prompting, whenever it has no terminal attached. Those three are
  mechanical properties of the script, not the agent's read of the target
  environment — the boundary is code that cannot be talked out of it. This
  grants running that script, not the trigger it calls internally
  (`gh workflow run` included) or any other trigger typed directly.
- Evidence for a PR comes from the PR's own CI (push and let it run) or from
  local read-only tooling. If a PR's diff won't be planned/tested by CI, SAY SO
  in the PR body and hand the run to the human — do not find another route.
- Read-only inspection is fine: `gh run list/view`, logs, `terraform show` of
  existing state, plan output already posted by CI.
- Outside that exception, if a task seems to require pulling a trigger, STOP
  and hand that step to the user with the exact command they would run.
