if [ ! -d $HOME/.fzf ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install --completion --key-bindings --update-rc
	exec "$SHELL"
fi
