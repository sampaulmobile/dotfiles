#!/bin/bash

DOTFILES=$HOME/dotfiles

# accept xcode command line tools terms
xcode-select --install

# change macOS configs/defaults
$DOTFILES/bin/macos_defaults.sh

# brew (and installs)
$DOTFILES/bin/install_brew.sh
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_basic
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_mac

# pip (and installs)
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/links.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_plugs.sh
$DOTFILES/bin/install_ycm.sh

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_shell_mac.sh
$DOTFILES/bin/oh_my_zsh.sh
$DOTFILES/bin/zsh_git_prompt.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh

# restart to install rvm
$DOTFILES/bin/install_rvm.sh

# setup 1password/dropbox, then link rest of dotfiles
# $DOTFILES/links.sh

# ssh-add SSH keys (if applicable)
# ssh-add -K ~/.ssh/id_rsa_air
