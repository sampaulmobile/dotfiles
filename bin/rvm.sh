
if [ ! -d $HOME/.rvm ]; then
    echo "Installing RVM... (+Ruby 2.2.5)"
    \curl -sSL https://get.rvm.io | bash
    source $HOME/.rvm/scripts/rvm
    rvm install ruby-2.2.5
fi
