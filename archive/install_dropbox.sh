
cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64"
sudo mkdir /opt/dropbox
sudo tar xzfv dropbox-linux.tar.gz --strip 1 -C /opt/dropbox
rm -f ~/dropbox-linux.tar.gz

python2 /opt/dropbox/dropbox.py exclude add Documents media Development Reading
