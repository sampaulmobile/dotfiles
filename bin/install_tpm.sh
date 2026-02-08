if [ $# -eq 0 ] && [ -d ~/.tmux/plugins/tpm ]; then
    exit 0
fi

mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
