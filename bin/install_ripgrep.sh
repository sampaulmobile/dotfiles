if [ $# -eq 0 ] && [ `which rg` ]; then
	exit 1
fi

brew tap burntsushi/ripgrep https://github.com/BurntSushi/ripgrep.git
brew install ripgrep-bin
