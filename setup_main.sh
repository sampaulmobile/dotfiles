#!/bin/bash

# accept xcode command line tools terms
xcode-select --install

# link (some) dotfiles
$HOME/dotfiles/bin/links.sh

# change macOS configs/defaults
$HOME/dotfiles/bin/macos.sh

# brew/pip/vim
$HOME/dotfiles/bin/brew.sh
$HOME/dotfiles/bin/pip.sh
$HOME/dotfiles/bin/vim.sh

# setup shell and /etc/hosts (blacklist)
$HOME/dotfiles/bin/shell.sh
$HOME/dotfiles/bin/hosts.sh

# restart to install rvm
$HOME/dotfiles/bin/rvm.sh

# setup 1password/dropbox, then link rest of dotfiles
# $HOME/dotfiles/links.sh

# ssh-add SSH keys (if applicable)
# ssh-add -K ~/.ssh/id_rsa_air

