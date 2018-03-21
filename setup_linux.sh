#!/bin/bash

DOTFILES=$HOME/dotfiles

# brew (and installs)
$DOTFILES/bin/install_linuxbrew.sh
brew bundle --no-upgrade --file=$DOTFILES/links/Brewfile_basic

# pip (and installs)
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/links.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_plugs.sh
# $DOTFILES/bin/install_ycm.sh

# shell (zsh)
# $DOTFILES/bin/set_shell_linux.sh
# $DOTFILES/bin/oh_my_zsh.sh

# /etc/hosts (blacklist)
# $DOTFILES/bin/hosts.sh
