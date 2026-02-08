if [ $# -eq 0 ] && [ `which rg` ]; then
	exit 1
fi

bin_brew=$HOME/.linuxbrew/bin/brew
$bin_brew tap burntsushi/ripgrep https://github.com/BurntSushi/ripgrep.git
$bin_brew install ripgrep-bin
