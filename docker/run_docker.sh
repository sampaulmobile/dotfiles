#!/bin/bash

DEV_DIR=${1:-$HOME/dev}

if [ ! -d "$DEV_DIR" ]; then
    echo "dev directory does not exist, exiting."
    exit 1
fi

# DOCKERFILE=Dockerfile
# NAME=dev
DOCKERFILE=alpine.Dockerfile
NAME=dev-alpine

docker build -f $DOCKERFILE -t $NAME .
docker run --rm -it \
    --name $NAME \
    --hostname dev-docker \
    --volume "$DEV_DIR":/root/dev \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --workdir /root/dev \
    $NAME:latest
