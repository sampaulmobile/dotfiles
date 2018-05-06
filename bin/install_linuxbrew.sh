if [ $# -eq 0 ] && [ -d $HOME/.linuxbrew ]; then
	exit 1
fi

RCFILE=$HOME/.zshenv
git clone https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew

echo 'export PATH="/home/$USER/.linuxbrew/bin:$PATH"' >> $RCFILE
echo 'export MANPATH="/home/$USER/.linuxbrew/share/man:$MANPATH"' >> $RCFILE
echo 'export INFOPATH="/home/$USER/.linuxbrew/share/info:$INFOPATH"' >> $RCFILE
