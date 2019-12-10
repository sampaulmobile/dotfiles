call plug#begin('~/.vim/plugs')

" ======================== Syntax =======================

" Asynchronous lint engine
Plug 'dense-analysis/ale'

" A collection of language packs for Vim.
Plug 'sheerun/vim-polyglot'

" Taskpaper (todo list) helpers/syntax
Plug 'davidoc/taskpaper.vim'

" Management of tag files
" Plug 'ludovicchabant/vim-gutentags'

" Extra highlighting of typedefs, enumerations etc (based on ctags)
" Plug 'vim-scripts/TagHighlight'

" Syntax highlighting for salt
" Plug 'saltstack/salt-vim'

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

" Auto close parens/brackets/etc.
Plug 'raimondi/delimitmate'

" Python folding
Plug 'tmhedberg/SimpylFold'

" Text filtering and alignment
Plug 'godlygeek/tabular'

" latex editing/compiling
Plug 'lervag/vimtex', { 'for': 'tex' }

" Reload files in vim when necessary
Plug 'tmux-plugins/vim-tmux-focus-events'

" Intellisense for JS, 'as smart as VSCode'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Autocomplete stuff
" Plug 'Valloric/YouCompleteMe'

" Ultisnips + snippets + supertab to make it work with YCM
" Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets' | Plug 'ervandew/supertab'

" Add 'end' for ruby
" Plug 'tpope/vim-endwise'

" ======================== VIM Tools =======================

" NERDTree BRO!
Plug 'scrooloose/nerdtree'

" NERDTree and tabs together in Vim
Plug 'jistr/vim-nerdtree-tabs'

" Add git status indicators to NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin'

" Git wrapper - :gblame, :gbrowse, etc.
Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb'

" Visually display indent levels in code
Plug 'nathanaelkane/vim-indent-guides'

" Minimal airline
Plug 'itchyny/lightline.vim'

" FZF
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Switch between vim/tmux panes seamlessly
Plug 'christoomey/vim-tmux-navigator'

" Visualize vim undo tree
Plug 'sjl/gundo.vim'

" Show git diff in vim 'gutter'
" Plug 'airblade/vim-gitgutter'

" 'distraction free writing in vim'
" Plug 'junegunn/goyo.vim'

" colorschemes
Plug 'sjl/badwolf'
Plug 'tomasr/molokai'
Plug 'reedes/vim-colors-pencil'
Plug 'morhetz/gruvbox'
Plug 'nanotech/jellybeans'
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()
