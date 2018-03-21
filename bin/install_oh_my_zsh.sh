if [ ! -d $HOME/.oh-my-zsh ]; then
    echo "Installing Oh-My-ZSH..."
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
