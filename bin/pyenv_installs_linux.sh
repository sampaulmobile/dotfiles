echo "Attempting to install Python 3.5.2"
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
pyenv install 3.5.2
pyenv global 3.5.2
