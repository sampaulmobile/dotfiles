call plug#begin('~/.vim/plugged_neo')

" ======================== Syntax =======================

" Taskpaper (todo list) helpers/syntax
Plug 'davidoc/taskpaper.vim'


" ======================== Text Editing =======================

" Automatically adjust 'shiftwidth' and 'expandtab' heuristically
Plug 'tpope/vim-sleuth'

" Hotkey for adding comments to blocks of code
Plug 'tomtom/tcomment_vim'

" Shows 'Nth match out of M' at every search
Plug 'vim-scripts/IndexedSearch'

" Auto close parens/brackets/etc.
Plug 'raimondi/delimitmate'

" Python folding
Plug 'tmhedberg/SimpylFold'

" Text filtering and alignment
Plug 'godlygeek/tabular'

" Intellisense for (N)VIM, 'as smart as VSCode'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" ======================== VIM Tools =======================

" Visually display indent levels in code
Plug 'nathanaelkane/vim-indent-guides'

" Visualize vim undo tree
Plug 'sjl/gundo.vim'

" colorschemes
Plug 'tomasr/molokai'

call plug#end()
