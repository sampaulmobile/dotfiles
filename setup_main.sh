#!/bin/bash

OPT_DIR=/usr/local/opt

# DOTFILES / LINKING

$HOME/dotfiles/links.sh

# add SSH keys somewhere
# ssh-add them too

# INSTALLS

xcode-select --install

if [ ! -f /usr/local/bin/brew ]; then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew install zsh
brew install vim
brew install macvim
brew install the_silver_searcher
brew install awscli
brew install pyenv
brew install postgresql

brew install fzf
$(brew --prefix)/opt/fzf/install

brew install ripgrep

brew services start postgresql

echo "Tapping caskroom..."
brew tap caskroom/cask

brew cask install java
brew cask install google-chrome
brew cask install iterm2
brew cask install dropbox
brew cask install slack
brew cask install 1password
brew cask install istat-menus
brew cask install dash
brew cask install witch
brew cask install vlc
brew cask install divvy


# CONFIGURATION

if [ "$SHELL" != "/usr/local/bin/zsh" ]; then
    echo "Setting ZSH to default shell..."
    sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
fi

if [ ! -d $HOME/.pyenv ]; then
    echo "Installing Python 3.5.2"
    PYTHON_CONFIGURE_OPTS="--enable-framework" pyenv install 3.5.2
    pyenv global 3.5.2
fi

if [ ! -f $HOME/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core.so ]; then
    echo "Building/installing YouCompleteMe..."
    cd $HOME/.vim/bundle/YouCompleteMe
    ./install.py
    cd
fi

if [ ! -f /usr/local/bin/psql ]; then
    echo "Setting up postgres..."
    createuser $USER -P -s
fi

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing Oh-My-ZSH..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# echo "Updating git-prompt..."
# rm -rf $OPT_DIR/zsh-git-prompt
if [ ! -d $OPT_DIR/zsh-git-prompt ]; then
    echo "Installing git-prompt..."
    git clone https://github.com/olivierverdier/zsh-git-prompt.git $OPT_DIR/zsh-git-prompt

    # setup prompt to use haskell for 4x+ speed
    curl -sSL https://get.haskellstack.org/ | sh
    cd $OPT_DIR/zsh-git-prompt
    stack setup
    stack build && stack install
fi

# restart to install rvm

if [ ! -d $HOME/.rvm ]; then
    echo "Installing RVM... (+Ruby 2.2.5)"
    \curl -sSL https://get.rvm.io | bash
    source $HOME/.rvm/scripts/rvm
    rvm install ruby-2.2.5
fi

