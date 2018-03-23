if [ ! -f $HOME/.linuxbrew ]; then
	echo "Installing linuxbrew..."
	RCFILE=$HOME/.zshenv
	git clone https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew

	echo 'export PATH="/home/ubuntu/.linuxbrew/bin:$PATH"' >> $RCFILE
	echo 'export MANPATH="/home/ubuntu/.linuxbrew/share/man:$MANPATH"' >> $RCFILE
	echo 'export INFOPATH="/home/ubuntu/.linuxbrew/share/info:$INFOPATH"' >> $RCFILE
	exec "$SHELL"
	brew update
	brew doctor
fi
