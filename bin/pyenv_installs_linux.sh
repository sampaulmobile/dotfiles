PYTHON_VERSION=3.7.0

# CFLAGS="-I$(brew --prefix openssl)/include" \
# LDFLAGS="-L$(brew --prefix openssl)/lib" \
export PYTHON_CONFIGURE_OPTS="--enable-shared" # YCM requires this
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION
