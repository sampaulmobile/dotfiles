zsh_path=$(which zsh | head -n 1)
if [ $# -eq 0 ] && [ "$SHELL" == $zsh_path ]; then
	exit 1
fi

chsh -s $zsh_path $USERNAME
