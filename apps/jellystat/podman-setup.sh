#!/bin/bash

source ../../scripts/common.sh

NAME="jellystat"
IMAGE_SOURCE="docker.io/cyfershepard/jellystat:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/backup"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8069:3000 \
 -v "$(get_vol_dir ${NAME})/backup":/app/backend/backup-data \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8069" "http"

echo "Done :)"
