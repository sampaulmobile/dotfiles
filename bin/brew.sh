
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
brew install ripgrep
brew install fzf
$(brew --prefix)/opt/fzf/install


echo "Tapping caskroom..."
brew tap caskroom/cask

brew cask install java
brew cask install google-chrome
brew cask install iterm2
brew cask install dropbox
brew cask install slack
brew cask install 1password
brew cask install istat-menus
brew cask install witch
brew cask install divvy


brew cask install vlc
brew cask install dash
