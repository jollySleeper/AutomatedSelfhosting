#!/bin/bash

source ../../scripts/common.sh

NAME="aria2"
IMAGE_SOURCE="docker.io/p3terx/aria2-pro:latest"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

ARIANG_NAME="ariang"
ARIANG_IMAGE="docker.io/p3terx/ariang:latest"

action_based_on_query "$1-con" "$ARIANG_NAME" "$ARIANG_IMAGE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/config"
mkdir -pv "$HOME/media/Downloads/aria2"

echo "-> Running '$NAME' Container (aria2 RPC daemon)"
# Two extra bind mounts to apply our repo-tracked aria2.conf overrides at
# container boot (instead of doing it from the host after start):
#   - apply-overrides.sh -> /etc/cont-init.d/48-apply-overrides
#       Runs as part of the image's s6-overlay init chain, AFTER `28-fix`
#       (which applies env-driven sed substitutions) and BEFORE service
#       startup. Re-runs on every container restart, so the override file
#       below is the only place anyone needs to edit.
#   - local.aria2.conf.overrides -> /etc/aria2-overrides.conf
#       The file the script reads. Bind-mounted live, so editing it on the
#       host and restarting aria2 is enough to roll out new overrides — no
#       re-running of podman-setup.sh required.
# See apps/aria2/README.md → "Aria2 conf overrides" for the full rationale.
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --env-file "$(get_env_dir ${NAME})/local.env" \
 -p ${LOCALHOST_IP}:8062:6800 \
 -p 6888:6888 \
 -p 6888:6888/udp \
 -v "$(get_vol_dir ${NAME})/config":/config \
 -v "$HOME/media/Downloads/aria2":/downloads \
 -v "$(get_script_dir ${NAME})/apply-overrides.sh":/etc/cont-init.d/48-apply-overrides:ro \
 -v "$(get_config_dir ${NAME})/local.aria2.conf.overrides":/etc/aria2-overrides.conf:ro \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

echo "-> Running '$ARIANG_NAME' Container (Web UI for aria2)"
podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -p ${LOCALHOST_IP}:8063:6880 \
 --name "$ARIANG_NAME" \
 "$ARIANG_IMAGE"

action_based_on_query "generate-con-quadlet" "$ARIANG_NAME"
action_based_on_query "install-con-quadlet" "$ARIANG_NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$ARIANG_NAME" "aevion" "lan" "8063" "http"

echo "Done :)"
