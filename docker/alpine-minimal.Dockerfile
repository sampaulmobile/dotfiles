FROM alpine
MAINTAINER Sam Paul <sampaulmobile@gmail.com>

ENV HOME /root
ENV PACKAGES="\
bash \
wget \
curl \
zsh \
vim \
git \
tmux \
"

RUN apk update && \
    apk add --update --no-cache $PACKAGES
RUN rm -f /tmp/* /etc/apk/cache/*
ENV SHELL /bin/zsh

# clone dotfiles
RUN git clone https://github.com/sampaulmobile/dotfiles.git ~/dotfiles

# Install oh-my-zsh
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh \
    && cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# symlink dots (and some others)
RUN ~/dotfiles/bin/symlink_files.sh

# setup vim
RUN ~/dotfiles/bin/install_vim_plug.sh
RUN ~/dotfiles/bin/update_vim_plugs.sh
# RUN /scripts/setup_ycm.sh

# setup zsh shell/prompt
RUN ~/dotfiles/bin/install_zsh_syntax_highlighting.sh
# RUN ~/dotfiles/bin/zsh_git_prompt.sh

# install tpm/plugins
RUN ~/dotfiles/bin/install_tpm.sh
RUN ~/dotfiles/bin/update_tpm_plugins.sh

WORKDIR /root
CMD ["zsh"]
