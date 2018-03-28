if [ $# -eq 0 ] && [ -f $HOME/.vim/plugs/YouCompleteMe/third_party/ycmd/ycm_core.so ]; then
	exit 0
fi

cd $HOME/.vim/plugs/YouCompleteMe
./install.py
cd
