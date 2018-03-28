if [ $# -eq 0 ] && [ -f /usr/local/bin/brew ]; then
	exit 0
fi

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
