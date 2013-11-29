
# Load git-prompt methods
source ~/dotfiles/git-prompt/zshrc.sh

# Get the current ruby version in use with RVM:
if [ -e ~/.rvm/bin/rvm-prompt ]; then
    RUBY_PROMPT_="%{$fg_bold[blue]%}(%{$FG[124]%}\$(~/.rvm/bin/rvm-prompt s i v g)%{$fg_bold[blue]%})%{$reset_color%} "
else
  if which rbenv &> /dev/null; then
    RUBY_PROMPT_="%{$fg_bold[blue]%}rbenv:(%{$fg[green]%}\$(rbenv version | sed -e 's/ (set.*$//')%{$fg_bold[blue]%})%{$reset_color%} "
  fi
fi

# calculate space between prompt and rprompt
function put_spacing() {
  local git=$(git_super_status)
  if [ ${#git} != 0 ]; then
    ((git=${#git} - 90))
  else
    git=0
  fi

  local rubylen=${#RUBY_PROMPT_}
  (( rubylen = rubylen - 1))

  local dirpath=${#PWD}
  if [ dirpath > 30 ]; then
    ((dirpath=30))
  fi

  local termwidth
  (( termwidth = ${COLUMNS} - ${#USERNAME} - ${#HOST} - ${#PWD} - ${rubylen} - ${git} ))

  local spacing=""
  for i in {1..$termwidth}; do
    spacing="${spacing} " 
  done
  echo $spacing
}

# if superuser make the username green
if [ $UID -eq 0 ]; then NCOLOR="green"; else NCOLOR="white"; fi

# prompt
HOST="[%{$fg[$NCOLOR]%}%B%n%b"
DIR="%{$reset_color%}:%{$fg[red]%}%30<...<%~%<<%{$reset_color%}]|"

GIT=$'$(git_super_status)
%(!.#.$) ' 

PROMPT=$HOST$DIR$RUBY_PROMPT_$GIT
RPROMPT='!%{%B%F{cyan}%}%!%{%f%k%b%}'
