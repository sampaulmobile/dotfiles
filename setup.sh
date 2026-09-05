#!/bin/bash

# Bootstrap order on a fresh Mac:
#   1. `git clone https://github.com/sampaulmobile/dotfiles.git ~/dotfiles`
#      (macOS prompts to install the Xcode Command Line Tools on first git use)
#   2. `cd ~/dotfiles && ./setup.sh`
#   3. machines needing the supplemental Brewfile: `./setup_other.sh` afterwards
# The xcode-select call below no-ops if the CLT are already installed.

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront, and keep them alive for the whole run (the cache
# expires after 5 idle minutes; brew and pkg-installer casks need sudo late).
# The background loop dies with the script via the kill -0 check.
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &

# accept xcode command line tools terms
echo "Accepting xcode command line tools terms"
xcode-select --install

# install rosetta (for intel based apps)
echo "Installing rosetta"
sudo softwareupdate --install-rosetta --agree-to-license

# change macOS configs/defaults
echo "Updating macOS configs/defaults"
$DOTFILES/bin/macos_defaults.sh

# brew (and installs)
echo "Installing brew"
$DOTFILES/bin/install_brew.sh
echo "Initializing brew"
eval $(/opt/homebrew/bin/brew shellenv)
echo "Running brew bundle"
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_mac

# install node
eval "$(fnm env)"
echo "installing node"
fnm install 22
fnm default 22

# claude code (npm globals are per-node-version under fnm — re-run this
# after switching the default node)
echo "Installing claude code"
npm install -g @anthropic-ai/claude-code

# seed machine-local config from templates (real files are gitignored).
# symlink_files.sh runs this too, but do it explicitly here so the output
# shows up in the setup log.
echo "Seeding other/ machine-local config"
$DOTFILES/bin/seed_other.sh

echo "Symlinking dotfiles"
$DOTFILES/bin/symlink_files.sh

echo "Installing Rectangle config"
$DOTFILES/bin/setup_rectangle.sh

# set shell (assuming ZSH has been installed)
echo "Setting default shell to zsh"
$DOTFILES/bin/set_zsh_mac.sh
echo "Installing oh-my-zsh"
$DOTFILES/bin/install_oh_my_zsh.sh

# setup zsh
echo "Installing zsh syntax highlighting"
$DOTFILES/bin/install_zsh_syntax_highlighting.sh

# install TPM/plugins
echo "Installing TPM"
$DOTFILES/bin/install_tpm.sh
echo "Updating TPM plugins"
$DOTFILES/bin/update_tpm_plugins.sh

echo ""
echo "===== Done. Manual steps remaining ====="
echo "  - edit other/*.local (git identity, claude model, project dirs — see other/README.md)"
echo "  - if macos_defaults skipped the zoom settings: grant the terminal Full Disk"
echo "    Access (Privacy & Security), relaunch it, re-run bin/macos_defaults.sh -f"
echo "  - gh auth login"
echo "  - bin/setup_github_ssh_key.sh (per-machine SSH key for github)"
echo "  - claude (first run: log in)"
echo "  - bin/hq-init (optional: scaffold ~/dev/hq for the /hq dispatcher)"
echo "  - sign in to 1Password"
echo "  - launch Docker.app once to finish its install"
echo "  - supplemental Brewfile (etc/Brewfile_other): ./setup_other.sh"
