#!/bin/bash

# Supplemental setup layered on top of setup.sh — installs the extra
# packages some machines need. All machine-local config (including claude
# skills/rules) is handled by setup.sh + other/ (see other/README.md).

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

eval $(/opt/homebrew/bin/brew shellenv)
echo "Running brew bundle (Brewfile_other)"
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_other

# register user-scoped MCP servers from other/mcp-servers.local.json
# (no-op if the file doesn't exist; OAuth via /mcp is still manual)
echo "Registering MCP servers"
$DOTFILES/bin/setup_mcp.sh

echo ""
echo "===== Done. Manual steps remaining ====="
echo "  - fill in other/*.local values (model env, TLS certs, project dirs, git identity)"
echo "  - configure SSO / VPN / access tooling per company docs"
echo "  - clone project repos"
echo "  - migrating from an old machine? copy its other/ folder over (AirDrop a tarball)"
