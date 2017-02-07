#!/bin/bash
############################
# links.sh
# This script creates symlinks for all the rc files (and vundles)
############################

########## Variables

dir=~/dotfiles/links        # dotfiles directory
deldir=~/DELETE_dotfiles     # backup directory (deprecated)
files="vimrc zshrc gemrc gitconfig gitignore ackrc"   # list of files/folders to symlink in homedir
NOT_PUBLIC='/Users/sampaul/dropbox/!public'

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

echo "Linking SSH config"
mkdir -p ~/.ssh
mv ~/.ssh/config $deldir
ln -s $dir/ssh_config ~/.ssh/config
echo "Done"

echo "Linking in vundles"
mkdir -p ~/.vim
mv ~/.vim/vundles.vim $deldir
ln -s $dir/vundles.vim ~/.vim/vundles.vim
echo "Done"

if [ -d ~/.oh-my-zsh ]; then
    echo "Linking in custom theme (sampaul)"
    mv ~/.oh-my-zsh/custom/sampaul.zsh-theme $deldir
    ln -s $dir/sampaul.zsh-theme ~/.oh-my-zsh/custom/sampaul.zsh-theme
    echo "Done"
fi

if [ -d $NOT_PUBLIC ]; then
    echo "Linking AWS config"
    mkdir -p ~/.aws
    mv ~/.aws/config $deldir
    ln -s $NOT_PUBLIC/aws_config ~/.aws/config
    echo "Done"

    echo "Linking AWS (shared) credentials"
    mkdir -p ~/.aws
    mv ~/.aws/credentials $deldir
    ln -s $NOT_PUBLIC/aws_credentials ~/.aws/credentials
    echo "Done"

    echo "Linking pgpass"
    mv ~/.pgpass $deldir
    ln -s $NOT_PUBLIC/pgpass ~/.pgpass
    echo "Done"
fi

echo "ALL FINISHED LINKING RCs"
echo "DELETING old dotfiles"
rm -rf $deldir

