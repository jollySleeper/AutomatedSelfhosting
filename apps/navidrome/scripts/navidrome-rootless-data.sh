#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing NaviDrome DB Data"
podman run \
    --detach \
    -v "$(get_vol_dir ${NAME})/data":/data \
    --env-file "$(get_env_dir ${NAME})/local.env" \
    --name "$NAME-tmp" \
    "$IMAGE_SOURCE"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$NAME-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && /bin/chown -v -R $(id -u):$(id -g) /data"

echo "-> Stopping Temp Container"
podman stop "$NAME-tmp"
echo "-> Removing Temp Container"
podman rm -f "$NAME-tmp"
