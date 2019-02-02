#!/bin/bash

DEV_DIR=${1:-$HOME/dev}

if [ ! -d "$DEV_DIR" ]; then
    echo "dev directory does not exist, exiting."
    exit 1
fi

docker build -t dev .
docker run --rm -it \
    --name dev \
    --hostname dev-docker \
    --volume "$DEV_DIR":/root/dev \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --workdir /root/dev \
    dev:latest
