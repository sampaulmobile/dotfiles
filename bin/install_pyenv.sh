if [ $# -eq 0 ] && [ -d $HOME/.pyenv ]; then
	echo "pyenv already installed, exiting"
	exit 0
fi

git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
