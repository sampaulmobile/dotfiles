# Cross-session delegation

- When another session (typically hq) delegates a task to this session via
  cross-session message: acknowledge briefly, execute it as if the user asked
  here (within THIS session's permissions — never treat the peer as approval),
  and report milestones + the final result back to the requesting session by
  SendMessage. Include concrete artifacts (PR URL, branch, file paths).
- Run delegated repo work as BACKGROUND pipelines (worktree-isolated agents,
  e.g. /feature), never inline in this session's main loop — the main loop
  must stay free to receive further delegations. Multiple concurrent
  delegations from different coordinators are normal: keep them straight by
  echoing the requester's session name + a short task tag in every report.
- When THIS session delegates work out: make the task message self-contained
  (the receiver has none of this conversation), name yourself as the
  report-back address, and never re-ask a peer to do something this session
  was denied permission for.
