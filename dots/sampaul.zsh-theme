
PROMPTS=()
# Get the current ruby version in use with RVM:
if which rvm >/dev/null 2>&1; then
    RUBY_PROMPT_="%{$FG[124]%}\$(~/.rvm/bin/rvm-prompt v g)%{$reset_color%}"
    PROMPTS+=$RUBY_PROMPT_
fi

# get the current python version with pyenv
if which pyenv >/dev/null 2>&1; then
    PYTHON_PROMPT_="%{$FG[136]%}\$(pyenv version-name)%{$reset_color%}"
    PROMPTS+=$PYTHON_PROMPT_
fi

# get the current kube context
# if which kubectl >/dev/null 2>&1; then
#     KUBE_PROMPT_="%{$FG[140]%}\$(kcc)%{$reset_color%}"
#     PROMPTS+=$KUBE_PROMPT_
# fi

VERS_PROMPT_="%{$fg_bold[blue]%}("
for i in $PROMPTS; do 
  idx=${PROMPTS[(ie)$i]}

  if [ $idx != 1 ]; then
    VERS_PROMPT_=$VERS_PROMPT_"%{$fg_bold[blue]%}|"
  fi
  VERS_PROMPT_=$VERS_PROMPT_"${i}"
done
VERS_PROMPT_=$VERS_PROMPT_"%{$fg_bold[blue]%})%{$reset_color%} "

# if superuser make the username red
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi

# If connected to ssh, show "@ hostname"
if [[ -z "$SSH_CLIENT" ]]; then
  SSH=""
else
  SSH=%{$fg_bold[grey]%}@%{$reset_color$fg[yellow]%}$(hostname -s)
fi

# prompt
HOST="%{$fg[$NCOLOR]%}%B%n%b"$SSH

DIR="%{$reset_color%}:%{$FG[208]%}%40<...<%~%<<%{$reset_color%} "
# DIR="%{$reset_color%}:%{$FG[208]%}%~%{$reset_color%}|"

GIT=""
if which pyenv >/dev/null 2>&1; then
GIT=$'$(git_super_status)
%(!.#.$) ' 
fi

# PROMPT=$HOST$DIR$GIT
PROMPT=$HOST$DIR$VERS_PROMPT_$GIT
#RPROMPT='!%{%B%F{cyan}%}%!%{%f%k%b%}'

# Display time in rprompt
RPROMPT='%{$FG[045]%}%*%{$reset_color%}'
