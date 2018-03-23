if [ ! -f $HOME/.linuxbrew ]; then
	echo "Installing linuxbrew..."
	git clone https://github.com/Linuxbrew/brew.git $HOME/.linuxbrew
	echo 'export PATH="/home/ubuntu/.linuxbrew/bin:$PATH"' >> ~/.bashrc
	echo 'export MANPATH="/home/ubuntu/.linuxbrew/share/man:$MANPATH"' >> ~/.bashrc
	echo 'export INFOPATH="/home/ubuntu/.linuxbrew/share/info:$INFOPATH"' >> ~/.bashrc
	exec "$SHELL"
	brew update
	brew doctor
fi
