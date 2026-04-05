#!/bin/bash

# Doc for Rootless
# https://github.com/docker-library/docs/blob/master/postgres/README.md#arbitrary---user-notes

echo "-> Running Temporary Container For Initializing PostgreSQL DB Data"
podman run \
    --detach \
    --env-file "$(get_env_dir ${NAME})/db.env" \
    -v "$(get_script_dir ${NAME})/multi-db-entrypoint.sh":/docker-entrypoint-initdb.d/entrypoint.sh \
    -v "$(get_vol_dir ${NAME})/data":/var/lib/postgresql/data \
    --name "$NAME-tmp" \
    "$IMAGE_SOURCE"

echo "-> Sleeping 5"
sleep 5

echo "-> Running Podman Exec Command To Change Permission"
podman exec -it "$NAME-tmp" \
    /bin/sh -c "echo '-> Changing Permission' && chown -v -R $(id -u) /var/lib/postgresql/data"

echo "-> Stopping Temp Container"
podman stop "$NAME-tmp"
echo "-> Removing Temp Container"
podman rm -f "$NAME-tmp"
