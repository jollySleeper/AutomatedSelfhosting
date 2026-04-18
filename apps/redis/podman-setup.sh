#!/bin/bash

source ../../scripts/common.sh

NAME="redis"
IMAGE_SOURCE="docker.io/valkey/valkey:alpine"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -p ${LOCALHOST_IP}:6379:6379 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
