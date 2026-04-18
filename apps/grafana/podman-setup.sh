#!/bin/bash

source ../../scripts/common.sh

NAME="grafana"
IMAGE_SOURCE="docker.io/$NAME/$NAME-oss:latest"
PORT="3300"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#-p ${LOCALHOST_IP}:${PORT}:5555 \
podman run \
 --replace \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' `# Pasta w/ host loopback at 10.0.2.2 (Prometheus, Loki scrapes). See docs/DNS_ARCHITECTURE.md` \
 -p $PORT:3000 \
 -v "$(get_vol_dir ${NAME})/data":/var/lib/$NAME \
 -v "$(get_config_dir ${NAME})/$NAME.ini":/etc/grafana/grafana.ini \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
