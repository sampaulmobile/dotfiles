#!/bin/bash

# Supplemental setup layered on top of setup.sh. Everything here is
# content-agnostic: the actual machine-specific files live in other/
# (gitignored — see other/README.md).

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# brew (supplemental packages)
eval $(/opt/homebrew/bin/brew shellenv)
echo "Running brew bundle (Brewfile_other)"
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_other

# machine-local claude skills/rules -> ~/.claude
echo "Symlinking other/claude skills/rules"
mkdir -p $DOTFILES/other/claude/skills $DOTFILES/other/claude/rules
mkdir -p ~/.claude/skills ~/.claude/rules
for skill in $DOTFILES/other/claude/skills/*/; do
    [[ -d "$skill" ]] && ln -sfnv "${skill%/}" ~/.claude/skills/$(basename "$skill")
done
for rule in $DOTFILES/other/claude/rules/*.md; do
    [[ -f "$rule" ]] && ln -sfnv "$rule" ~/.claude/rules/$(basename "$rule")
done

echo ""
echo "===== Done. Manual steps remaining ====="
echo "  - fill in other/*.local values (model env, TLS certs, project dirs, git identity)"
echo "  - drop machine-local claude skills/rules into other/claude/ and re-run this script"
echo "  - configure SSO / VPN / access tooling per company docs"
echo "  - clone project repos"
echo "  - migrating from an old machine? copy its other/ folder over (AirDrop a tarball)"
