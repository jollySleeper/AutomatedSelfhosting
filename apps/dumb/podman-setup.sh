#!/bin/bash

source ../../scripts/common.sh

NAME="dumb"
IMAGE_SOURCE="ghcr.io/rramiachraf/$NAME:latest"
PORT="8016"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 -p ${LOCALHOST_IP}:${PORT}:5555 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"
action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "https"

echo "Done :)"
