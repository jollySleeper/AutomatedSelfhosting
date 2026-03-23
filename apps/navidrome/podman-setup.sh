#!/bin/bash

source ../../scripts/common.sh

NAME="navidrome"
IMAGE_SOURCE="docker.io/deluan/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data/cache"

# Making DB Data for Rootless Container
if [[ -z "$(ls -A $(get_vol_dir ${NAME})/data/*.db)" ]]; then
    source ./scripts/${NAME}-rootless-data.sh
fi

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8043:4533 \
 -v "$(get_vol_dir ${NAME})/data":/data \
 -v ${HOME}/media/Songs:/music \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8043" "http"

echo "Done :)"
