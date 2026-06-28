#!/bin/bash

source ../../scripts/common.sh

NAME="paperless-ngx"
IMAGE_SOURCE="ghcr.io/paperless-ngx/paperless-ngx:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"
mkdir -pv "$(get_vol_dir ${NAME})/media"
mkdir -pv "$(get_vol_dir ${NAME})/export"
mkdir -pv "$(get_vol_dir ${NAME})/consume"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8033:8000 \
 -v "$(get_vol_dir ${NAME})/data":/usr/src/paperless/data \
 -v "$(get_vol_dir ${NAME})/media":/usr/src/paperless/media \
 -v "$(get_vol_dir ${NAME})/export":/usr/src/paperless/export \
 -v "$(get_vol_dir ${NAME})/consume":/usr/src/paperless/consume \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8033" "http"

echo "Done :)"
