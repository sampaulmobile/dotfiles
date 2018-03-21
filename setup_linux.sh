#!/bin/bash

DOTFILES=$HOME/dotfiles

# brew (and installs)
$DOTFILES/bin/install_linuxbrew.sh
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_base

# pip (and installs)
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_shell_linux.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh
