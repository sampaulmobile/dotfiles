
# this assumes ZSH has been installed

zsh_path=$(which zsh | head -n 1)
if [ "$SHELL" != $zsh_path ]; then
    echo "Setting ZSH to default shell..."
    chsh -s $zsh_path
fi

if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing Oh-My-ZSH..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

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
