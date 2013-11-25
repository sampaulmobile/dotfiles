
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

### Added by the Heroku Toolbelt
export PATH=/usr/local/heroku/bin:$PATH

alias es=elasticsearch

elasticsearch() {
  /usr/local/elasticsearch/bin/elasticsearch $1
}
