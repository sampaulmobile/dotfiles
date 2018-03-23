#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# accept xcode command line tools terms
xcode-select --install

# change macOS configs/defaults
$DOTFILES/bin/macos_defaults.sh

# brew (and installs)
$DOTFILES/bin/install_brew.sh
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_base
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_mac

# pyenv/pip (and installs)
$DOTFILES/bin/pyenv_installs_mac.sh
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_shell_mac.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh
