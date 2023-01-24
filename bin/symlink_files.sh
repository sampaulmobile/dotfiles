#!/bin/bash
############################
# symlink_files.sh
# This script creates symlinks for ALL THE FILES
############################

########## Variables

# dotfiles directory
dir=$HOME/dotfiles/dots

# backup directory (deprecated)
deldir=$HOME/DELETE_dotfiles

# list of files/folders to symlink in homedir
files="vimrc zshrc gitconfig gitignore tmux.conf tmux.remote.conf ideavimrc"

# dropbox !public folder
NOT_PUBLIC=$HOME/Dropbox/!Public

##########

# create DELETE_dotfiles in homedir
mkdir -p $deldir

# Remove existing dotfiles and create symlinks for $files
for file in $files; do
    mv ~/.$file $deldir
    ln -s $dir/$file ~/.$file
done

mkdir -p ~/.vim
mv ~/.vim/plugs.vim $deldir
ln -s $dir/plugs.vim ~/.vim/plugs.vim

if [ -d ~/.oh-my-zsh ]; then
    mv ~/.oh-my-zsh/custom/sampaul.zsh-theme $deldir
    ln -s $dir/sampaul.zsh-theme ~/.oh-my-zsh/custom/sampaul.zsh-theme
fi

if [ $(which nvim) ]; then
    mkdir -p ~/.config/nvim

    mv ~/.config/nvim/init.lua $deldir
    ln -s $dir/init.lua ~/.config/nvim/init.lua

    mkdir -p ~/.config/nvim/lua
    mv ~/.config/nvim/lua $deldir
    ln -s $dir/lua ~/.config/nvim/lua
fi

if [ -d $NOT_PUBLIC/links ]; then
    mkdir -p ~/.aws
    mv ~/.aws/config $deldir
    ln -s $NOT_PUBLIC/links/aws_config ~/.aws/config

    mkdir -p ~/.aws
    mv ~/.aws/credentials $deldir
    ln -s $NOT_PUBLIC/links/aws_credentials ~/.aws/credentials

    mkdir -p ~/.ssh
    mv ~/.ssh/config $deldir
    ln -s $NOT_PUBLIC/links/ssh_config ~/.ssh/config
    mv ~/.ssh/known_hosts $deldir
    ln -s $NOT_PUBLIC/links/ssh_known_hosts ~/.ssh/known_hosts

    mv ~/.pgpass $deldir
    ln -s $NOT_PUBLIC/links/pgpass ~/.pgpass

    if [ -d $HOME/.kube ]; then
	mv ~/.kube/client.crt $deldir
	ln -s $NOT_PUBLIC/keys/sam.paul.vpn.crt ~/.kube/client.crt
	mv ~/.kube/client.key $deldir
	ln -s $NOT_PUBLIC/keys/sam.paul.vpn.key ~/.kube/client.key
	mv ~/.kube/ca.crt $deldir
	ln -s $NOT_PUBLIC/keys/docurated.intermediate.crt ~/.kube/ca.crt
    fi

    if [ -d $HOME/Library/Application\ Support/Tunnelblick ]; then
	mv ~/Library/Application\ Support/Tunnelblick/Configurations $deldir
	ln -s $NOT_PUBLIC/keys/Configurations ~/Library/Application\ Support/Tunnelblick/Configurations
    fi
fi
rm -rf $deldir
