if [ $# -eq 0 ] && [ -d $HOME/.oh-my-zsh ]; then
	echo "oh-my-zsh already installed, exiting"
	exit 0
fi

# KEEP_ZSHRC=yes stops the installer from replacing ~/.zshrc (our symlink)
# with the oh-my-zsh template on fresh machines.
KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
