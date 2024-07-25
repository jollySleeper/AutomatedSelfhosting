#!/bin/bash

source ../../scripts/common.sh

NAME="redlib"
IMAGE_SOURCE="quay.io/$NAME/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/safe.env" \
 -p ${LOCALHOST_IP}:8013:8080 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8013" "http"

echo "Done :)"
