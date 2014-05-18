# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Theme is symlinked to ~/.oh-my-zsh/custom/
ZSH_THEME="sampaul"


# ============ Aliases =============
alias dev="cd ~/Development/SBP"
DOC_HOME='/Users/sampaul/Development/Docurated'

alias docweb='cd $DOC_HOME/website/rails && rvmgd'
alias docutil='cd $DOC_HOME/utilities && rvmgdu'
alias doccli='cd $DOC_HOME/clients && rvmgdu'

alias con='$DOC_HOME/utilities/docformation/docconnection.rb'
webconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb $1.web.$2
}
alias cweb=webconnect
railsappconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb $1.railsapp.$2
}
alias crapp=railsappconnect

dwebconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb demo.web.$1
}
alias cdweb=dwebconnect
alias cdweb0='$DOC_HOME/utilities/docformation/docconnection.rb demo.web.0'
alias cdweb1='$DOC_HOME/utilities/docformation/docconnection.rb demo.web.1'

drappconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb demo.railsapp.$1
}
alias cdrapp=drappconnect
# alias cdrapp='$DOC_HOME/utilities/docformation/docconnection.rb demo.railsapp.0'

dfdbconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb demo.foundationdb.$1
}
alias cdfdb=dfdbconnect
alias cdfdb='$DOC_HOME/utilities/docformation/docconnection.rb demo.foundationdb.0'

pwebconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb production.web.$1
}
alias cpweb=pwebconnect
# alias cpweb='$DOC_HOME/utilities/docformation/docconnection.rb production.web.12'

prappconnect() {
    $DOC_HOME/utilities/docformation/docconnection.rb production.railsapp.$1
}
alias cprapp=prappconnect
alias cprapp='$DOC_HOME/utilities/docformation/docconnection.rb production.railsapp.0'

dwebdeploy() {
    $DOC_HOME/utilities/docformation/docformation.rb deploy_web demo --branch=$1
}
alias ddweb=dwebdeploy
drappdeploy() {
    $DOC_HOME/utilities/docformation/docformation.rb deploy_railsapp demo --branch=$1
}
alias ddrapp=drappdeploy

webdeploy() {
    $DOC_HOME/utilities/docformation/docformation.rb deploy_web $1 --branch=$2
}
alias dweb=webdeploy
alias dpweb='$DOC_HOME/utilities/docformation/docformation.rb deploy_web production'

alias tag='$DOC_HOME/utilities/docformation/docformation.rb tag_release --repo='

alias rvmgd='rvm gemset use docurated'
alias rvmgdu='rvm gemset use docurated_util'
alias rs='rails s'
alias rc='rails c'
alias rsp='rails s -p '
alias rcd='rails c development'
alias solrs='cd $DOC_HOME/website/rails/opt/solr/jetty && java -Dsolr.solr.home=docu -jar start.jar'
alias jira='history | grep -e "DIOR" -e "CAS"'

alias c='clear'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias ln='ln -v'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
#alias rcp='rsync -v --progress'
#alias rmv='rsync -v --progress --remove-source-files'

alias g='grep -rn '
alias gi='grep -rni '
alias hist='history'
alias histg='history | grep'

alias psx='ps aux | grep'

#fix for rake tasks
alias rake='noglob rake'

# alias g='git'
alias gs='git status'
alias ga='git add '
alias gco='git checkout '
alias gci='git commit '
alias gb='git branch '
alias gcam='git commit -a -m '
alias gpull='git pull origin '
alias gpush='git push origin '
alias gmm='git merge master'

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
SAVEHIST=100000
HISTSIZE=100000
setopt APPEND_HISTORY
# setopt SHARE_HISTORY # share history between multiple shells
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
plugins=(autojump brew bunder command-not-found gem nyan osx python rails ruby rvm sublime textmate vi-mode web-search zsh-syntax-highlighting)

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

