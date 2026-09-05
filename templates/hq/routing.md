# Services routing table

One row per service: pure routing facts (repo path, alerts channel, tracker,
wiki pointer). Deep knowledge lives in the wiki module page, read lazily.
Consumers: the `/hq` dispatch skill (from any shell) and the hq session
(imported by CLAUDE.md). Keep rows ~15 tokens; never add prose paragraphs.

<!-- Row template:
- **Name** (repo-dir-basename) — one-phrase purpose
  repo `~/dev/<dir>` · alerts #<channel> · tracker <PROJECT> · wiki [[module-id]]
-->
