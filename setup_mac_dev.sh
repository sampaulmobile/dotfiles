#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# run setup_mac.sh
# $DOTFILES/setup_mac.sh

# install dev brews
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_mac_dev

# install YouCompleteMe
# $DOTFILES/bin/install_ycm.sh

# setup zsh git prompt
$DOTFILES/bin/zsh_git_prompt.sh

# restart to install rvm
# $DOTFILES/bin/install_rvm.sh
# $DOTFILES/bin/rvm_installs.sh

# setup 1password/dropbox, then link rest of dotfiles
# $DOTFILES/bin/symlink_files.sh

# ssh-add SSH keys (if applicable)
# ssh-add -K ~/.ssh/id_rsa_air
