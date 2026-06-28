#!/bin/bash

source ../../scripts/common.sh

NAME="rimgo"

IMAGE_SOURCE="codeberg.org/$NAME/$NAME:latest"
PORT="8019"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:${PORT}:3000 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
