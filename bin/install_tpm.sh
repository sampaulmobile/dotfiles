if [ $# -eq 0 ] && [ -d ~/.tmux/plugins/tpm ]; then
    exit 1
fi

mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
