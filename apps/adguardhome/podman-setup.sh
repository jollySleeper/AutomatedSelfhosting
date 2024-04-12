#!/bin/bash

source ../../scripts/common.sh

NAME="adguardhome"
IMAGE_SOURCE="docker.io/adguard/$NAME:latest"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/work"

echo "-> Running '$NAME' Container"
# Experimenting with DHCP
    #--network host \ Network = HOST Not reqd for preserving IPs
# Network = rootlesskit by default using slirp4netns with flag for preserving IPs
    #--cap-add NET_RAW \
    #--userns keep-id   `# Reqd for Reading Config | Or Make files rootless` \
# Rootless Mode
    #--user $(id -u):$(id -g) \
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network slirp4netns:port_handler=slirp4netns \
 -p 53:53/tcp       `# Plain DNS` \
 -p 53:53/udp       `# Plain DNS` \
 -p ${LOCALHOST_IP}:8000:8000/tcp     `# Dashboard` \
 -v "$(get_config_dir ${NAME})":/opt/adguardhome/conf \
 -v "$(get_vol_dir ${NAME})/work":/opt/adguardhome/work \
 --hostname "$NAME" \
 --name "$NAME" \
 "$IMAGE_SOURCE"

echo "Done :)"
