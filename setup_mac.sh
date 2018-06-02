#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront
sudo -v

# accept xcode command line tools terms
xcode-select --install

# change macOS configs/defaults
$DOTFILES/bin/macos_defaults.sh

# brew (and installs)
$DOTFILES/bin/install_brew.sh
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_mac

# pyenv/pip (and installs)
$DOTFILES/bin/pyenv_installs_mac.sh
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/pip_installs.sh

# link all non-dropbox files (except .oh-my-zsh)
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# set shell (assuming ZSH has been installed)
$DOTFILES/bin/set_zsh_mac.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# link .oh-my-zsh theme
$DOTFILES/bin/symlink_files.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh
