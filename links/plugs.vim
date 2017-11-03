call plug#begin('~/.vim/plugs')

" ======================== Syntax =======================

" A collection of language packs for Vim.
Plug 'sheerun/vim-polyglot'

" Asyncrhronous lint engine
Plug 'w0rp/ale'

" Syntax highlighting for salt
Plug 'saltstack/salt-vim'

" Taskpaper (todo list) helpers/syntax
Plug 'davidoc/taskpaper.vim'

" ======================== Text Editing =======================

" Repeat certain actions with '.'
Plug 'tpope/vim-repeat'

" Automatically adjust 'shiftwidth' and 'expandtab' heuristically
Plug 'tpope/vim-sleuth'

" Hotkey for adding comments to blocks of code
Plug 'tomtom/tcomment_vim'

" Shows 'Nth match out of M' at every search
Plug 'vim-scripts/IndexedSearch'

" Extended % matching for HTML, LaTeX, and many other languages
Plug 'vim-scripts/matchit.zip'

" Add 'end' for ruby
Plug 'tpope/vim-endwise'

" Auto close parens/brackets/etc.
Plug 'raimondi/delimitmate'

" Python folding
Plug 'tmhedberg/SimpylFold'

" Text filtering and alignment
Plug 'godlygeek/tabular'

" Quoting/parenthesizing made simple
" Plug 'tpope/vim-surround'

" Autocomplete stuff
" Plug 'Valloric/YouCompleteMe'

" Multiple Plug commands can be written in a single line using | separators
" Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" ======================== VIM Tools =======================

" NERDTree and tabs together in Vim
Plug 'jistr/vim-nerdtree-tabs'

" NERDTree BRO!
Plug 'scrooloose/nerdtree'

" Show git diff in vim 'gutter'
Plug 'airblade/vim-gitgutter'

" Git wrapper - :gblame, :gbrowse, etc.
Plug 'tpope/vim-fugitive' "| Plug 'tpope/vim-rhubarb'

" Visualize vim undo tree
Plug 'sjl/gundo.vim'

" Visually display indent levels in code
Plug 'nathanaelkane/vim-indent-guides'

" Minimal airline
Plug 'itchyny/lightline.vim'

" Fuzzy file, buffer, mru, tag, etc finder
Plug 'kien/ctrlp.vim'

" FZF
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" 'distraction free writing in vim'
" Plug 'junegunn/goyo.vim'

" colorschemes
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'reedes/vim-colors-pencil'

call plug#end()
