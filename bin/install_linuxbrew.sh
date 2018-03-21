if [ ! -f $HOME/.linuxbrew ]; then
	echo "Installing linuxbrew..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
fi
