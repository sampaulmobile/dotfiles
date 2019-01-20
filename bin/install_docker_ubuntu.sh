#!/bin/bash
# pulled from https://www.linode.com/docs/applications/containers/how-to-install-docker-and-pull-images-for-container-deployment/

DOCKER_USERNAME=sampaul

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
sudo usermod -aG docker $DOCKER_USERNAME
