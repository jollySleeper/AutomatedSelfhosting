#!/bin/bash

source ../../scripts/common.sh

NAME="seerr"
IMAGE_SOURCE="ghcr.io/seerr-team/seerr:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 --network 'pasta:--map-host-loopback,10.0.2.2' `# Maps 10.0.2.2 to host localhost for backend access` \
 -p ${LOCALHOST_IP}:8068:5055 \
 -v "$(get_vol_dir ${NAME})/config":/app/config \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8068" "http"

echo "Done :)"
