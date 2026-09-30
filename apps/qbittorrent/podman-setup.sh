#!/bin/bash

source ../../scripts/common.sh

NAME="qbittorrent"
IMAGE_SOURCE="ghcr.io/linuxserver/qbittorrent:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$HOME/media/Downloads/complete/movies"
mkdir -pv "$HOME/media/Downloads/complete/tv"
mkdir -pv "$HOME/media/Downloads/complete/music"
mkdir -pv "$HOME/media/Downloads/complete/books"
mkdir -pv "$HOME/media/Downloads/incomplete"

echo "-> Running '$NAME' Container"
# =============================================================================
# DNS BYPASS of AdGuardHome (see /docs/DNS_ARCHITECTURE.md for full rationale)
# =============================================================================
# Several torrent tracker domains are caught by AGH's StevenBlack Extra
# blocklist and AGH SafeBrowsing (e.g. bt.xxx-tracker.com, tracker.bittor.pw,
# glotorrents.pw, tracker1.520.jp, tracker1.myporn.club, p4p.arenabg.ch).
# qBittorrent is a specialized outbound workload that does not need DNS-level
# ad/malware filtering; sending its DNS straight to public resolvers avoids
# false positives.
#
# TWO THINGS ARE REQUIRED for the bypass to actually work:
#
#   1) --dns 1.1.1.1 --dns 9.9.9.9 in the [Container] section of the quadlet
#      (captured by podlet from this `podman run`).
#
#   2) Environment=CONTAINERS_CONF=/dev/null in the [Service] section of the
#      quadlet. Injected below, after podlet generates the file.
#
# Why both? Podman 5.4.1 APPENDS --dns values to containers.conf's dns_servers
# instead of overriding them. Without CONTAINERS_CONF=/dev/null, the container's
# /etc/resolv.conf ends up with 192.168.1.105 (AGH, from containers.conf) listed
# FIRST, then 1.1.1.1, 9.9.9.9. This image is Alpine/musl, whose resolver queries
# ALL nameservers in parallel — AGH's sinkhole response (94.140.14.33 / 0.0.0.0)
# can win the race.
#
# We pass CONTAINERS_CONF=/dev/null to the initial `podman run` below so the
# container we create on first install is correct immediately. The Environment=
# injection (see inject-quadlet-env action) makes systemd use the same override
# on every subsequent restart.
# =============================================================================
CONTAINERS_CONF=/dev/null podman run \
 --detach \
 --replace \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 --dns 1.1.1.1 \
 --dns 9.9.9.9 \
 -p ${LOCALHOST_IP}:8061:8061 \
 -p 6881:6881 \
 -p 6881:6881/udp \
 -v "$HOME/media/Downloads":/downloads \
 -v "$(get_vol_dir ${NAME})/config":/config \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "inject-quadlet-env" "$NAME" "Environment=CONTAINERS_CONF=/dev/null"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8061" "http"

echo "Done :)"
