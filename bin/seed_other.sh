#!/bin/bash
# seed_other.sh — create each other/**/<name> from its tracked <name>.example
# when the real file is missing. Never overwrites. Called by setup.sh and by
# symlink_files.sh (so a rerun on an existing machine fills any gaps), and
# safe to run by hand.
#
#   seed_other.sh           create missing files, then apply settings drift
#   seed_other.sh --check   report only — missing files + settings drift,
#                           nothing written; exit 1 if anything is flagged
#                           (this is what bin/doctor runs)
#
# The copy happens once, so a default added to an .example LATER never reaches
# a machine that already has the real file. For the one structured file where
# that matters, settings.json, the run ends with bin/claude-settings-check: in
# write mode it runs --apply (adds the gaps), in --check mode it only reports
# them and names --apply as the fix.
set -euo pipefail

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

check=0
[[ "${1:-}" == "--check" || "${1:-}" == "-n" ]] && check=1

created=0 existing=0 missing=0
for example in "$DOTFILES"/other/*.example \
               "$DOTFILES"/other/claude/*.example \
               "$DOTFILES"/other/codex/*.example; do
    [[ -f "$example" ]] || continue
    target="${example%.example}"
    rel="${target#"$DOTFILES"/}"
    if [[ -e "$target" ]]; then
        existing=$((existing + 1))
    elif (( check )); then
        echo "  MISSING  $rel  (fix: bin/seed_other.sh, then edit it)"
        missing=$((missing + 1))
    else
        cp "$example" "$target"
        echo "  created  $rel  (from $(basename "$example") — edit it)"
        created=$((created + 1))
    fi
done
if (( check )); then
    echo "seed_other: $missing missing, $existing present"
else
    echo "seed_other: $created created, $existing already present"
fi

# settings.json drift — only meaningful once the live file exists (a missing
# one was just reported above, or just created from the example = no drift).
# --check stays read-only (reports + names the fix); write mode applies the
# gaps, and a failed apply is printed but does not fail this run, so
# symlink_files.sh keeps linking.
drift=0
if [[ -f "$DOTFILES/other/claude/settings.json" ]]; then
    if (( check )); then
        "$DOTFILES/bin/claude-settings-check" || drift=1
    else
        "$DOTFILES/bin/claude-settings-check" --apply || true
    fi
fi

if (( check )) && (( missing > 0 || drift )); then
    exit 1
fi
exit 0
