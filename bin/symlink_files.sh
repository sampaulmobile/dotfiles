#!/bin/bash
############################
# symlink_files.sh
# This script creates symlinks for ALL THE FILES
############################

########## Variables

# dotfiles directory
dir=$HOME/dotfiles/dots

# detect OS
OS="$(uname -s)"

##########

# Helper: force-create a symlink (removes existing file/link first)
link() {
    rm -rf "$2"
    ln -sfv "$1" "$2"
}

# ===== Common dotfiles (both platforms) =====
common_files="gitconfig gitignore tmux.conf tmux.remote.conf"

for file in $common_files; do
    link $dir/$file ~/.$file
done

# ===== zshrc (platform-specific) =====
if [[ "$OS" == "Linux" ]]; then
    link $dir/zshrc_linux ~/.zshrc
else
    link $dir/zshrc ~/.zshrc
fi

# ===== starship =====
mkdir -p ~/.config
link $dir/starship.toml ~/.config/starship.toml

# ===== neovim (LazyVim config) =====
link $dir/nvim ~/.config/nvim

echo "Symlinks created successfully!"
