if grep -q "StevenBlack/hosts" /etc/hosts; then
	echo "/etc/hosts blacklist already updated, exiting..."
	exit 0
fi

echo "Updating /etc/hosts blacklist..."
sudo -v
tmp_dir=/tmp/hosts

git clone git@github.com:StevenBlack/hosts.git $tmp_dir
python $tmp_dir/updateHostsFile.py \
	--backup --auto --replace --extensions fakenews --flush-dns-cache
rm -rf $tmp_dir
