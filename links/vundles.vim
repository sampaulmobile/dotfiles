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

" open URLs/PDFs/etc. from vim hyperlinks
" Plugin 'vim-scripts/ult'

" (emacs) narrow region feature
" Plugin 'NrrwRgn'

" markdown syntax highlighting (required godlygeek/tabular)
Plugin 'plasticboy/vim-markdown'

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

"auto close parens/brackets/etc. 
Plugin 'raimondi/delimitmate'

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
Plugin 'vim-airline/vim-airline'

" Load local lvimrc files (currently for per-project indenting)
Plugin 'embear/vim-localvimrc.git'

" easy motion for EASY movement
Plugin 'easymotion/vim-easymotion'

" 'distraction free writing in vim'
Plugin 'junegunn/goyo.vim'

" (emacs) org mode in vim
Plugin 'jceb/vim-orgmode'

" colorschemes
Plugin 'sjl/badwolf'
Plugin 'tomasr/molokai'
Plugin 'reedes/vim-colors-pencil'


call vundle#end() " required now for new vundle
filetype plugin indent on
