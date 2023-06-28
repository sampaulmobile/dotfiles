SUGGESTIONS_DIR=$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions

if [ $# -eq 0 ] && [ -d "$SUGGESTIONS_DIR" ]; then
    echo "zsh-autosuggestions plugin already installed, exiting"
    exit 1
fi

git clone https://github.com/zsh-users/zsh-autosuggestions "$SUGGESTIONS_DIR"
