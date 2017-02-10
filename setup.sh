#!/bin/bash

DOTFILES=$HOME/dotfiles

# xcode-select --install

echo "Making dock static-only..."
# defaults write com.apple.dock static-only -bool TRUE; killall Dock
echo "Enabling key repeat..."
# defaults write -g ApplePressAndHoldEnabled -bool false
# defaults write -g InitialKeyRepeat -int 15
# defaults write -g KeyRepeat -int 2

echo "Linking up (available) dotfiles..."
$DOTFILES/links.sh

echo "Brew / Cask installing stuff..."

if [ ! -f /usr/local/bin/brew ]; then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if [ ! -f /usr/local/bin/mvim ]; then
    echo "Installing VIm + MacVIm (Make sure XCode is installed/run)"
    brew install vim
    brew install macvim
    brew install gpg
fi

if [ ! -f /usr/local/bin/consul ]; then
    brew install consul
fi

if [ ! -f /usr/local/bin/jq ]; then
    brew install jq
fi

if [ ! -f /usr/local/bin/psql ]; then
    brew install postgresql
    brew services start postgresql
    # createuser sampaul -P -s
fi

if [ ! -f /usr/local/bin/redis-server ]; then
    brew install redis
    brew services start redis
fi

if [ ! -f /usr/local/bin/mongo ]; then
    brew install mongo
    brew services start mongodb
    # db.createUser({user: "sampaul", pwd: "password", roles: ["readWrite"]})
    # mongo admin -u admin -p admin --eval "db.getSiblingDB('docurated').addUser('sampaul', 'password')"
fi


if [ ! -d '/usr/local/Cellar/the_silver_searcher' ]; then
    echo "Installing the Silver Searcher"
    brew install the_silver_searcher
fi

echo "Tapping caskroom..."
brew tap caskroom/cask

if [ ! -d "/Applications/Google Chrome.app" ]; then
    echo "Installing Chrome..."
    brew cask install google-chrome
fi

if [ ! -d "/Applications/iTerm.app" ]; then
    echo "Installing iTerm2..."
    brew cask install iterm2
fi

if [ ! -d "/Applications/Dropbox.app" ]; then
    echo "Installing Dropbox..."
    brew cask install dropbox
fi

if [ ! -d "/Applications/Slack.app" ]; then
    echo "Installing Slack..."
    brew cask install slack
fi

if [ ! -d "/Applications/1Password 6.app" ]; then
    echo "Installing 1password..."
    brew cask install 1password
fi

if [ ! -d "/Applications/iStat Menus.app" ]; then
    echo "Installing iStat-Menus..."
    brew cask install istat-menus
fi

if [ ! -d "/Applications/Dash.app" ]; then
    echo "Installing Dash..."
    brew cask install dash
fi

if [ ! -d "/usr/local/Caskroom/witch" ]; then
    echo "Installing Witch..."
    brew cask install witch
fi

if [ ! -d "/Applications/VLC.app" ]; then
    echo "Installing VLC..."
    brew cask install vlc
fi

if [ ! -d "/Applications/Tunnelblick.app" ]; then
    echo "Installing Tunnelblick..."
    brew cask install tunnelblick
fi

if [ ! -d $HOME/.pyenv ]; then
    echo "Installing pyenv... (+Python 3.5.2)"
    brew install pyenv
    pyenv install 3.5.2
    pyenv global 3.5.2
fi

if [ ! -d $HOME/.vim/bundle/Vundle.vim ]; then
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi

echo "Updating vundle plugins..."
cd $HOME && vim +PluginUpdate +qall

if [ ! -f /bin/zsh ]; then
    echo "Installing ZSH..."
    brew install zsh
    echo "Setting ZSH to default shell..."
    sudo chsh -s /bin/zsh
fi

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing Oh-My-ZSH..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# restart to install rvm

if [ ! -d $HOME/.rvm ]; then
    echo "Installing RVM... (+Ruby 2.2.5)"
    \curl -sSL https://get.rvm.io | bash
    source $HOME/.rvm/scripts/rvm
    rvm install ruby-2.2.5
fi

# install java

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

