#!/bin/bash

set -eu

echo "Authenticating with 1Password"
signin_address="https://my.1password.com"
email="sampaulmobile@gmail.com"
OP_SESSION_my=$(op signin $signin_address $email --output=raw)
export OP_SESSION_my

echo "Pulling secrets"
if [ ! -f ~/.ssh/sampaulmobile_rsa ]; then
	op get document 'sampaulmobile_rsa' > ~/.ssh/sampaulmobile_rsa
	chmod 0600 ~/.ssh/sampaulmobile_rsa
fi

echo "Done!"
