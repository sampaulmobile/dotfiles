call plug#begin('~/.vim/plugs')

" ======================== Syntax =======================

" Asynchronous lint engine
Plug 'w0rp/ale'

" Syntax highlighting for salt
Plug 'saltstack/salt-vim'

" Taskpaper (todo list) helpers/syntax
Plug 'davidoc/taskpaper.vim'

" A collection of language packs for Vim.
Plug 'sheerun/vim-polyglot'

" Extra highlighting of typedefs, enumerations etc (based on ctags)
" Plug 'vim-scripts/TagHighlight'

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

" Autocomplete stuff
" Plug 'Valloric/YouCompleteMe'

" Ultisnips + snippets + supertab to make it work with YCM
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets' | Plug 'ervandew/supertab'

" latex editing/compiling
Plug 'lervag/vimtex', { 'for': 'tex' }

" ======================== VIM Tools =======================

" NERDTree BRO!
Plug 'scrooloose/nerdtree'

" NERDTree and tabs together in Vim
Plug 'jistr/vim-nerdtree-tabs'

" Add git status indicators to NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin'

" Show git diff in vim 'gutter'
Plug 'airblade/vim-gitgutter'

" Git wrapper - :gblame, :gbrowse, etc.
Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb'

" Visualize vim undo tree
Plug 'sjl/gundo.vim'

" Visually display indent levels in code
Plug 'nathanaelkane/vim-indent-guides'

" Minimal airline
Plug 'itchyny/lightline.vim'

" FZF
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Switch between vim/tmux panes seamlessly
Plug 'christoomey/vim-tmux-navigator'

" 'distraction free writing in vim'
" Plug 'junegunn/goyo.vim'

" colorschemes
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'reedes/vim-colors-pencil'
Plug 'morhetz/gruvbox'

call plug#end()
