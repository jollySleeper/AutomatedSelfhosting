#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing DB Data"
podman run \
    --detach \
    -v "$(get_config_dir ${NAME})":/opt/adguardhome/conf \
    -v "$(get_vol_dir ${NAME})/work":/opt/adguardhome/work \
    --name "$NAME-tmp" \
    "$IMAGE_SOURCE"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$NAME-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && chown -v -R $(id -u) /opt/adguardhome/conf && chown -v -R $(id -u) /opt/adguardhome/work"

echo "-> Stopping Temp Container"
podman stop "$NAME-tmp"
echo "-> Removing Temp Container"
podman rm -f "$NAME-tmp"
