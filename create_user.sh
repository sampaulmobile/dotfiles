# create user and assign password
NEW_USER=sam
adduser $NEW_USER
adduser $NEW_USER sudo

# update /etc/ssh/sshd_config to reject root login/etc.

NEW_HOSTNAME=sbp_dev
NEW_IP=45.33.90.186
hostnamectl set-hostname $NEW_HOSTNAME
sudo cat "$NEW_IP $NEW_HOSTNAME.com $NEW_HOSTNAME" > /etc/hosts
