#!/bin/bash

DEV_DIR=${1:-$HOME/dev}

if [ ! -d "$DEV_DIR" ]; then
    echo "dev directory does not exist, exiting."
    exit 1
fi

DOCKERFILE=Dockerfile
NAME=dev
# DOCKERFILE=alpine.Dockerfile
# NAME=dev-alpine

# build the image
docker build -f $DOCKERFILE -t $NAME .

# run container (in background)
docker run -td \
    --name $NAME \
    --hostname dev-docker \
    --volume "$DEV_DIR":/root/dev \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /tmp:/tmp \
    --volume "$HOME/.ssh:/root/.ssh:ro" \
    --workdir /root/dev \
    $NAME:latest

# exec zsh on container
# docker exec -it $NAME zsh
