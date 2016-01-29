#!/bin/bash
############################
# links.sh
# This script creates symlinks for all the rc files (and vundles)
############################

########## Variables

dir=~/dotfiles/links        # dotfiles directory
deldir=~/DELETE_dotfiles     # backup directory (deprecated)
files="bashrc vimrc zshrc gemrc gitconfig gitignore ackrc"   # list of files/folders to symlink in homedir

##########

# create DELETE_dotfiles in homedir
echo -n "Creating $deldir..."
mkdir -p $deldir
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

echo "Cloning/setting up zsh syntax highlighting"
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "ALL FINISHED LINKING RCs"
echo "DELETING old dotfiles"
rm -rf $deldir

