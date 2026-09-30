#!/bin/bash

source ../../scripts/common.sh

NAME="hyperpipe"
IMAGE_SOURCE="codeberg.org/$NAME/$NAME:latest"

# TODO: Requires Backend as well, So onhold till Backend is not needed

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8045:80 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8045" "http"

echo "Done :)"
