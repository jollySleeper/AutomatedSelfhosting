#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing PostgreSQL DB Data"
podman run \
    --detach \
    -v "$(get_vol_dir ${POD_NAME})/$name/data":/var/lib/postgresql/data \
    --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
    --name "$name-tmp" \
    "$image_source"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$name-tmp" \
    /bin/bash -c "echo '-> Changing Permission' && chown -v -R $(id -u) /var/lib/postgresql/data"

echo "-> Stopping Temp Container"
podman stop "$name-tmp"
echo "-> Removing Temp Container"
podman rm -f "$name-tmp"
