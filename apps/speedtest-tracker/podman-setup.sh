#!/bin/bash

source ../../scripts/common.sh

NAME="speedtest-tracker"
IMAGE_SOURCE="lscr.io/linuxserver/speedtest-tracker:1.12.4"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"

echo "-> Running '$NAME' Container"
# Note: Using v1.12.4 as v1.13.0+ uses ICMP ping for connectivity checks which doesn't work
# in rootless Podman with pasta/slirp4netns networking (ICMP traffic is blocked)
# See: https://github.com/alexjustesen/speedtest-tracker/issues/2611
podman run \
 --detach \
 --replace \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8054:80 \
 -v "$(get_vol_dir ${NAME})/config":/config \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# Generate nginx config for both domains
# echo "-> Generating nginx configuration for speedtest.aevion.lan"
# action_based_on_query "generate-nginx-conf-file" "speedtest" "aevion" "lan" "8054" "http"

echo "Done :)"
