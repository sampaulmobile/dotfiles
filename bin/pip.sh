
if [ ! -f /usr/local/bin/pip ]; then
    curl -o $HOME/downloads/get-pip.py https://bootstrap.pypa.io/get-pip.py
    sudo python $HOME/downloads/get-pip.py
    rm $HOME/downloads/get-pip.py
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
