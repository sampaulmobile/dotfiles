if [ $# -eq 0 ] && [ -d $HOME/.rvm ]; then
	exit 1
fi

\curl -sSL https://get.rvm.io | bash
source $HOME/.rvm/scripts/rvm
