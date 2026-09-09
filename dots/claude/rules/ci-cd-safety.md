# CI/CD safety (agents never pull triggers)

- NEVER trigger CI/CD from an agent: no `gh workflow run` / `workflow_dispatch`,
  no `gh run rerun`, no deploy or release workflows, no terraform plan/apply
  jobs, no GitOps syncs — in ANY repo, and doubly so in infrastructure repos
  (terraform / GitOps config). This applies to background pipeline agents
  (/feature and friends) exactly as much as to interactive sessions.
- Evidence for a PR comes from the PR's own CI (push and let it run) or from
  local read-only tooling. If a PR's diff won't be planned/tested by CI, SAY SO
  in the PR body and hand the run to the human — do not find another route.
- Read-only inspection is fine: `gh run list/view`, logs, `terraform show` of
  existing state, plan output already posted by CI.
- If a task seems to require pulling a trigger, STOP and hand that step to the
  user with the exact command they would run.
