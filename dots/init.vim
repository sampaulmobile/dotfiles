" =============================  GENERAL CONFIG  ==============================
let mapleader=","               "Change leader to a comma
let maplocalleader = "\\"       "Change local leader to backslash

set nocompatible                "Use vim defaults
set ru                          "Show line, column number of cursor
set number                      "Show line numbers
set nowrap                      "Don't wrap lines
set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim
set hidden                      "Buffers exist in the background
set autochdir                   "Always set pwd to path of current file

set ignorecase                  "Ignore case when searching
set smartcase                   "Override 'ignorecase' if search has uppercase
set wrapscan                    "Search wrap around the EOF
set incsearch                   "While typing search, show matches thus far
set hlsearch                    "Highlight searches

set scrolloff=8                 "Start scrolling 8 lines from top/bottom margin
set sidescrolloff=15            "Start scrolling 15 lines from left/right margin
set sidescroll=1                "Scroll horizontally by 1 character at time

set encoding=utf-8              "Set encoding to UTF-8
set backspace=indent,eol,start  "Allow backspace in insert mode
set clipboard=unnamed           "Allow vim to access OS clipboard
set history=100                 "Store 100 lines of :cmdline history
set gcr=a:blinkon0              "Disable cursor blink

set foldnestmax=5               "deepest fold is 5 levels
set foldmethod=syntax           "fold by syntax

" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

" Disable scrollbars
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L

" Allow mouse to drag/adjust window splits
set mouse+=a

" Auto complete stuff
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

" Keep undo history across sessions by storing it in a file
if has('persistent_undo')
  set undodir=~/.vim/undodir
  " Create dir if doesnt exist
  silent call system('mkdir -p ' . &undodir)
  set undofile
endif

" highlight characters past 80 columns
" augroup vimrc_autocmds
"   autocmd BufEnter * highlight OverLength ctermbg=darkgrey guibg=#592929
"   autocmd BufEnter * match OverLength /\%80v.*/
" augroup END


" ================================  MAPPINGS  ==================================

" jj to exit insert mode
imap jj <Esc>

" Misc <leader> mappings
nmap <Leader>vs :vsplit<CR>
nmap <Leader>s :split<CR>
nmap <Leader>c :close<CR>
nmap <Leader>w :w<CR>
nmap <Leader>wq :wq<CR>
nmap <Leader>q :q<CR>
nmap <Leader>r :so $MYVIMRC<CR>

" Move between split windows with Ctrl + hlkj keys
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-l> <C-w>l
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-j> <C-w>j

" Make search results appear in middle of screen
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" Clear searches with ESC
nnoremap <esc> :noh<return><esc>
nnoremap <esc>^[ <esc>^[

" Remove unnecessary whitespace (trailing, between {}/quotes)
nnoremap <Leader>ww :let _s=@/
  \<Bar>:%s/\s\+$//e
  \<Bar>:%s/{ '/{'/e
  \<Bar>:%s/' }/'}/e
  \<Bar>:%s/{ "/{"/e
  \<Bar>:%s/" }/"}/e
  \<Bar>:let @/=_s<Bar><CR>

" format json
nmap fj :%!python -m json.tool<CR>


" Toggle fold open/closed with <S-Space> if over a fold
" (this does not work in vim terminal)
" nnoremap <silent> <S-Space> @=(foldlevel('.')?'za':'zc')<CR>


" ========================  PLUG SETTINGS/MAPPINGS  =========================

" init plugs
if filereadable(expand("~/.config/nvim/plugs_neo.vim"))
  source ~/.config/nvim/plugs_neo.vim
endif

" Set colorscheme
silent! colorscheme molokai

" Set some shortcuts for Tabularize
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a: :Tabularize /:\zs<CR>
vmap <Leader>a: :Tabularize /:\zs<CR>

" TComment remap to c key
map <leader>/ <c-_><c-_>

" Mappings for fugitive
map <leader>gb :Gblame<CR>
map <leader>gh :Gbrowse<CR>

" Gundo mappings
map <leader>u :GundoToggle<CR>
let g:gundo_prefer_python3 = 1

" python folding - preview docstring in fold text
let g:SimpylFold_docstring_preview = 1

" indent guide - minimum width, subtle highlighting
let g:indent_guides_guide_size = 1
let g:indent_guides_color_change_percent = 3
let g:indent_guides_enable_on_vim_startup = 1

" NERDTree settings
map T :NERDTreeToggle<CR>
let g:NERDTreeWinSize = 20
let NERDTreeIgnore = ['\.pyc$','\.pyo$', '\.db$', '__pycache__']

" NERDtree-tabs settings
let g:nerdtree_tabs_open_on_console_startup=1

" coc.nvim configuration
set cmdheight=2         " Better display for messages
set updatetime=300      " Bad experience with diagnostic messages when it's default 4000
set shortmess+=c        " don't give |ins-completion-menu| messages

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" vim-clap settings
let g:clap_open_action = {'ctrl-t': 'tab split', 'ctrl-s': 'split', 'ctrl-v': 'vsplit'}
nmap <Leader>t :Clap files ++ef=fzf<CR>
nmap <Leader>f :Clap grep ++ef=fzf<CR>

" Use <C-n>/<C-p> instead of <C-j>/<C-k>
autocmd FileType clap_input inoremap <silent> <buffer> <C-n> <C-R>=clap#navigation#linewise('down')<CR>
autocmd FileType clap_input inoremap <silent> <buffer> <C-p> <C-R>=clap#navigation#linewise('up')<CR>

" ALE
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint'],
\}
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

" run linting before saving to see changes
nmap <leader>d <Plug>(ale_fix)

" Lightline
let g:lightline = {
\ 'colorscheme': 'wombat',
\ 'active': {
\   'left': [['mode', 'paste'], ['filename', 'modified']],
\   'right': [['lineinfo'], ['percent'], ['readonly', 'linter_warnings', 'linter_errors', 'linter_ok']]
\ },
\ 'component_expand': {
\   'linter_warnings': 'LightlineLinterWarnings',
\   'linter_errors': 'LightlineLinterErrors',
\   'linter_ok': 'LightlineLinterOK'
\ },
\ 'component_type': {
\   'readonly': 'error',
\   'linter_warnings': 'warning',
\   'linter_errors': 'error'
\ },
\ }

function! LightlineLinterWarnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ◆', all_non_errors)
endfunction

function! LightlineLinterErrors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction

function! LightlineLinterOK() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '✓ ' : ''
endfunction

autocmd User ALELint call s:MaybeUpdateLightline()

" Update and show lightline but only if it's visible (e.g., not in Goyo)
function! s:MaybeUpdateLightline()
  if exists('#lightline')
    call lightline#update()
  end
endfunction
