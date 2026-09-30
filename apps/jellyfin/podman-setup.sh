#!/bin/bash

source ../../scripts/common.sh

NAME="jellyfin"
# Pinned to the 10.11 line: the transcoding issue is fixed in 10.11.7 (tested).
IMAGE_SOURCE="ghcr.io/$NAME/$NAME:10.11"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$(get_vol_dir ${NAME})/cache"

echo "-> Running '$NAME' Container"

# Check README.md (### Hardware Acceleration Configuration) for more information on hardware acceleration configuration

# podman run \
#  --annotation run.oci.keep_original_groups=1 \
#  --privileged \
#  --detach \
#  --restart unless-stopped \
#  --label io.containers.autoupdate=registry \
#  --device /dev/dri:/dev/dri \
#  --device /dev/dma_heap:/dev/dma_heap \
#  --device /dev/mali0:/dev/mali0 \
#  --device /dev/rga:/dev/rga \
#  --device /dev/mpp_service:/dev/mpp_service \
#  -p ${LOCALHOST_IP}:8041:8096/tcp \
#  -v "$(get_vol_dir ${NAME})/config":/config \
#  -v "$(get_vol_dir ${NAME})/cache":/cache \
#  -v "$HOME/media":/media \
#  -v "/mnt/ssd/home/Media":/media-ssd \
#  -v "$(get_script_dir ${NAME})/entrypoint-root.sh":/entrypoint.sh \
#  --entrypoint /entrypoint.sh \
#  --hostname "$NAME" \
#  --name "$NAME" \
#  "$IMAGE_SOURCE"

# Official Jellyfin Rockchip RKMPP configuration (privileged mode required for hardware acceleration)
podman run \
 --privileged \
 --annotation run.oci.keep_original_groups=1 \
 --detach \
 --replace \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --userns keep-id \
 --group-add $(id -g) \
 --group-add keep-groups \
 --security-opt systempaths=unconfined \
 --security-opt apparmor=unconfined \
 --device /dev/dri:/dev/dri \
 --device /dev/dma_heap:/dev/dma_heap \
 --device /dev/mali0:/dev/mali0 \
 --device /dev/rga:/dev/rga \
 --device /dev/mpp_service:/dev/mpp_service \
 --device /dev/iep:/dev/iep \
 --device /dev/rk-mpp:/dev/rk-mpp \
 --device /dev/rkvdec:/dev/rkvdec \
 --device /dev/rkvenc:/dev/rkvenc \
 --device /dev/vepu:/dev/vepu \
 --device /dev/h265e:/dev/h265e \
 -p ${LOCALHOST_IP}:8041:8096/tcp \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$(get_vol_dir ${NAME})/cache":/cache \
 -v "$HOME/media":/media \
 -v "/mnt/ssd/home/Media":/media-ssd \
 -v "$(get_script_dir ${NAME})/entrypoint-rootless.sh":/entrypoint.sh \
 --entrypoint /entrypoint.sh \
 --hostname "$NAME" \
 --name "$NAME-2" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8041" "http"

echo "Done :)"
