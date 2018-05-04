#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# create user and assign password
# update sshd to reject root login/etc.
# NEW_USER=sam
# adduser $NEW_USER
# adduser $NEW_USER sudo

# NEW_HOSTNAME=sbp_dev
# NEW_IP=45.33.90.186
# hostnamectl set-hostname $NEW_HOSTNAME
# $NEW_IP $NEW_HOSTNAME.com $NEW_HOSTNAME" > /etc/hosts

# install stuff
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git vim zsh wget curl make build-essential
# sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
#     libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev snapd

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_zsh_linux.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# install (ghetto) linuxbrew (and *some* brews)
$DOTFILES/bin/install_linuxbrew.sh
brews="vim pyenv" # ripgrep"
for b in $brews; do brew install $b; done

# fzf/ripgrep (b/c brew installing these is a nightmare)
# $DOTFILES/bin/install_fzf.sh
# $DOTFILES/bin/install_ripgrep.sh

# pyenv/pip (and installs)
# $DOTFILES/bin/install_pyenv.sh
$DOTFILES/bin/install_pip.sh
$DOTFILES/bin/pyenv_installs_linux.sh
$DOTFILES/bin/pip_installs.sh

# link (some) dotfiles
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# /etc/hosts (blacklist)
$DOTFILES/bin/blacklist_hosts.sh
