#!/bin/bash
# pulled from https://www.linode.com/docs/applications/containers/how-to-use-docker-compose/

sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
