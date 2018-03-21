#!/bin/bash

DOTFILES=$HOME/dotfiles

# brew (and installs)
$DOTFILES/bin/linuxbrew.sh
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_basic

# pip (and installs)
$DOTFILES/bin/pip.sh

# link (some) dotfiles
$DOTFILES/bin/links.sh

# vim (and plugs)
$DOTFILES/bin/vim.sh

# shell (zsh)
# $DOTFILES/bin/shell_linux.sh

# /etc/hosts (blacklist)
# $DOTFILES/bin/hosts.sh
