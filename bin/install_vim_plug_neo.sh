if [ $# -eq 0 ] && [ -f ~/.vim/autoload/plug.vim ]; then
    exit 1
fi

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
