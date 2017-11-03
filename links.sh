#!/bin/bash
############################
# links.sh
# This script creates symlinks for all the rc files (and vundles)
############################

########## Variables

dir=$HOME/dotfiles/links        # dotfiles directory
deldir=$HOME/DELETE_dotfiles     # backup directory (deprecated)
files="vimrc zshrc gemrc gitconfig gitignore ackrc"   # list of files/folders to symlink in homedir
NOT_PUBLIC=$HOME/dropbox/!public

##########

# create DELETE_dotfiles in homedir
mkdir -p $deldir

# Remove existing dotfiles and create symlinks for $files
for file in $files; do
    echo "Linking $file..."
    mv ~/.$file $deldir
    ln -s $dir/$file ~/.$file
done

echo "Linking SSH config..."
mkdir -p ~/.ssh
mv ~/.ssh/config $deldir
ln -s $dir/ssh_config ~/.ssh/config

echo "Linking vundles..."
mkdir -p ~/.vim
mv ~/.vim/vundles.vim $deldir
ln -s $dir/vundles.vim ~/.vim/vundles.vim

echo "Linking plugged..."
mkdir -p ~/.vim
mv ~/.vim/plugged.vim $deldir
ln -s $dir/plugged.vim ~/.vim/plugged.vim

if [ -d ~/.oh-my-zsh ]; then
    echo "Linking in custom theme (sampaul)..."
    mv ~/.oh-my-zsh/custom/sampaul.zsh-theme $deldir
    ln -s $dir/sampaul.zsh-theme ~/.oh-my-zsh/custom/sampaul.zsh-theme
fi

if [ -d $NOT_PUBLIC/links ]; then
    echo "Linking AWS config..."
    mkdir -p ~/.aws
    mv ~/.aws/config $deldir
    ln -s $NOT_PUBLIC/links/aws_config ~/.aws/config

    echo "Linking AWS (shared) credentials..."
    mkdir -p ~/.aws
    mv ~/.aws/credentials $deldir
    ln -s $NOT_PUBLIC/links/aws_credentials ~/.aws/credentials

    echo "Linking ssh known_hosts..."
    mv ~/.ssh/known_hosts $deldir
    ln -s $NOT_PUBLIC/links/ssh_known_hosts ~/.ssh/known_hosts

    echo "Linking pgpass..."
    mv ~/.pgpass $deldir
    ln -s $NOT_PUBLIC/links/pgpass ~/.pgpass
fi

echo "ALL FINISHED LINKING RCs"
echo "DELETING old dotfiles"
rm -rf $deldir
echo "Done."

