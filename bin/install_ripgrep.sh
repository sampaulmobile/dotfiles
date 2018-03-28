if [ $# -eq 0 ] && [ -f /usr/local/bin/rg ]; then
	exit 0
fi

sudo snap install rg
