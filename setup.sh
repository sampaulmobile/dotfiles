#!/bin/bash

DOTFILES=~/dotfiles

echo "Linking up (available) dotfiles..."
$DOTFILES/links.sh

echo "Installing homebrew..."
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Tapping caskroom..."
brew tap caskroom/cask

echo "Installing VIm + MacVIm (Make sure XCode is installed/run)"
brew install vim
brew install macvim

echo "Installing the Silver Searcher"
brew install the_silver_searcher

echo "Installing Chrome..."
brew cask install google-chrome

echo "Installing iTerm2..."
brew cask install iterm2

echo "Installing Dropbox..."
brew cask install dropbox

echo "Installing iStat-Menus..."
brew cask install istat-menus

echo "Installing Dash..."
brew cask install dash

echo "Installing Slack..."
brew cask install slack

echo "Installing 1password..."
brew cask install 1password

echo "Installing Witch..."
brew cask install witch

echo "Installing VLC..."
brew cask install vlc

echo "Installing RVM... (+Ruby 2.2.5)"
\curl -sSL https://get.rvm.io | bash
source /Users/sampaul/.rvm/scripts/rvm
rvm install ruby-2.2.5

# echo "Installing uTorrent..."
# brew cask install utorrent
# echo "Installing Skype..."
# brew cask install skype
# echo "Installing HipChat..."
# brew cask install hipchat

# echo "Setting up GIT"
# ssh-keygen -t rsa -b 4096 -C "sampaulmobile@gmail.com"
# pbcopy < ~/.ssh/id_rsa.pub
# echo "key copied to clipboard, paste into https://github.com/settings/ssh"

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cd ~ && vim +PluginInstall +qall

echo "Installing ZSH..."
brew install zsh
echo "Setting ZSH to default shell..."
sudo chsh -s /bin/zsh

echo "Installing Oh-My-ZSH..."
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

