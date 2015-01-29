#!/bin/bash
############################
# links.sh
# This script creates symlinks for all the rc files (and vundles)
############################

########## Variables

dir=~/dotfiles               # dotfiles directory
deldir=~/DELETE_dotfiles     # backup directory
files="bashrc vimrc zshrc gemrc gitconfig gitignore ackrc"   # list of files/folders to symlink in homedir

##########

# create DELETE_dotfiles in homedir
echo -n "Creating $olddir..."
mkdir -p $olddir
echo "done"

# Remove existing dotfiles and create symlinks for $files
for file in $files; do
    echo "Backing up ~/.$file"
    mv ~/.$file $deldir
    echo "Symlinking to $file in home directory."
    ln -s $dir/$file ~/.$file
done

echo "Linking in vundles"
mkdir -p ~/.vim
mv ~/.vim/vundles.vim $deldir
ln -s $dir/vundles.vim ~/.vim/vundles.vim
echo "Done"

echo "Linking in custom theme (sampaul)"
mv ~/.oh-my-zsh/custom/sampaul.zsh-theme $deldir
ln -s $dir/sampaul.zsh-theme ~/.oh-my-zsh/custom/sampaul.zsh-theme
echo "Done"

echo "ALL FINISHED LINKING RCs"
echo "Be sure to Review/DELETE old dotfiles"


