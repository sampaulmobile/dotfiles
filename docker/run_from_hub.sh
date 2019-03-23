#!/bin/bash

DEV_DIR=${1:-$HOME/dev}

if [ ! -d "$DEV_DIR" ]; then
    echo "dev directory does not exist, exiting."
    exit 1
fi

# NAME=sampaul/dev
NAME=sampaul/dev:alpine

docker run -itd \
    --name dev \
    --hostname dev-docker \
    --volume "$DEV_DIR":/root/dev \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --workdir /root/dev \
    $NAME
