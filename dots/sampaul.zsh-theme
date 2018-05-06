# Get the current ruby version in use with RVM:
if [ -e ~/.rvm/bin/rvm-prompt ]; then
    RUBY_PROMPT_="%{$FG[124]%}\$(~/.rvm/bin/rvm-prompt v g)%{$reset_color%}"
fi

# get the current python version with pyenv
if [ -d ~/.pyenv ]; then
    PYTHON_PROMPT_="%{$FG[136]%}\$(pyenv version-name)%{$reset_color%}"
fi

# get the current python version with pyenv
if [ -d ~/.kube ]; then
    KUBE_PROMPT_="%{$FG[140]%}\$(kcc)%{$reset_color%}"
fi

if [ -e ~/.rvm/bin/rvm-prompt ] || [ -d ~/.pyenv ] || [ -d ~/.kube ]; then
    VERS_PROMPT_="%{$fg_bold[blue]%}("
    if [ -e ~/.rvm/bin/rvm-prompt ]; then
        VERS_PROMPT_=$VERS_PROMPT_$RUBY_PROMPT_
    fi
    if [ -d ~/.pyenv ]; then
        VERS_PROMPT_=$VERS_PROMPT_"%{$fg_bold[blue]%}|"$PYTHON_PROMPT_
    fi
    if [ -d ~/.kube ]; then
        VERS_PROMPT_=$VERS_PROMPT_"%{$fg_bold[blue]%}|"$KUBE_PROMPT_
    fi
    VERS_PROMPT_=$VERS_PROMPT_"%{$fg_bold[blue]%})%{$reset_color%} "
fi

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
if [ -d ~/.pyenv ]; then
GIT=$'$(git_super_status)
%(!.#.$) ' 
fi

PROMPT=$HOST$DIR$GIT
# PROMPT=$HOST$DIR$VERS_PROMPT_$GIT
#RPROMPT='!%{%B%F{cyan}%}%!%{%f%k%b%}'

# Display time in rprompt
RPROMPT='%{$FG[045]%}%*%{$reset_color%}'
