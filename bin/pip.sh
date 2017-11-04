
if [ ! -f /usr/local/bin/brew ]; then
	curl -o $HOME/downloads/get-pip.py https://bootstrap.pypa.io/get-pip.py
	python $HOME/downloads/get-pip.py
	rm $HOME/downloads/get-pip.py
fi

if [ ! -d $HOME/.pyenv ]; then
    echo "Installing Python 3.5.2"
    PYTHON_CONFIGURE_OPTS="--enable-framework" pyenv install 3.5.2
    pyenv global 3.5.2
fi

pip install flake8

