#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront
sudo -v

# linuxbrew
$DOTFILES/bin/install_linuxbrew.sh
bin_brew=$HOME/.linuxbrew/bin/brew # so we dont have to restart shell
$bin_brew update
$bin_brew doctor
$bin_brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_linux

# ripgrep (b/c need to use compiled binary)
$DOTFILES/bin/install_ripgrep.sh

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_zsh_linux.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# link dotfiles
$DOTFILES/bin/symlink_files.sh

exit 0

# pyenv/pip installs
$DOTFILES/bin/pyenv_installs_linux.sh
$DOTFILES/bin/pip_installs.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# dev stuff
# $DOTFILES/bin/install_ycm.sh
# $DOTFILES/bin/zsh_git_prompt.sh
