#!/bin/bash

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# run setup_mac.sh
$DOTFILES/setup_mac.sh

# INSTALLS
brew install nginx

git clone https://github.com/CouchPotato/CouchPotatoServer.git /Applications/CouchPotatoServer

# brew cask install couchpotato
brew cask install sabnzbd
brew cask install sonarr
brew cask install radarr
brew cask install plex-media-server

# need to start plex/sab/sonnar/cp to generate folders
# copy over backups to each

# copy nginx.conf
# sudo brew services restart nginx
# forward port 80 to 80 in router

# add SSH keys somewhere
# ssh-add them too
