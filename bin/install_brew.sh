if [ $# -eq 0 ] && [ -f /opt/homebrew/bin/brew ]; then
	echo "Homebrew installed, exiting"
	exit 1
fi

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
