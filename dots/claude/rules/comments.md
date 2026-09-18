# Comments and prose in code

Code here is written and maintained by agents. Comments are read by the next
agent, at token cost, on every visit — so a comment must pay for itself.

- **Record only what the code cannot say.** A comment earns its place when it
  states an invariant, a gotcha, an empirical finding (name the version or
  date it was observed against), or a constraint imposed from outside the
  file (why this path must stay fork-free, why bash 3.2 syntax). The
  constraint must BIND THE CODE — "this must stay fork-free" binds; "this
  lives here because the listener imports it" is a decision about the code
  and belongs in git. Never write what the code does — the code already says
  that. No narrative walkthroughs of the implementation.
- **A docstring is a comment.** It earns its place on the same terms: a
  gotcha, an invariant, a constraint a caller cannot see, or what a return
  value MEANS where the signature does not say it. One that restates the
  name, the signature or the type hints is deleted — `"""Reset the cache."""`
  over `reset_cache()`, an `Args:` block repeating the annotations, a
  `Returns:` line repeating `-> bool`, a test docstring that re-reads its own
  test name. Module and class docstrings state purpose and constraints and
  are usually the ones worth keeping. The exception is an API consumed
  outside the repo, where the docstring IS the reference: write that one
  fully.
- **The decision record is git, not the code.** A changed line states the
  new fact, never why it changed: no `(because ...)`, no `(X is reserved for
  Y)`, no "was Z, now W" appended to a value, default, or setting. A comment
  likewise never justifies the SHAPE of the code — where a module sits, what
  a thing is named, or which alternative was rejected. "Lives in `shared/`
  rather than beside X because X imports the app", "named Y rather than Z
  because the stdlib already exports Z", "we use an exception here so the
  task reaches the DLQ" are all commit-message, PR-body or workplan text.
  This applies to EVERY file an agent edits, not just code: skills, rules,
  CLAUDE.md, READMEs, configs, YAML. Before finishing an edit, reread the
  diff for added parentheticals and justifications and delete them.
- **One home per fact.** Cross-file behavior, architecture and operating
  knowledge live in the repo's CLAUDE.md (or its docs). A local invariant
  lives in ONE comment at the code it protects. A file header states purpose
  and the non-obvious constraints, not a table of contents and not a copy of
  the function comments below it. A gotcha belongs where the thing is
  DEFINED and is not restated at the places that use it; the second copy is
  a pointer or nothing. If changing a fact would mean editing two places,
  one of them is a duplicate — delete it.
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
- **Size guide.** Function comment or docstring: 1–3 lines, longer only for
  a gotcha, and never longer than the code it sits on without one.
  File header: purpose plus constraints. CLAUDE.md entries: what a session
  needs to operate or safely change the thing — invariants, where things
  live, the commands — not how it was built. Reference a USER reads on screen
  (a tool's columns, its key list, output formats, thresholds) lives in the
  tool's `--help` or header; CLAUDE.md points at it. When a paragraph reads
  like a PR description, it belongs in git history, not in the repo.
- **Applies to reviews too.** A reviewer flags comment noise, duplicated
  facts and rotted references the same as any other defect; "the code is
  self-explanatory here — drop the comment" is a valid finding.
