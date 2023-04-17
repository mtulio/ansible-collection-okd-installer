#!/bin/bash

# Run AWS mock server with Moto project.
# https://github.com/getmoto/moto
# Note: alternatives of Mock AWS API: Localstack*
#  Localstack offers runs very well with okd-installer with
#  limitations of mocking elbv2 API which is offered by a 
#  Premium version, making it unviable to this project.

IMG="ghcr.io/getmoto/motoserver:latest"
NAME="mock-aws-api"
IMG="quay.io/mrbraga/motorserver-patch:latest"
NAME="mock-aws-api-patched"
PORT="5000"
OPTS=""

echo "# Running AWS Mock API on port 3000"
podman run --rm \
    --name $NAME \
    -p "${PORT}:5000" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -d $IMG $OPTS

echo "You can populate and check the Dashboard http://localhost:$PORT/moto-api/"
