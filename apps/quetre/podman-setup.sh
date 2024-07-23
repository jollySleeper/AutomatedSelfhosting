#!/bin/bash

source ../../scripts/common.sh

NAME="quetre"
IMAGE_SOURCE="codeberg.org/video-prize-ranch/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/prod-http.env" \
 -p ${LOCALHOST_IP}:8012:3000 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8012" "http"

echo "Done :)"
