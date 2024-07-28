#!/bin/bash

source ../../scripts/common.sh

NAME="libremdb"
IMAGE_SOURCE="localhost/zyachel/$NAME"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=local \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8015:3000 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8015" "http"

echo "Done :)"
