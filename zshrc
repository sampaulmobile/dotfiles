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
alias csback='con stage.backends'
alias csrapp='baseconnect stage railsapp'
alias csfdb='baseconnect stage foundationdb'

alias cadmin='baseconnect production admin'

alias cchef='docutil && $DOC_HOME/utilities/docformation/docconnection.rb chef.workstation'

alias dfdbstat='docutil && $DOC_HOME/utilities/docformation/docconnection.rb demo.foundationdb.10 "fdbcli --exec \"status details\""'
alias pfdbstat='docutil && $DOC_HOME/utilities/docformation/docconnection.rb production.foundationdb.3 "fdbcli --exec \"status details\""'

alias tag='$DOC_HOME/utilities/docformation/docformation.rb tag_release --repo='

taillog() {
    cd $DOC_HOME/utilities/docformation
    rvm gemset use docurated_util
    lines=100
    N=${2:-$lines}
    ./docconnection.rb $1.web "tail -n $N /mnt/app/website/rails/log/$1.log"
}

alias taild='taillog demo'
alias tailp='taillog production'

setDemoVersion() {
    cd $DOC_HOME/clients/deploy
    rm client_demo_version.txt
    touch client_demo_version.txt
    echo $1 > client_demo_version.txt
    s3cmd put client_demo_version.txt s3://docurated-private/client_demo_version.txt
}

alias pyserv='doccli && python -m SimpleHTTPServer'
alias coffserv='doccli && cd browser && coffee --watch --compile --output lib/ src/'
# alias cliserv='doccli && pyserv'
# alias cliserv='doccli && cd browser && coffserv'
alias clogd='doccli && tail -f app.log'
alias clog='tail -f ~/.docurated/app.log'

alias rvmgd='rvm gemset use docurated'
alias rvmgdu='rvm gemset use docurated_util'
alias rs='rails s'
alias rc='rails c'
alias rsp='rails s -p '
alias rcd='docweb && rails c development'
alias rsd='docweb && thin start --ssl --ssl-verify --ssl-key-file ~/Development/server.key --ssl-cert-file ~/Development/server.crt'
alias solrsold='cd $DOC_HOME/website/rails/opt/solr/jetty && java -Dsolr.solr.home=docu -jar start.jar'
alias solrs='cd /opt/solr/solr-4.10.2/example && java -jar start.jar'
alias testsolrs='docweb && bundle exec sunspot-solr start -p 8984'
alias testsolrr='docweb && bundle exec sunspot-solr run -p 8984'
alias jira='history | grep -e "DIOR" -e "CAS"'

alias wlog='docweb && tail -f log/development.log'


alias pd='doccli && python docurated.py'

# alias events='docweb && bundle exec ruby bin/event_trackor_server_control.rb start'
alias eventr='docweb && bundle exec ruby bin/event_trackor_server_control.rb restart'
alias events='docweb && bundle exec ruby bin/event_trackor_server_control.rb stop'

#workers
alias start_resqs='docweb && resque-scheduler --environment development &'
alias start_resqp='docweb && resque-pool --environment development &'
alias start_sidekiq='docweb && RAILS_ENV=development sh bin/sidekiq.sh start &'

alias stop_resqs='pkill -f "resque-scheduler"'
alias stop_resqp='pkill -f "resque-pool-master"'
alias stop_sidekiq='docweb && RAILS_ENV=development sh bin/sidekiq.sh stop'

alias start_workers='start_resqs; start_resqp; start_sidekiq'
alias stop_workers='stop_resqs; stop_resqp; stop_sidekiq'

alias start_all='pstarts; testsolrs; start_dynamo; start_workers; solrs &'
alias start_cli='pyserv &; coffserv &; doccli; mount_vol'

alias dresq='docutil && docformation/docconnection.rb demo.railsapp "ps -ef f | grep resque"'
alias sresq='docutil && docformation/docconnection.rb stage.railsapp "ps -ef f | grep resque"'

alias bci='cd $DOC_HOME/time && rmswp && vim bci.txt'
alias notes='cd ~/Development/SBP/notes && rmswp && vim notes.txt'

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

alias psg=psgrep
psgrep() {
    ps aux | grep $1 | grep -v grep
}
psgrepi() {
    ps aux | grep -i $1 | grep -v grep
}
alias psgi=psgrepi

grepfind() {
    find . -name "*.$1" | xargs grep --color=auto -n "$2"
}
alias gf=grepfind
grepfindi() {
    find . -name "*.$1" | xargs grep --color=auto -ni "$2"
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

#websites!!
alias hubc='open https://github.com/Docurated/clients'
alias hubw='open https://github.com/Docurated/website'
alias hubu='open https://github.com/Docurated/utilities'
alias hubs='open https://github.com/Docurated/services'

searchgit() {
    open "https://github.com/Docurated/$1/search?utf8=✓&q=$2"
}
alias hubcs='searchgit clients'
alias hubws='searchgit website'
alias hubus='searchgit utilities'
alias hubss='searchgit services'

alias sl='open http://www.seamless.com/food-delivery/vendors.m'
alias slmmg='open http://www.seamless.com/food-delivery/muscle-maker-grill-chelsea-new-york-city.29481.r'
alias sltoast='open http://www.seamless.com/food-delivery/toasties-delicatessen-new-york-city.1898.r'
alias slzumi='open http://www.seamless.com/food-delivery/izumi-sushi-new-york-city.1688.r'

alias weather='open http://www.weather.com/weather/hourbyhour/l/10012:4:US'

alias resqd='open https://demosecure.docurated.com/site/resque/overview'
alias resqp='open https://admin.docurated.com/site/resque/overview'

alias jenk='open https://jenkins.docurated.com/'
alias jenkc='open https://jenkins.docurated.com/job/Client%20Build/'
alias jenks='open https://jenkins.docurated.com/job/BuildTestDeployWebStage/'
alias jenkw='open https://jenkins.docurated.com/job/BuildTestDeployWebMaster/'

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
alias pstarts='pstart redis && pstart post && pstart mongo'

# rvm stuff
alias rvml='rvm list'
alias rvmgl='rvm gemset list'
alias rvmg='rvm gemset use'
alias rvmrc="echo 'rvm --create use$1' >> .rvmrc"

#spec testing
alias ber='bundle exec rspec'

#shared drive mounting
alias msd='sudo mount -t smbfs //Guest@50.17.45.211/vol /private/nfs'

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
plugins=(autojump brew bunder command-not-found gem nyan osx python ruby rvm sublime textmate vi-mode web-search zsh-syntax-highlighting)

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

