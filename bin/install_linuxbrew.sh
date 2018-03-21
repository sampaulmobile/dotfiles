if [ ! -f $HOME/.linuxbrew ]; then
	echo "Installing linuxbrew..."
	git clone https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew
	echo 'export PATH="/home/ubuntu/.linuxbrew/bin:$PATH"' >> ~/.profile
	echo 'export MANPATH="/home/ubuntu/.linuxbrew/share/man:$MANPATH"' >> ~/.profile
	echo 'export INFOPATH="/home/ubuntu/.linuxbrew/share/info:$INFOPATH"' >> ~/.profile
	source ~/.profile
	brew update
	brew doctor
fi
