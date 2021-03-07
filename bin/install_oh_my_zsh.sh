if [ $# -eq 0 ] && [ -d $HOME/.oh-my-zsh ]; then
	echo "oh-my-zsh already installed, exiting"
	exit 1
fi

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
