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

# ===== Mac-only dotfiles =====
if [[ "$OS" == "Darwin" ]]; then
    link $dir/ideavimrc ~/.ideavimrc

    # Dropbox-linked sensitive files (Mac only)
    NOT_PUBLIC=$HOME/Dropbox/!Public
    if [ -d $NOT_PUBLIC/links ]; then
        mkdir -p ~/.aws
        link $NOT_PUBLIC/links/aws_config ~/.aws/config
        link $NOT_PUBLIC/links/aws_credentials ~/.aws/credentials

        mkdir -p ~/.ssh
        link $NOT_PUBLIC/links/ssh_config ~/.ssh/config
        link $NOT_PUBLIC/links/ssh_known_hosts ~/.ssh/known_hosts

        link $NOT_PUBLIC/links/pgpass ~/.pgpass

        if [ -d $HOME/.kube ]; then
            link $NOT_PUBLIC/keys/sam.paul.vpn.crt ~/.kube/client.crt
            link $NOT_PUBLIC/keys/sam.paul.vpn.key ~/.kube/client.key
            link $NOT_PUBLIC/keys/docurated.intermediate.crt ~/.kube/ca.crt
        fi

        if [ -d "$HOME/Library/Application Support/Tunnelblick" ]; then
            link $NOT_PUBLIC/keys/Configurations "$HOME/Library/Application Support/Tunnelblick/Configurations"
        fi
    fi
fi

echo "Symlinks created successfully!"
