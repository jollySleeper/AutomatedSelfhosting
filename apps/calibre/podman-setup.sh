#!/bin/bash

source ../../scripts/common.sh

NAME="calibre"
IMAGE_SOURCE="lscr.io/linuxserver/calibre:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Creating required directories"
mkdir -p "$(get_vol_dir ${NAME})"

echo "-> Running '$NAME' Container"
podman run \
 --detach \
 --replace \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env PUID=$(id -u) \
 --env PGID=$(id -g) \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p 9080:8080 \
 -p 9181:8181 \
 -p 9081:8081 \
 -p 9092:9090 \
 -v "$(get_vol_dir ${NAME})":/config \
 -v ~/media/Books:/books \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# NOTE: nginx reverse proxy disabled for this app
# Reason: Calibre requires HTTPS but our nginx setup lacks SSL certificates for upstream proxying.
# Container networking issues with HTTPS upstream connections also occur.
# Solution: Expose Calibre ports directly to LAN instead of using reverse proxy.
#
# SECURITY NOTE: Ports are now exposed to entire LAN (not just localhost).
# Risks: Potential unauthorized access from network devices.
# Mitigation: Calibre has built-in authentication (PASSWORD in local.env).
# Monitor access logs and consider firewall rules if security is a concern.
#
# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "9181" "https"

echo "Done :)"
