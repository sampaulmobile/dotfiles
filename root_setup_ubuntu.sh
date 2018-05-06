NEW_USER=sampaul
NEW_PASS=password
NEW_HOST=sbp_dev
PUB_KEY_URL=https://www.dropbox.com/s/rwvh7mfqwm4zx0f/id_rsa_linode.pub?dl=0

# install stuff
apt-get update
apt-get upgrade -y
apt-get install -y git vim zsh wget curl make build-essential
apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev

# create user and assign password
adduser $NEW_USER --gecos "" --disabled-password
echo "$NEW_USER:$NEW_PASS" | chpasswd
adduser $NEW_USER sudo

mkdir /home/$NEW_USER/.ssh
cd /home/$NEW_USER/.ssh
curl -O -J -L $PUB_KEY_URL
cp id_rsa_linode.pub authorized_keys
chmod 600 /home/$NEW_USER/.ssh/*
chmod 700 /home/$NEW_USER/.ssh
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

hostnamectl set-hostname $NEW_HOST
EXT_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
echo "$EXT_IP $NEW_HOST.com $NEW_HOST" >> /etc/hosts

# update /etc/ssh/sshd_config to reject root login/etc.
