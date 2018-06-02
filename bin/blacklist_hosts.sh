if [ $# -eq 0 ] && grep -q "StevenBlack/hosts" /etc/hosts; then
	exit 1
fi

sudo -v
tmp_dir=/tmp/hosts

git clone https://github.com/StevenBlack/hosts.git $tmp_dir
python $tmp_dir/updateHostsFile.py \
	--backup --auto --replace --extensions fakenews --flush-dns-cache
rm -rf $tmp_dir
