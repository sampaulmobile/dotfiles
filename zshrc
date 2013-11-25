# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="ys"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git brew bunder gem nyan osx python rails4 ruby rvm sublime textmate vi-mode web-search zsh-syntax-highlighting)

# Use vi-mode in the shell
bindkey -v
bindkey -M viins 'jj' vi-cmd-mode #map jj to exit (mimic ESC)

source $ZSH/oh-my-zsh.sh

alias dev="cd ~/Dropbox/Development/"

# Customize to your needs...
export PATH=/usr/local/bin:/usr/local/sbin:/bin:/usr/sbin:/sbin:/usr/bin:/opt/X11/bin:$PATH
export PATH=$PATH:/Users/sampaul/.rvm/gems/ruby-2.0.0-p247/bin:/Users/sampaul/.rvm/gems/ruby-2.0.0-p247@global/bin:/Users/sampaul/.rvm/rubies/ruby-2.0.0-p247/bin:/Users/sampaul/.rvm/bin:/Users/sampaul/.rvm/bin

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 

typeset -U path

source ~/.zsh-autosuggestions/autosuggestions.zsh

# Enable autosuggestions automatically
zle-line-init() {
    zle autosuggest-start
}
zle -N zle-line-init

# use ctrl+t to toggle autosuggestions(hopefully this wont be needed as
# zsh-autosuggestions is designed to be unobtrusive)
bindkey '^T' autosuggest-toggle

