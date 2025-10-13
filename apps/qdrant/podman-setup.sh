#!/bin/bash

source ../../scripts/common.sh

NAME="qdrant"
IMAGE_SOURCE="docker.io/$NAME/$NAME:latest"
PORT="6333"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -v "$(get_vol_dir ${NAME})/data":/qdrant/storage \
 -p ${PORT}:${PORT} \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
