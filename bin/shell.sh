
if [ "$SHELL" != "/usr/local/bin/zsh" ]; then
    echo "Setting ZSH to default shell..."
    sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
fi

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing Oh-My-ZSH..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

OPT_DIR=/usr/local/opt
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

