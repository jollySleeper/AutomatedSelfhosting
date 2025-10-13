#!/bin/bash

source ../../scripts/common.sh

NAME="cadvisor"
# VERSION="v0.49.1" # use the latest release version from https://github.com/google/cadvisor/releases
# VERSION="latest"
VERSION="v0.50.0"
IMAGE_SOURCE="gcr.io/$NAME/$NAME:$VERSION"
PORT="9091"

action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> No Required Directories"

echo "-> Starting Rootless Podman Socket"
# systemctl --user start podman.socket
systemctl --user enable --now podman.socket

echo "-> Running '$NAME' Container"
#--user $(id -u):$(id -g) \
#-p ${LOCALHOST_IP}:${PORT}:5555 \

# /var/run/podman was needed so no need to give all of /var/run
# --volume /var/run:/var/run:rw \

#--volume /var/lib/containers:/var/lib/containers:ro `# Root containers` \


# For Podman Sock
# --podman="unix:///var/run/podman/podman.sock" `# Root Containers` \
# --podman="unix:///var/run/user/$(id -u)/podman/podman.sock" `# Rootless Containers` \
# --volume /run/podman:/var/run/podman:ro `# Root Socket`\
#--volume $XDG_RUNTIME_DIR/podman:/var/run/podman:ro `# Same as /run/user/$(id -u)`\

# TODO: Test this out
#--network=host \

# This was creating problem with user.slice removing this did the trick
#--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \

podman run \
 --replace \
 --detach \
 --privileged \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 -p "$PORT":8080 \
 --device /dev/kmsg \
 --volume /:/rootfs:ro \
 --volume /dev/disk/:/dev/disk:ro \
 --volume /sys:/sys:ro \
 --volume /etc/machine-id:/etc/machine-id:ro \
 --volume /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro \
 --volume ${XDG_RUNTIME_DIR}/podman:/var/run/podman:ro `# Same as /run/user/$(id -u)`\
 --volume ${HOME}/.local/share/containers/:/var/lib/containers:ro `# Rootless Containers` \
 --name "$NAME" \
 "$IMAGE_SOURCE" \
 --podman="unix:///var/run/podman/podman.sock" \
 --docker="unix://" \
 --housekeeping_interval=10s \
 --docker_only=true

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "$PORT" "http"

echo "Done :)"
