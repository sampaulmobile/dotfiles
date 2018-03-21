if [ ! -f /usr/local/bin/pip ]; then
    curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo python /tmp/get-pip.py
    rm /tmp/get-pip.py
fi
