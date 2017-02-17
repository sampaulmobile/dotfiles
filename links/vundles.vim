" vim --noplugin -u vim/vundles.vim -N '+set hidden" '+syntax on" +PluginClean! +PluginInstall +qall
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'


" ======================== Syntax =======================
"Syntax highlighting for salt
Plugin 'saltstack/salt-vim.git'

"Syntax highlighting for typescript
Plugin 'leafgarland/typescript-vim'

"Zencoding for html
Plugin 'mattn/emmet-vim'

"Extra highlighting of typedefs, enumerations etc (based on ctags)
Plugin 'vim-scripts/TagHighlight.git'

" Taskpaper (todo list) helpers/syntax
Plugin 'davidoc/taskpaper.vim'

" ======================== Text Editing =======================
"text filtering and alignment
Plugin 'godlygeek/tabular'

"hotkey for adding comments to blocks of code
Plugin 'tomtom/tcomment_vim.git'

"shows 'Nth match out of M' at every search
Plugin 'vim-scripts/IndexedSearch'

"extended % matching for HTML, LaTeX, and many other languages
Plugin 'vim-scripts/matchit.zip.git'

"add 'end' for ruby
Plugin 'tpope/vim-endwise.git'

"quoting/parenthesizing made simple
Plugin 'tpope/vim-surround.git'

"pairs of handy bracket mappings
Plugin 'tpope/vim-unimpaired'

"python folding
Plugin 'tmhedberg/SimpylFold'

"autocomplete
Plugin 'Valloric/YouCompleteMe'

" ======================== VIM Tools =======================
"NERDTree and tabs together in Vim
Plugin 'jistr/vim-nerdtree-tabs.git'

"Fuzzy file, buffer, mru, tag, etc finder
Plugin 'kien/ctrlp.vim'

" NERDTree BRO!
Plugin 'scrooloose/nerdtree.git'

"Git wrapper - :gblame, :gbrowse, etc.
Plugin 'tpope/vim-fugitive'

" hopefully adds (removes files of) .gitignore for NERDtree
Plugin 'Xuyuanp/nerdtree-git-plugin'

"syntax checking
Plugin 'scrooloose/syntastic.git'

"visualize vim undo tree
Plugin 'sjl/gundo.vim'

"visually display indent levels in code
Plugin 'nathanaelkane/vim-indent-guides'

"lean & mean status/tabline
Plugin 'bling/vim-airline.git'

" Load local lvimrc files (currently for per-project indenting)
Plugin 'embear/vim-localvimrc.git'

Plugin 'tomasr/molokai'


call vundle#end() " required now for new vundle
filetype plugin indent on
