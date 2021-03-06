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
g++ \
make \
bzip2-dev \
libffi-dev \
linux-headers \
openssl-dev \
readline-dev \
sqlite-dev \
zlib-dev \
"

RUN apk add --update --no-cache $PACKAGES && \
  rm -f /tmp/* /etc/apk/cache/*
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
ENV GIT_URL https://github.com/olivierverdier/zsh-git-prompt.git
RUN git clone $GIT_URL $HOME/.zsh-git-prompt

# install pyenv/python
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
ENV PYTHON_CONFIGURE_OPTS --enable-shared
RUN pyenv install 3.7.2 && \
    pyenv global 3.7.2
RUN ~/dotfiles/bin/pip_installs.sh

# install tpm/plugins
RUN ~/dotfiles/bin/install_tpm.sh
RUN ~/dotfiles/bin/update_tpm_plugins.sh

# install docker / docker-compose
RUN apk add --update --no-cache docker && \
  pip install docker-compose

WORKDIR /root
# CMD ["zsh"]
