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
OPTS="-p3000 --debug True"

echo "# Running AWS Mock API on port 3000"
podman run \
    --name $NAME \
    -p "3000:3000" \
    -d $IMG $OPTS

echo "You can populate and check the Dashboard http://localhost:3000/moto-api/"