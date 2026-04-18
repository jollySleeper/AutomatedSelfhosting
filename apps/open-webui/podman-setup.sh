#!/bin/bash

source ../../scripts/common.sh

NAME="open-webui"
IMAGE_SOURCE="ghcr.io/$NAME/$NAME:main"
PORT="8888"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"

# For GPU in future
 # --device /dev/dri:/dev/dri \
 # --device /dev/dma_heap:/dev/dma_heap \
 # --device /dev/mali0:/dev/mali0 \
 # --device /dev/rga:/dev/rga \
 # --device /dev/mpp_service:/dev/mpp_service \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' `#Pasta w/ host loopback at 10.0.2.2. See docs/DNS_ARCHITECTURE.md` \
 -v "$(get_vol_dir ${NAME})/data":/app/backend/data \
 -p ${LOCALHOST_IP}:${PORT}:8080 \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
