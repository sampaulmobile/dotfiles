#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# install stuff
sudo apt-get update
sudo apt-get install -y git vim zsh python-pip build-essential

# $DOTFILES/bin/install_linuxbrew.sh

$DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/install_fzf.sh
# $DOTFILES/bin/install_ripgrep.sh

# brews="ripgrep"
# for b in $brews; do brew install $b; done
# brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_base

# pyenv/pip (and installs)
$DOTFILES/bin/pyenv_installs.sh
$DOTFILES/bin/install_pip.sh
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
