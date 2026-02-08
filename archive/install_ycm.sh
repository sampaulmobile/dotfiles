if [ $# -eq 0 ] && [ -f $HOME/.vim/plugs/YouCompleteMe/third_party/ycmd/ycm_core.so ]; then
	exit 1
fi

cd $HOME/.vim/plugs/YouCompleteMe
./install.py
cd
