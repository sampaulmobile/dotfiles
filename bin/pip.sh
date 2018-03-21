
if [ ! -f /usr/local/bin/pip ]; then
    curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo python /tmp/get-pip.py
    rm /tmp/get-pip.py
fi

if [ ! -d $HOME/.pyenv ]; then
    echo "Installing Python 3.5.2"
    CFLAGS="-I$(brew --prefix openssl)/include" \
    LDFLAGS="-L$(brew --prefix openssl)/lib" \
    PYTHON_CONFIGURE_OPTS="--enable-framework" \ # required for haskell YCM
    pyenv install 3.5.2
    pyenv global 3.5.2
fi

pip install flake8
