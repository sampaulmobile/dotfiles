if [ $# -eq 0 ] && [ -d $HOME/.pyenv ]; then
	exit 1
fi

RCFILE=$HOME/.zshenv

git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $RCFILE
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $RCFILE
exec "$SHELL"
