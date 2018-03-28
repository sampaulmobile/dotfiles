if [ $# -eq 0 ] && [ -f /usr/local/bin/pip ]; then
	exit 0
fi

curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
sudo python /tmp/get-pip.py
rm /tmp/get-pip.py
