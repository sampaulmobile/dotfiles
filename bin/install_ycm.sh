if [ ! -f $HOME/.vim/plugs/YouCompleteMe/third_party/ycmd/ycm_core.so ]; then
    echo "Building/installing YouCompleteMe..."
    cd $HOME/.vim/plugs/YouCompleteMe
    ./install.py
    cd
fi
