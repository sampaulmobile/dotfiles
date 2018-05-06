#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront
sudo -v

# shell (assuming ZSH has been installed)
$DOTFILES/bin/set_zsh_linux.sh
$DOTFILES/bin/install_oh_my_zsh.sh

# install (ghetto) linuxbrew (and *some* brews)
$DOTFILES/bin/install_linuxbrew.sh
brews=(pyenv vim fzf) # if bash, parens should be quotes
for b in $brews; do brew install $b; done

# ripgrep (b/c need to use compiled binary)
$DOTFILES/bin/install_ripgrep.sh

# link dotfiles
$DOTFILES/bin/symlink_files.sh
source $HOME/.zshrc

# pyenv/pip installs
$DOTFILES/bin/pyenv_installs_linux.sh
$DOTFILES/bin/pip_installs.sh

# vim (and plugs)
$DOTFILES/bin/install_vim_plug.sh
$DOTFILES/bin/update_vim_plugs.sh

# dev stuff
# $DOTFILES/bin/install_ycm.sh
# $DOTFILES/bin/zsh_git_prompt.sh
