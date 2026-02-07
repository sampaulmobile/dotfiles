if [ $# -eq 0 ] && grep -q "StevenBlack/hosts" /etc/hosts; then
    exit 1
fi

sudo -v

# tmp_dir=/tmp/hosts
# git clone https://github.com/StevenBlack/hosts.git $tmp_dir
# pip install --user -r $tmp_dir/requirements_python2.txt
# python $tmp_dir/updateHostsFile.py \
# 	--backup --auto --replace --extensions fakenews --flush-dns-cache
# rm -rf $tmp_dir

curl -o /tmp/hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts
sudo mv -f /tmp/hosts /etc/hosts
