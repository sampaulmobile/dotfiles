#!/bin/bash

# Supplemental setup layered on top of setup.sh — installs the extra
# packages some machines need. All machine-local config (including claude
# skills/rules) is handled by setup.sh + other/ (see other/README.md).

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

eval $(/opt/homebrew/bin/brew shellenv)
echo "Running brew bundle (Brewfile_other)"
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_other

echo ""
echo "===== Done. Manual steps remaining ====="
echo "  - fill in other/*.local values (model env, TLS certs, project dirs, git identity)"
echo "  - configure SSO / VPN / access tooling per company docs"
echo "  - clone project repos"
echo "  - migrating from an old machine? copy its other/ folder over (AirDrop a tarball)"
