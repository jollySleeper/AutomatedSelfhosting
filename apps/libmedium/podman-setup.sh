#!/bin/bash

source ../../scripts/common.sh

NAME="libmedium"
IMAGE_SOURCE="docker.io/realaravinth/$NAME:latest"
PORT="8014"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 -p ${LOCALHOST_IP}:${PORT}:7000 \
 -v "$(get_config_dir ${NAME})/local.toml":/etc/libmedium/config.toml \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
