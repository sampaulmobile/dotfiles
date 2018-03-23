if [ ! -d $HOME/.fzf ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install --completion --key-bindings --no-update-rc
	exec "$SHELL"
fi
