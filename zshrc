# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Theme is symlinked to ~/.oh-my-zsh/custom/
ZSH_THEME="sampaul"


# ============ Aliases =============
alias dev="cd ~/Development/SBP"
DOC_HOME='/Users/sampaul/Development/Docurated'

alias docweb='cd $DOC_HOME/website/rails'
alias docutil='cd $DOC_HOME/utilities'
alias cdemo='$DOC_HOME/utilities/docformation/docconnection.rb demo.web.0'
alias crailsapp='$DOC_HOME/utilities/docformation/docconnection.rb demo.railsapp.0'
alias cfdb='$DOC_HOME/utilities/docformation/docconnection.rb demo.foundationdb.0'
alias cprod='$DOC_HOME/utilities/docformation/docconnection.rb production.web.12'

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias ln='ln -v'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
#alias rcp='rsync -v --progress'
#alias rmv='rsync -v --progress --remove-source-files'

#fix for rake tasks
alias rake='noglob rake'

alias g='git'

# rvm stuff
alias rvml='rvm list'
alias rvmgl='rvm gemset list'
alias rvmg='rvm gemset use'
alias rvmrc="echo 'rvm --create use$1' >> .rvmrc"

# Use vi-mode in the shell
bindkey -v
bindkey -M viins 'jj' vi-cmd-mode #map jj to exit (mimic ESC)


# ======== History Stuff =========
HISTFILE=~/.history
SAVEHIST=10000
HISTSIZE=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY # share history between multiple shells
# dont save duplicates
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
# If a line starts with a space, don't save it.
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
# When using a hist thing, make a newline show the change before executing it.
setopt HIST_VERIFY
# Save the time and how long a command ran
setopt EXTENDED_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Oh-my-zsh plugins
plugins=(git autojump brew bunder command-not-found gem nyan osx python rails4 ruby rvm sublime textmate vi-mode web-search zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh


# =========== $PATH Stuff ==========
export PATH=/usr/local/bin:/usr/local/sbin:/bin:/usr/sbin:/sbin:/usr/bin:/opt/X11/bin:$PATH
#Python
export PATH=$PATH:/Users/sampaul/Library/Python/2.7/bin
### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 
typeset -U path


# =============== Autocomplete Stuff ==============
source ~/.zsh-autosuggestions/autosuggestions.zsh
# Enable autosuggestions automatically
zle-line-init() {
    zle autosuggest-start
}
zle -N zle-line-init
# use ctrl+t to toggle autosuggestions(hopefully this wont be needed as
# zsh-autosuggestions is designed to be unobtrusive)
bindkey '^T' autosuggest-toggle
# Auto completion for git aliased as g
# complete -o bashdefault -o default -o nospace -F _git g 2>/dev/null \
#         || complete -o default -o nospace -F _git g

