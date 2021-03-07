if [ $# -eq 0 ] && [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
	echo "vim plug already installed for nvim, exiting"
	exit 1
fi

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
