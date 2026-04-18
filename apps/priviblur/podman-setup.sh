#!/bin/bash

source ../../scripts/common.sh

NAME="priviblur"

IMAGE_SOURCE="ghcr.io/jollysleeper/$NAME:master"
PORT="8110"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
# --user $(id -u):$(id -g) \
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -p ${LOCALHOST_IP}:${PORT}:8000 \
 -v "$(get_config_dir ${NAME})/config.toml":/priviblur/config.toml:Z,ro \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
