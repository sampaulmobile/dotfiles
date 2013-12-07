set nocompatible    "use vim defaults


" ================ General Config ====================

"win 120 80                      "Diplay - make window 80 wide x 45 tall
set ru                          "Turn on ruler
set number                      "Line numbers are good
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set gcr=a:blinkon0              "Disable cursor blink
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim

if $TMUX == ''
  set clipboard+=unnamed
endif

" Mappings
imap jj <Esc>

" Move between split windows with Ctrl + arrow keys
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-l> <C-w>l
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-j> <C-w>j

" This makes vim act like all other editors, buffers can
" exist in the background without being in a window.
" http://items.sjbach.com/319/configuring-vim-right
set hidden

"turn on syntax highlighting
syntax on


" =============== Vundle Initialization ===============
" This loads all the plugins specified in ~/.vim/vundles.vim
" Use Vundle plugin to manage all other plugins
if filereadable(expand("~/.vim/vundles.vim"))
  source ~/.vim/vundles.vim
endif


" Change leader to a comma because the backslash is too far away
let mapleader=","

" Set some shortcuts for Tabularize
"if exists(":Tabularize")
  nmap <Leader>a= :Tabularize /=<CR>
  vmap <Leader>a= :Tabularize /=<CR>
  nmap <Leader>a: :Tabularize /:\zs<CR>
  vmap <Leader>a: :Tabularize /:\zs<CR>
"endif

"NERDTree toggle set to capital T
map T :NERDTreeToggle<CR>

"TagBar toggle set to leader + b
let g:tagbar_usearrows = 1
nnoremap <leader>b :TagbarToggle<CR>

"CtrlP toggle set to leader + t
map <leader>t :CtrlP<CR>
nnoremap <silent> <leader>T :ClearCtrlPCache<cr>\|:CtrlP<cr>

"TComment remap to c key
map <leader>/ <c-_><c-_>

"Yankring map display to leader y
nnoremap <silent> <leader>y :YRShow<CR>

"Gundo - GUI Undo Tree (visualized)
map <leader>u :GundoToggle<CR>

"Remapping yankring n/p to meta key
let g:yankring_replace_n_pkey = '<m-p>'
let g:yankring_replace_n_nkey = '<m-n>'

"let g:UltiSnipsExpandTrigger=""
"let g:UltiSnipsJumpForwardTrigger=""
"let g:UltiSnipsJumpBackwardTrigger=""

"<leader><leader>w is default for vim motion plugin

"Use CamelCaseMotion for normal w, b, e
"map <silent> w <Plug>CamelCaseMotion_w 
"map <silent> b <Plug>CamelCaseMotion_b 
"map <silent> e <Plug>CamelCaseMotion_e 
"sunmap w
"sunmap b
"sunmap e

"Mappings for Rails.vim
map <leader><leader>m :Emodel<CR>
map <leader><leader>c :Econtroller<CR>
map <leader><leader>v :Eview<CR>

"<leader>ig is default for vim indentation guide

"Need to set coloscheme after vundles are loaded
"colorscheme desert
"colorscheme solarized
colorscheme molokai
"set background=light             "Options are 'dark' or 'light'
"Set F5 to toggle background color
"call togglebg#map("<F5>")


" ================ Persistent Undo ==================
" Keep undo history across sessions, by storing in file.
" Only works all the time.
silent !mkdir ~/.vim/backups > /dev/null 2>&1
set undodir=~/.vim/backups
set undofile

" ================ Indentation ======================

"filetype on

"set cin             "c indent
"set autoindent
"set smartindent
"set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

" Filetype Settings
"filetype indent on
"filetype plugin on

autocmd FileType ruby set sw=4 sts=4 et
autocmd FileType haml set sw=4 sts=4 et
autocmd FileType coffee set sw=4 sts=4 et
autocmd FileType scss set sw=4 sts=4 et
autocmd FileType erb set sw=4 sts=4 et

" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·
set nowrap       "Don't wrap lines
set linebreak    "Wrap lines at convenient points


" ================ Folds ============================
"set foldmethod=indent   "fold based on indent
set foldmethod=syntax   "fold by syntax
set foldnestmax=5       "deepest fold is 3 levels
"set nofoldenable        "dont fold by default
" toggle hold with <S-Space> if over a fold
nnoremap <silent> <S-Space> @=(foldlevel('.')?'za':'l')<CR>


" ================ Completion =======================
set wildmode=list:longest,full     "first list:longest then full
set wildmenu                       "enable ctrl-n and ctrl-p to scroll thru matches
set wildignore=*.o,*.obj,*~        "stuff to ignore when tab completing
set wildignore+=*vim/backups*
set wildignore+=*sass-cache*
set wildignore+=*DS_Store*
set wildignore+=vendor/rails/**
set wildignore+=vendor/cache/**
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif

" Search
set ignorecase      "ignore case when searching
set wrapscan        "search wrap around the EOF
set smartcase       "override 'ignorecase' if search has uppercase
set incsearch       "do incremental searching
set hlsearch        "highlight searches

"make search results appear in middle of screen
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz    
"clear searches
nnoremap <Esc> :noh<Return><Esc> 


" ================ Scrolling ========================
set scrolloff=8         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

