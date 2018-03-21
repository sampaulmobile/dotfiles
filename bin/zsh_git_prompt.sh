OPT_DIR=/usr/local/opt
if [ ! -d $OPT_DIR/zsh-git-prompt ]; then
    echo "Installing/updating git-prompt..."
    git clone https://github.com/olivierverdier/zsh-git-prompt.git $OPT_DIR/zsh-git-prompt

    # setup prompt to use haskell for 4x+ speed
    curl -sSL https://get.haskellstack.org/ | sh
    cd $OPT_DIR/zsh-git-prompt
    stack setup
    stack build && stack install
fi
