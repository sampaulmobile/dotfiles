if [ ! -d $HOME/.pyenv ]; then
	RCFILE=$HOME/.bashrc

	git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $RCFILE
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $RCFILE
	exec "$SHELL"
fi
