zsh_path=$(which zsh | head -n 1)
if [ "$SHELL" != $zsh_path ]; then
    echo "Setting ZSH to default shell..."
    sudo chsh -s $zsh_path $USERNAME
fi
