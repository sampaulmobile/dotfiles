# Test fixtures

`settings-example.json`, `settings-live-clean.json` and
`settings-live-gappy.json` are the trio `tests/test-settings-check.sh` feeds
to `bin/claude-settings-check`: a cut-down settings.json template, a live file
that differs from it only in non-drift ways (key order, scalar values, local
extras), and one missing a hook, an allowlist entry, a nested key and a whole
object. Hand-written; the command strings are the repo's own `~/dotfiles/bin`
paths.
