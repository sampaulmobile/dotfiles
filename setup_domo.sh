#!/bin/bash

# add SSH keys somewhere
# ssh-add them too

# INSTALLS

xcode-select --install

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install zsh
brew install vim

echo "Tapping caskroom..."
brew tap caskroom/cask

brew cask install google-chrome
brew cask install iterm2
# brew cask install witch
brew cask install vlc
brew install nginx

git clone https://github.com/CouchPotato/CouchPotatoServer.git /Applications/CouchPotatoServer

# brew cask install couchpotato
brew cask install sabnzbd
brew cask install sonarr
brew cask install radarr
brew cask install plex-media-server

# CONFIGURATION

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# need to start plex/sab/sonnar/cp to generate folders
# copy over backups to each

# copy nginx.conf

# sudo brew services restart nginx
# forward port 80 to 80 in router



