#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront
sudo -v

# accept xcode command line tools terms
echo "Accepting xcode command line tools terms"
xcode-select --install

# install rosetta (for intel based apps)
echo "Installing rosetta"
# softwareupdate --install-rosetta

# change macOS configs/defaults
echo "Updating macOS configs/defaults"
$DOTFILES/bin/macos_defaults.sh

# brew (and installs)
echo "Installing brew"
$DOTFILES/bin/install_brew.sh
echo "Initializing brew"
eval $(/opt/homebrew/bin/brew shellenv)
echo "Running brew bundle"
brew bundle --no-upgrade --file=$DOTFILES/etc/Brewfile_m1

# install node
# source /opt/homebrew/opt/nvm/nvm.sh  # This loads nvm
source /usr/local/opt/nvm/nvm.sh  # This loads nvm
echo "installing node"
nvm install --lts

# pyenv/pip (and installs)
# $DOTFILES/bin/pyenv_installs_mac.sh
# eval "$(pyenv init -)"
# $DOTFILES/bin/install_pip.sh
# $DOTFILES/bin/pip_installs.sh

# link all non-dropbox files (except .oh-my-zsh)
echo "Symlinking dotfiles"
$DOTFILES/bin/symlink_files.sh

# vim (and plugs)
echo "Installing vim plug for nvim"
$DOTFILES/bin/install_vim_plug_neo.sh
echo "Running vim plug update"
$DOTFILES/bin/update_vim_plugs_neo.sh

# set shell (assuming ZSH has been installed)
echo "Setting default shell to zsh"
$DOTFILES/bin/set_zsh_mac.sh
echo "Installing oh-my-zsh"
$DOTFILES/bin/install_oh_my_zsh.sh

# link .oh-my-zsh theme
echo "Symlinking dotfiles"
$DOTFILES/bin/symlink_files.sh

# setup zsh
echo "Installing zsh syntax highlighting"
$DOTFILES/bin/install_zsh_syntax_highlighting.sh
echo "Installing zsh git prompt"
$DOTFILES/bin/install_zsh_git_prompt.sh

# install TPM/plugins
echo "Installing TPM"
$DOTFILES/bin/install_tpm.sh
echo "Updating TPM plugins"
$DOTFILES/bin/update_tpm_plugins.sh
