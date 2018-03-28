if [ $# -eq 0 ] && [ -d $HOME/.linuxbrew ]; then
	exit 0
fi

RCFILE=$HOME/.zshenv
git clone https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew

echo 'export PATH="/home/ubuntu/.linuxbrew/bin:$PATH"' >> $RCFILE
echo 'export MANPATH="/home/ubuntu/.linuxbrew/share/man:$MANPATH"' >> $RCFILE
echo 'export INFOPATH="/home/ubuntu/.linuxbrew/share/info:$INFOPATH"' >> $RCFILE
brew update
brew doctor
