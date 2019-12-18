call plug#begin('~/.vim/plugged_neo')

" ======================== Syntax =======================

" Taskpaper (todo list) helpers/syntax
Plug 'davidoc/taskpaper.vim'

" Visually display indent levels in code
Plug 'nathanaelkane/vim-indent-guides'


" ======================== Text Editing =======================

" Automatically adjust 'shiftwidth' and 'expandtab' heuristically
Plug 'tpope/vim-sleuth'

" Hotkey for adding comments to blocks of code
Plug 'tomtom/tcomment_vim'

" Shows 'Nth match out of M' at every search
Plug 'vim-scripts/IndexedSearch'

" Insert or delete brackets, parens, quotes in pair
Plug 'jiangmiao/auto-pairs'

" Python folding
Plug 'tmhedberg/SimpylFold'

" Text filtering and alignment
Plug 'godlygeek/tabular'

" Intellisense for (N)VIM, 'as smart as VSCode'
Plug 'neoclide/coc.nvim', {'branch': 'release'}


" ======================== VIM Tools =======================

" Git(hub) wrapper - :gblame, :gbrowse, etc.
Plug 'tpope/vim-fugitive' | Plug 'tpope/vim-rhubarb'

" Visualize vim undo tree
Plug 'sjl/gundo.vim'

" NERDTree BRO!
Plug 'scrooloose/nerdtree'

" NERDTree and tabs together in Vim
Plug 'jistr/vim-nerdtree-tabs'

" Add git status indicators to NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin'

" Modern generic interactive finder/dispatcher for (N)VIM
Plug 'liuchengxu/vim-clap'

" colorschemes
Plug 'tomasr/molokai'

call plug#end()
