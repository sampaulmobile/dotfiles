if [ $# -eq 0 ] && [ -d $HOME/.fzf ]; then
	exit 0
fi

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --completion --key-bindings --no-update-rc
exec "$SHELL"
