# install stuff
apt-get update
apt-get upgrade -y
apt-get install -y git vim zsh wget curl make build-essential
apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev

# create user and assign password
NEW_USER=sampaul
NEW_HOSTNAME=sbp_dev
NEW_IP=`dig +short myip.opendns.com @resolver1.opendns.com`

adduser $NEW_USER --gecos "" --disabled-password
echo "$NEW_USER:password" | chpasswd
adduser $NEW_USER sudo

hostnamectl set-hostname $NEW_HOSTNAME
echo "$NEW_IP $NEW_HOSTNAME.com $NEW_HOSTNAME" >> /etc/hosts

# update /etc/ssh/sshd_config to reject root login/etc.
