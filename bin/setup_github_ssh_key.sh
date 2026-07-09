#!/bin/bash

# Generate a per-machine SSH key for GitHub and walk it into place:
# keygen (if missing) -> ~/.ssh/config block -> agent + macOS keychain ->
# pubkey to clipboard + browser. Idempotent; safe to re-run.
#
# Usage: setup_github_ssh_key.sh [label]
#   label defaults to "<hostname>" — shows up as the key comment on GitHub.

set -e

KEY="$HOME/.ssh/id_ed25519"
LABEL="${1:-$(hostname -s)}"

# 1. generate (skip if present)
if [[ -f "$KEY" ]]; then
    echo "Key already exists at $KEY — skipping keygen"
else
    ssh-keygen -t ed25519 -C "$LABEL" -f "$KEY"
fi

# 2. ssh config block (skip if github.com already configured)
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if grep -qs "Host github.com" ~/.ssh/config; then
    echo "github.com already in ~/.ssh/config — skipping"
else
    cat >> ~/.ssh/config <<EOF

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $KEY
EOF
    chmod 600 ~/.ssh/config
    echo "Added github.com block to ~/.ssh/config"
fi

# 3. load into agent, remember passphrase in macOS keychain
ssh-add --apple-use-keychain "$KEY" 2>/dev/null || ssh-add "$KEY"

# 4. hand the pubkey to GitHub
pbcopy < "$KEY.pub"
echo ""
echo "Public key copied to clipboard. Fingerprint:"
ssh-keygen -lf "$KEY.pub"
echo ""
echo "Opening GitHub — paste the key, then IF THE ORG USES SAML SSO:"
echo "  after adding, click 'Configure SSO' -> Authorize next to the key,"
echo "  or org repos will reject it even though auth 'works'."
open "https://github.com/settings/ssh/new" 2>/dev/null || echo "  -> https://github.com/settings/ssh/new"
echo ""
echo "Verify with: ssh -T git@github.com   (should greet the right username)"
