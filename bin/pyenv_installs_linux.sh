PYTHON_VERSION=3.5.2

CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION
