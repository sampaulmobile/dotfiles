zsh_path=$(which zsh | head -n 1)
if [ "$SHELL" != $zsh_path ]; then
	echo "Setting ZSH to default shell..."
	sudo dscl . -create /Users/$USER UserShell $zsh_path
fi
