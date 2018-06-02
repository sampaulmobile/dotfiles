if [ $# -eq 0 ] && [ -f /usr/local/bin/brew ]; then
	exit 1
fi

echo | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
