# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Theme is symlinked to ~/.oh-my-zsh/custom/
ZSH_THEME="sampaul"

DOC_HOME='/Users/sampaul/Development/Docurated'
# ============ Aliases =============
alias dotz="vim ~/dotfiles/zshrc"
alias dotv="vim ~/dotfiles/vimrc"
alias dev="cd ~/Development/SBP"
alias startup="~/dotfiles/startup.sh"

alias docweb='cd $DOC_HOME/website/rails && rvmgd'
alias docutil='cd $DOC_HOME/utilities && rvmgdu'
alias doccli='cd $DOC_HOME/clients && rvmgdu'

#connect and update docconnections
alias con='docutil && $DOC_HOME/utilities/docformation/docconnection.rb'
alias cupdate='docutil && $DOC_HOME/utilities/docformation/docconnection.rb update'

baseconnect() {
    cd $DOC_HOME/utilities/docformation
    rvm gemset use docurated_util
    $DOC_HOME/utilities/docformation/docconnection.rb $1.$2.$3
}

alias cdweb='baseconnect demo web'
alias cdapi='baseconnect demo api'
alias cdrapp='baseconnect demo railsapp'
alias cdfdb='baseconnect demo foundationdb'

alias cpweb='baseconnect production web'
alias cpapi='baseconnect production api'
alias cprapp='baseconnect production railsapp'
alias cpfdb='baseconnect production foundationdb'

alias csweb='baseconnect stage web'
alias csrapp='baseconnect stage railsapp'
alias csfdb='baseconnect stage foundationdb'

alias cchef='docutil && $DOC_HOME/utilities/docformation/docconnection.rb chef.workstation'

alias tag='$DOC_HOME/utilities/docformation/docformation.rb tag_release --repo='

alias pyserv='python -m SimpleHTTPServer'
alias coffserv='coffee --watch --compile --output lib/ src/'

alias rvmgd='rvm gemset use docurated'
alias rvmgdu='rvm gemset use docurated_util'
alias rs='rails s'
alias rc='rails c'
alias rsp='rails s -p '
alias rcd='rails c development'
alias solrs='cd $DOC_HOME/website/rails/opt/solr/jetty && java -Dsolr.solr.home=docu -jar start.jar'
alias testsolrs='docweb && bundle exec sunspot-solr start -p 8984'
alias testsolrr='docweb && bundle exec sunspot-solr run -p 8984'
alias jira='history | grep -e "DIOR" -e "CAS"'

#start up dynamo for tests to run properly
alias start_dynamo='cd ~/dynamo && nohup java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -inMemory -port 8888 > ~/dynamoout.txt 2> ~/dynamoerr.text < /dev/null &'

#mount /volumes/vol
alias mount_vol='sudo mount -t smbfs //Guest@50.17.45.211/vol /private/nfs'

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

alias psg='ps aux | grep'

grepfind() {
    find . -name "*.$1" | xargs grep -n "$2"
}
alias gf=grepfind
grepfindi() {
    find . -name "*.$1" | xargs grep -ni "$2"
}
alias gfi=grepfindi

#remove vim swap files
alias rmswp='find . -name "*.sw*" | xargs rm'
rmpython() {
    find . -name "*.pyc*" | xargs rm
    find . -name "*.pyo*" | xargs rm
}
alias rmpy=rmpython

#fix for rake tasks
alias rake='noglob rake'

fixedrake() {
    bundle exec rake "$1"
}
alias berake=fixedrake
alias berspec='bundle exec rspec'

#FOR FUNN!!!!
alias hip='cd $DOC_HOME/scratch && ruby hippost.rb'

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

# plunchy stuff
alias pstart='plunchy start '
alias pstop='plunchy stop '
alias plist='plunchy -v ls '

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

