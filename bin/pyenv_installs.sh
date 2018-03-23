if [ ! -d $HOME/.pyenv ]; then
    echo "Installing Python 3.5.2"
    CFLAGS="-I$(brew --prefix openssl)/include" \
    LDFLAGS="-L$(brew --prefix openssl)/lib" \
    PYTHON_CONFIGURE_OPTS="--enable-framework" \ # required for haskell YCM
    pyenv install 3.5.2
    pyenv global 3.5.2
fi
