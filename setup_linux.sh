#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# install stuff
sudo apt-get update
sudo apt-get install -y git vim zsh build-essential \
    make libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev snapd

# install (ghetto) linuxbrew (and *some* brews)
$DOTFILES/bin/install_linuxbrew.sh
brews="openssl readline" # zsh vim ripgrep"
for b in $brews; do brew install $b; done
# brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_base

# fzf/ripgrep (b/c brew installing these is a nightmare)
$DOTFILES/bin/install_fzf.sh
# $DOTFILES/bin/install_ripgrep.sh

# pyenv/pip (and installs)
$DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/pyenv_installs_linux.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_zsh_linux.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh
