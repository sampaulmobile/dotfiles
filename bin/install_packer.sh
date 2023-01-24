if [ $# -eq 0 ] && [ -f ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]; then
	echo "packer already installed, exiting"
	exit 1
fi

git clone --depth 1 https://github.com/wbthomason/packer.nvim \
	~/.local/share/nvim/site/pack/packer/start/packer.nvim
