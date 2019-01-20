#!/bin/bash

docker build -t dev .
docker run -it dev
