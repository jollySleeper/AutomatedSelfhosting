#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing PostgreSQL DB Data"
podman run \
   --detach \
    --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
    -v "$(get_config_dir ${POD_NAME})/$name-resolv.conf":/etc/resolv.conf:ro \
    -v "$(get_vol_dir ${POD_NAME})/$name/lib":/var/lib \
    -v "$(get_vol_dir ${POD_NAME})/$name/lib/$name":/var/lib/tailscale \
    --name "$name-tmp" \
    "$image_source"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$name-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && chown -v -R $(id -u) /var/lib/tailscale"

echo "-> Stopping Temp Container"
podman stop "$name-tmp"
echo "-> Removing Temp Container"
podman rm -f "$name-tmp"
