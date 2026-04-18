#!/bin/bash

source ../../scripts/common.sh

NAME="prometheus"
IMAGE_SOURCE="quay.io/$NAME/$NAME:latest"
PORT="9090"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/data"

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#-p ${LOCALHOST_IP}:${PORT}:5555 \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network 'pasta:--map-host-loopback,10.0.2.2' `# Pasta w/ host loopback at 10.0.2.2 (scrapes cadvisor/node-exporter/podman-exporter on host). See docs/DNS_ARCHITECTURE.md` \
 -p $PORT:9090 \
 -v "$(get_config_dir ${NAME})/$NAME.yml":/etc/prometheus/prometheus.yml \
 -v "$(get_vol_dir ${NAME})/data":/$NAME \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
