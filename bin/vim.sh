
if [ ! -f ~/.vim/autoload/plug.vim ]; then
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

cd $HOME && vim +PlugUpgrade +PlugUpdate +qall

# if [ ! -f $HOME/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core.so ]; then
#     echo "Building/installing YouCompleteMe..."
#     cd $HOME/.vim/bundle/YouCompleteMe
#     ./install.py
#     cd
# fi

