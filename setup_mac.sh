#!/bin/bash

DOTFILES=$HOME/dotfiles

# accept xcode command line tools terms
xcode-select --install

# change macOS configs/defaults
$DOTFILES/bin/macos.sh

# brew (and installs)
$DOTFILES/bin/brew.sh
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_basic
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_mac

# pip (and installs)
$DOTFILES/bin/pip.sh

# link (some) dotfiles
$DOTFILES/bin/links.sh

# vim (and plugs)
$DOTFILES/bin/vim.sh

# shell (zsh)
$DOTFILES/bin/shell.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/hosts.sh

# restart to install rvm
$DOTFILES/bin/rvm.sh

# setup 1password/dropbox, then link rest of dotfiles
# $DOTFILES/links.sh

# ssh-add SSH keys (if applicable)
# ssh-add -K ~/.ssh/id_rsa_air
