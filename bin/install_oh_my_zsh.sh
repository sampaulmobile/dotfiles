if [ $# -eq 0 ] && [ -d $HOME/.oh-my-zsh ]; then
    exit 1
fi

# sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mriedmann/oh-my-zsh/master/tools/install.sh)"
