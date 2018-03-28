zsh_path=$(which zsh | head -n 1)
if [ $# -eq 0 ] && [ "$SHELL" == $zsh_path ]; then
	exit 0
fi

sudo dscl . -create /Users/$USER UserShell $zsh_path
