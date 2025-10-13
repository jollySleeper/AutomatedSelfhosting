#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

NAME=$name

echo "-> Running Temporary Container For Initializing PostgreSQL DB Data"
podman run \
   --detach \
    --env-file "$(get_env_dir ${NAME})/$NAME.env" \
    -v "$(get_config_dir ${NAME})/resolv.conf":/etc/resolv.conf:ro \
    -v "$(get_vol_dir ${NAME})/lib":/var/lib \
    -v "$(get_vol_dir ${NAME})/lib/$NAME":/var/lib/tailscale \
    --name "$NAME-tmp" \
    "$image_source"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$NAME-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && chown -v -R $(id -u) /var/lib/tailscale"

echo "-> Stopping Temp Container"
podman stop "$NAME-tmp"
echo "-> Removing Temp Container"
podman rm -f "$NAME-tmp"
