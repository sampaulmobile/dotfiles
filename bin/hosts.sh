#!/bin/bash

sudo -v
tmp_dir=$HOME/Downloads/hosts

git clone git@github.com:StevenBlack/hosts.git $tmp_dir
python $tmp_dir/updateHostsFile.py \
    --auto --replace --extensions fakenews --flush-dns-cache
rm -rf $tmp_dir

sudo -- sh -c 'echo "#dev for docurated" >> /etc/hosts'
sudo -- sh -c 'echo "127.0.0.1       development.docurated.com" >> /etc/hosts'

