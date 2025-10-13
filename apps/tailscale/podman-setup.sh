#!/bin/bash

source ../../scripts/common.sh

NAME="tailscale"
IMAGE_SOURCE="docker.io/$NAME/$NAME:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/lib/$NAME"

# Making Files Data for Rootless Container
# files=$(ls -A $(get_vol_dir ${NAME})/lib/${NAME})
# if [[ $? == 0 ]] && [[ -z "$files" ]]; then
#     source ./scripts/${NAME}-rootless-data.sh
# fi

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#--sysctl net.ipv4.ip_forward=1 \

    #--sysctl net.ipv4.conf.all.forwarding=1 \
    #--detach \
podman run \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --network slirp4netns:allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
 -v "$(get_config_dir ${NAME})/resolv.conf":/etc/resolv.conf:ro \
 --cap-add=NET_ADMIN \
 --cap-add=SYS_MODULE \
 --device /dev/net/tun:/dev/net/tun \
 --env-file "$(get_env_dir ${NAME})/tailscale.env" \
 -p 3000:3000 \
 -p 8001:8000 \
 -v "$(get_vol_dir ${NAME})/lib":/var/lib \
 -v "$(get_vol_dir ${NAME})/lib/$NAME":/var/lib/tailscale \
 -v "$(get_script_dir ${NAME})/entrypoint.sh":/entrypoint.sh \
 -v "$(get_config_dir 'adguardhome')":/tmp/AdGuardHome/conf \
 -v "$(get_vol_dir 'adguardhome')/work":/tmp/AdGuardHome/work \
 --entrypoint /entrypoint.sh \
 --name "$NAME" \
 "$IMAGE_SOURCE"

#action_based_on_query "generate-con-quadlet" "$NAME"
#action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# Generate NGINX Conf File
#action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8001" "http"

echo "Done :)"
