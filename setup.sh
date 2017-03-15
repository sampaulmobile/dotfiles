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
brew install gpg
brew install the_silver_searcher

brew install consul
brew install jq
brew install awscli

brew install scala
brew install apache-spark
brew install cmake

brew install pyenv

brew install postgresql
brew install redis
brew install mongo

brew install solr
brew install sbt
brew install terraform

brew install rabbitmq

brew services start postgresql
brew services start mongodb
brew services start redis

brew services start rabbitmq


if [ ! -d /usr/local/opt/solr ]; then
    SOLR_PATH=/usr/local/opt/solr
    DOC_CONFIG_PATH=$SOLR_PATH/server/solr/configsets/doc_configs
    DEMO_SOLR_HOST=demo-solr-2.zookeeper.1
    DEMO_SOLR_PATH=/opt/solr/zookeeper/default

    mkdir -p $DOC_CONFIG_PATH
    scp -r $DEMO_SOLR_HOST:$DEMO_SOLR_PATH $DOC_CONFIG_PATH/conf
    $SOLR_PATH/bin/solr start -c

    $SOLR_PATH/server/scripts/cloud-scripts/zkcli.sh -z localhost:9983 -cmd upconfig -confdir $DOC_CONFIG_PATH/conf -confname docconf
    curl 'http://localhost:8983/solr/admin/cores?action=CREATE&name=space&collection=space&collection.configName=docconf'
    curl 'http://localhost:8983/solr/admin/cores?action=CREATE&name=spacestile&collection=spacestile&collection.configName=docconf'
    curl 'http://localhost:8983/solr/admin/cores?action=CREATE&name=default&collection=default&collection.configName=docconf'
    $SOLR_PATH/bin/solr stop -all
    $SOLR_PATH/bin/solr start -c
fi

if [ ! -d /usr/local/opt/arcanist ]; then
    git clone https://github.com/phacility/libphutil.git /usr/local/opt/libphutil
    git clone https://github.com/phacility/arcanist.git /usr/local/opt/arcanist

    arc set-config default https://phabricator.docurated.rocks
    arc install-certificate https://phabricator.docurated.rocks/
fi


echo "Tapping caskroom..."
brew tap caskroom/cask


if [ ! -f /usr/bin/java ]; then
    echo "Installing Java..."
    brew cask install java
fi

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

# if [ ! -d "/Applications/Docker.app" ]; then
#     brew cask install docker
# fi

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

if [ ! -d $HOME/.vim/bundle/Vundle.vim ]; then
    echo "Installing Vundle..."
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
fi
cd $HOME && vim +PluginClean! +PluginUpdate +qall

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

if [ ! -f /usr/local/bin/mongo ]; then
    echo "Setting up mongo..."
    # use docurated
    # db.createUser({user: "sampaul", pwd: "password", roles: ["readWrite"]})
    # mongo admin -u admin -p admin --eval "db.getSiblingDB('docurated').addUser('sampaul', 'password')"
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

