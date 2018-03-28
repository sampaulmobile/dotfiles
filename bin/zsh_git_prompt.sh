OPT_DIR=/usr/local/opt
if [ $# -eq 0 ] && [ -d $OPT_DIR/zsh-git-prompt ]; then
	exit 0
fi

GIT_URL=https://github.com/olivierverdier/zsh-git-prompt.git
git clone $GIT_URL $OPT_DIR/zsh-git-prompt

# setup prompt to use haskell for 4x+ speed
curl -sSL https://get.haskellstack.org/ | sh
cd $OPT_DIR/zsh-git-prompt
stack setup
stack build && stack install
