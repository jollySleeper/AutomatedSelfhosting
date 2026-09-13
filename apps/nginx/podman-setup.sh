#!/bin/bash

source ../../scripts/common.sh

NAME="nginx"
IMAGE_SOURCE="docker.io/library/$NAME:stable-alpine"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
#mkdir -pv "$(get_vol_dir ${NAME})/lib/$NAME"

echo "-> Running '$NAME' Container"
# Slirp4netns: Working but SLOW (~0.5 MB/s for video streaming)
 #--network slirp4netns:allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
 #--network slirp4netns:port_handler=slirp4netns,allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \

# Pasta: FAST (~4-6 MB/s for video streaming) - 8x faster than slirp4netns
 #--network=pasta \                                    # Basic pasta, no host loopback
 #--network=pasta:--map-gw \                           # BROKEN: syntax issue
 #--network 'pasta:--map-host-loopback,10.0.2.2' \     # WORKING: maps 10.0.2.2 to host localhost
 #--network pasta:-a,10.0.2.0,-n,24,-g,10.0.2.2,--dns-forward,10.0.2.3,-T,8882 \ # Trying for tailscale in container

podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --userns keep-id \
 --network 'pasta:--map-host-loopback,10.0.2.2' `# Maps 10.0.2.2 to host localhost for backend access` \
 -p 80:1080 \
 -p 443:1443 \
 --tmpfs /tmp:size=1G `# RAM-backed /tmp: proxy_buffering temp files go to RAM, not NVMe SSD` \
 -v "$(get_config_dir ${NAME})/rootless/nginx.conf":/etc/nginx/nginx.conf \
 -v "$(get_config_dir ${NAME})/snippets":/etc/nginx/snippets \
 -v "$(get_config_dir ${NAME})/certs":/etc/nginx/certs \
 -v "$(get_config_dir ${NAME})/sites":/etc/nginx/conf.d \
 -v "$(get_config_dir ${NAME})/html":/usr/share/nginx/html:ro `# Static landing page for home.aevion.lan dashboard` \
 `# -v "$(get_config_dir ${NAME})/.htpasswd":/etc/nginx/.htpasswd:ro # Uncomment to enable dashboard Basic Auth (create file first, see home.conf)` \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "Done :)"
