NEW_USER=${1:-sampaul}
NEW_HOST=${2:-sbp_dev}

# install stuff
apt-get update
apt-get upgrade -y
apt-get install -y git vim jq

# PUB_KEY_URL="https://www.dropbox.com/s/rwvh7mfqwm4zx0f/id_rsa_linode.pub?dl=0"
PUB_KEY_URL=https://api.github.com/users/sampaulmobile/keys
PUB_KEY_NAME=sampaulmobile.pub

# create user and assign password
adduser $NEW_USER --gecos "" --disabled-password
adduser $NEW_USER sudo

mkdir /home/$NEW_USER/.ssh
cd /home/$NEW_USER/.ssh
curl $PUB_KEY_URL | jq -r '.[length-1]["key"]' >> $PUB_KEY_NAME
cp $PUB_KEY_NAME authorized_keys
chmod 600 /home/$NEW_USER/.ssh/*
chmod 700 /home/$NEW_USER/.ssh
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

hostnamectl set-hostname $NEW_HOST
EXT_IP=$(curl ifconfig.me)
echo "$EXT_IP $NEW_HOST.com $NEW_HOST" >> /etc/hosts

# update /etc/ssh/sshd_config to reject root login/etc.

# to allow user to sudo w/o password
# sudo update-alternatives --config editor
# sudo visudo
# $USER ALL=(ALL) NOPASSWD: ALL
