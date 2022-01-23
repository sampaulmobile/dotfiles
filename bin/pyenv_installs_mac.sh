PYTHON_VERSION=3.9.6

# --enable-framework required for haskell YCM
# CFLAGS="-I$(brew --prefix openssl)/include" \
# LDFLAGS="-L$(brew --prefix openssl)/lib" \
# PYTHON_CONFIGURE_OPTS="--enable-framework" \
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION
