# Comments and prose in code

Code here is written and maintained by agents. Comments are read by the next
agent, at token cost, on every visit — so a comment must pay for itself.

- **Record only what the code cannot say.** A comment earns its place when it
  states an invariant, a gotcha, an empirical finding (name the version or
  date it was observed against), or a constraint imposed from outside the
  file (why this path must stay fork-free, why bash 3.2 syntax). Never write
  what the code does — the code already says that. No narrative walkthroughs
  of the implementation.
- **A changed line states the new fact, never why it changed.** No
  `(because ...)`, no `(X is reserved for Y)`, no "was Z, now W" appended to
  a value, default, or setting. The why of a change is the commit message
  and PR body. This applies to EVERY file an agent edits, not just code:
  skills, rules, CLAUDE.md, READMEs, configs, YAML. Before finishing an
  edit, reread the diff for added parentheticals that justify a decision
  and delete them.
- **One home per fact.** Cross-file behavior, architecture and operating
  knowledge live in the repo's CLAUDE.md (or its docs). A local invariant
  lives in ONE comment at the code it protects. A file header states purpose
  and the non-obvious constraints, not a table of contents and not a copy of
  the function comments below it. If changing a fact would mean editing two
  places, one of them is a duplicate — delete it.
- **Never point at ephemeral files.** Pipeline state (`.feature/`), scratch
  dirs, session notes and chat transcripts do not exist for the next reader.
  If the fact matters, write the fact; otherwise write nothing. A pointer to
  a COMMITTED doc (a workplan, a design doc) is fine when it carries the why.
- **A comment inside a quoted program is code.** A `#` line inside a
  single-quoted `jq`/`awk` program or a heredoc is string content to the
  shell: an apostrophe ends the quote, and the program's meaning can change.
  Leave those alone, or re-run the script after touching them.
- **Guard comments are load-bearing — treat deletion as a code change.** A
  comment explaining why a seemingly redundant check exists is the only thing
  stopping the next "simplify" pass from reintroducing the bug. Remove one
  only after verifying the gotcha is gone (a test, a version check), and say
  so in the commit.
- **Size guide.** Function comment: 1–3 lines, longer only for a gotcha.
  File header: purpose plus constraints. CLAUDE.md entries: what a session
  needs to operate or safely change the thing — invariants, where things
  live, the commands — not how it was built. Reference a USER reads on screen
  (a tool's columns, its key list, output formats, thresholds) lives in the
  tool's `--help` or header; CLAUDE.md points at it. When a paragraph reads
  like a PR description, it belongs in git history, not in the repo.
- **Applies to reviews too.** A reviewer flags comment noise, duplicated
  facts and rotted references the same as any other defect; "the code is
  self-explanatory here — drop the comment" is a valid finding.
