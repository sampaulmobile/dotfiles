" ========================================
" Vim plugin configuration
" ========================================
"
" This file contains the list of plugin installed using vundle plugin manager.
" Once you've updated the list of plugin, you can run vundle update by issuing
" the command :BundleInstall from within vim or directly invoking it from the
" command line with the following syntax:
" vim --noplugin -u vim/vundles.vim -N "+set hidden" "+syntax on" +BundleClean! +BundleInstall +qall
" Filetype off is required by vundle
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle (required)
Bundle "gmarik/vundle"


" ======================== Ruby, Rails, Rake =======================
"Bundle "astashov/vim-ruby-debugger"
"Bundle "ecomba/vim-ruby-refactoring"
"Bundle "skwp/vim-ruby-conque"
Bundle "tpope/vim-rails.git"
Bundle "tpope/vim-rake.git"
Bundle "tpope/vim-rvm.git"
Bundle "vim-ruby/vim-ruby.git"
"Bundle "vim-scripts/Specky.git" Used for testing

"Changes ruby hash syntax
Bundle "ck3g/vim-change-hash-syntax"


" ======================== Other languages =======================
Bundle "briancollins/vim-jst"
Bundle "pangloss/vim-javascript"
"Bundle "rodjek/vim-puppet"


" ======================== HTML, XML, CSS, Markdown =======================
"jasmine javascript testing
"Bundle "claco/jasmine.vim"

"syntax highlighting for jade templates
"Bundle "digitaltoad/vim-jade.git"

"syntax highlighting for LESS
"Bundle "groenewege/vim-less.git"

Bundle "itspriddle/vim-jquery.git"
Bundle "jtratner/vim-flavored-markdown.git"

"coffeescript highlighting
Bundle "kchmck/vim-coffee-script"

"preview markdown documents in browser
"Bundle "nelstrom/vim-markdown-preview"

Bundle "skwp/vim-html-escape"

"syntax highlighting for slim
"Bundle "slim-template/vim-slim.git"

"Syntax Highlighting and Textile rendering / preview
"Bundle "timcharper/textile.vim.git"

"Vim runtime files for Haml, Sass, and SCSS
"Bundle "tpope/vim-haml"

"Syntax highlighting for Stylus
"Bundle "wavded/vim-stylus"

Bundle 'hail2u/vim-css3-syntax'


" ======================== Git Stuff =======================
Bundle "gregsexton/gitv"

"vimscript for creating gists
"Bundle "mattn/gist-vim"

"Find (git grep) references to the rails view partial you're viewing
Bundle "skwp/vim-git-grep-rails-partial"

Bundle "tjennings/git-grep-vim"

"Git wrapper so awesome, it should be illegal
Bundle "tpope/vim-fugitive"

"Git syntax, indent, and filetype plugin files
Bundle "tpope/vim-git"

"show Git diffs in gutter
"Bundle 'airblade/vim-gitgutter'

" ======================== General Text Editing =======================
"switching between single-line and multiline code
Bundle "AndrewRadev/splitjoin.vim"

"insert mode auto-completion for quotes, parens, brackets, etc
Bundle "Raimondi/delimitMate"

"YouCompleteMe all around autocomplete
"Bundle "Valloric/YouCompleteMe"

"ultisnips (used in YouCompleteMe)
"Bundle "SirVer/ultisnips"

"implements some of TextMate's snippets features
"Bundle "garbas/vim-snipmate.git"

"some utility functions (needed for snipmate)
"Bundle "tomtom/tlib_vim.git"
"Bundle "MarcWeber/vim-addon-mw-utils.git"

"Ultimate auto-completion system for Vim
"Bundle "Shougo/neocomplcache.git"

"vim-snipmate default snippets
"Bundle "honza/vim-snippets"

"change the contents of the innermost 'surrounding'
Bundle "briandoll/change-inside-surroundings.vim.git"

"text filtering and alignment
Bundle "godlygeek/tabular"

"Start a * or # search from a visual block
Bundle "nelstrom/vim-visual-star-search"

"vim motions on speeds
Bundle "Lokaltog/vim-easymotion"

"extensible & universal comments
Bundle "tomtom/tcomment_vim.git"

"vim goodies for Bundler
Bundle "tpope/vim-bundler"

"shows 'Nth match out of M' at every search
Bundle "vim-scripts/IndexedSearch"

"Motion through CamelCaseWords and underscore_notation.
"Bundle "vim-scripts/camelcasemotion.git"

"extended % matching for HTML, LaTeX, and many other languages
Bundle "vim-scripts/matchit.zip.git"

"True Sublime Text style multiple selections
Bundle "terryma/vim-multiple-cursors"


" ======================== General VIM =======================

"open file @ a given line
Bundle "bogado/file-line.git"

"NERDTree and tabs together in Vim
Bundle "jistr/vim-nerdtree-tabs.git"

"Fuzzy file, buffer, mru, tag, etc finder
Bundle "kien/ctrlp.vim"

"LustyJuggler -> puts open windows on home row keys
"Bundle "sjbach/lusty/master/plugin/lusty-juggler.vim"
Bundle "vim-scripts/LustyJuggler"

"Vim plugin that displays tags in a window, ordered by class
Bundle "majutsushi/tagbar.git"

"vim interface to Web API
Bundle "mattn/webapi-vim.git"

"siver searcher, similar to ack
"Bundle "rking/ag.vim"

Bundle "scrooloose/nerdtree.git"

"syntax checking
Bundle "scrooloose/syntastic.git"

"visualize vim undo tree
Bundle "sjl/gundo.vim"

"Maintains a history of previous yanks, changes and deletes
Bundle "vim-scripts/YankRing.vim"

"Replace a pattern across multiple files interactively
Bundle "skwp/greplace.vim"

"terminal emulator which uses a Vim buffer to display the program output
"Bundle "skwp/vim-conque"

"easily search for, substitute, and abbreviate multiple variants of a word
Bundle "tpope/vim-abolish"

"add 'end' for ruby
Bundle "tpope/vim-endwise.git"

"ghetto HTML/XML mappings
Bundle "tpope/vim-ragtag"

"enable repeating supported plugin maps with '.'
Bundle "tpope/vim-repeat.git"

"quoting/parenthesizing made simple
Bundle "tpope/vim-surround.git"

"pairs of handy bracket mappings
Bundle "tpope/vim-unimpaired"

"ansi escape sequences concealed
"Bundle "vim-scripts/AnsiEsc.vim.git"

"Updates entries in a tags file automatically when saving
Bundle "vim-scripts/AutoTag.git"

"Bundle "vim-scripts/lastpos.vim"

"edit a file with priviledges from an unprivledged session
Bundle "vim-scripts/sudo.vim"

"Visually shows the location of marks
"Bundle "xsunsmile/showmarks.git"

"vim-misc is required for vim-session
"Bundle "xolox/vim-misc"
"Bundle "xolox/vim-session"


" ======================== Text Objects =======================
"Text Objects based on Indentation Level
Bundle "austintaylor/vim-indentobject"

"Text object for manipulation of ruby symbol variables
"Bundle "bootleq/vim-textobj-rubysymbol"

"Adds text-objects for word-based columns
Bundle "coderifous/textobj-word-column.vim"

"Bundle "kana/vim-textobj-datetime"
"Bundle "kana/vim-textobj-entire"
"Bundle "kana/vim-textobj-function"

"installed for textobj-underscore
Bundle "kana/vim-textobj-user"

"Underscore text-object for Vim
Bundle "lucapette/vim-textobj-underscore"

"visually display indent levels in code
Bundle "nathanaelkane/vim-indent-guides"

"custom text object for selecting ruby blocks
Bundle "nelstrom/vim-textobj-rubyblock"

"Text objects for functions in javascript.
Bundle "thinca/vim-textobj-function-javascript"

"Text-object like motion for arguments
Bundle "vim-scripts/argtextobj.vim"


" ======================== Cosmetics, Colors, Powerline =======================
"color hex codes and color names
Bundle "chrisbra/color_highlight.git"

"Bundle "skwp/vim-colors-solarized"
Bundle "altercation/vim-colors-solarized"
Bundle "tomasr/molokai"

"lean & mean status/tabline
Bundle "bling/vim-airline.git"

"Extra highlighting of typedefs, enumerations etc (based on ctags)
Bundle "vim-scripts/TagHighlight.git"

"Supertab - all insert mode completion using <TAB>
"Bundle "ervandew/supertab"

" non-GitHub repos
"CommandT is SLOW
"Bundle 'git://git.wincent.com/command-t.git'

" Git repos on your local machine (i.e. when working on your own plugin)
"Bundle 'file:///Users/gmarik/path/to/plugin'
" ...

"Filetype plugin indent on is required by vundle
filetype plugin indent on
