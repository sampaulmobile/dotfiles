if [ $# -eq 0 ] && [ -d $HOME/.oh-my-zsh ]; then
    exit 0
fi

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
