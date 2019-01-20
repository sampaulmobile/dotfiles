SYNTAX_DIR=$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

if [ $# -eq 0 ] && [ -d "$SYNTAX_DIR" ]; then
    exit 1
fi

git clone git://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
