#!/bin/bash

sudo -v
tmp_dir=$HOME/Downloads/hosts

git clone git@github.com:StevenBlack/hosts.git $tmp_dir
python $tmp_dir/updateHostsFile.py \
    --auto --replace --extensions fakenews --flush-dns-cache
rm -rf $tmp_dir

