#!/bin/bash
############################
# symlink_files.sh
# This script creates symlinks for ALL THE FILES
############################

########## Variables

# dotfiles directory
dir=$HOME/dotfiles/dots

# backup directory
deldir=$HOME/DELETE_dotfiles

# detect OS
OS="$(uname -s)"

##########

# create backup dir
mkdir -p $deldir

# Helper: backup existing file, then symlink
link() {
    mv "$2" $deldir 2>/dev/null
    ln -sv "$1" "$2"
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

echo ""
echo "Symlinks created successfully!"
echo "Old dotfiles backed up to: $deldir"
read -p "Delete backup directory? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf $deldir
    echo "Backup deleted."
fi
