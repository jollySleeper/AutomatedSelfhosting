#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing NaviDrome DB Data"
podman run \
    --detach \
    -v "$(get_vol_dir ${NAME})/config":/config \
    --name "$NAME-tmp" \
    "$IMAGE_SOURCE"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$NAME-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && /bin/chown -v -R $(id -u):$(id -g) /config"

echo "-> Stopping Temp Container"
podman stop "$NAME-tmp"
echo "-> Removing Temp Container"
podman rm -f "$NAME-tmp"
