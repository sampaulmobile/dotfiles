#!/bin/bash
# seed_other.sh — create each other/**/<name> from its tracked <name>.example
# when the real file is missing. Never overwrites. Called by setup.sh and by
# symlink_files.sh (so a rerun on an existing machine fills any gaps), and
# safe to run by hand.
set -euo pipefail

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

created=0 existing=0
for example in "$DOTFILES"/other/*.example \
               "$DOTFILES"/other/claude/*.example \
               "$DOTFILES"/other/codex/*.example; do
    [[ -f "$example" ]] || continue
    target="${example%.example}"
    rel="${target#$DOTFILES/}"
    if [[ -e "$target" ]]; then
        echo "  exists   $rel"
        existing=$((existing + 1))
    else
        cp "$example" "$target"
        echo "  created  $rel  (from $(basename "$example") — edit it)"
        created=$((created + 1))
    fi
done
echo "seed_other: $created created, $existing already present"
