#!/bin/bash

source ../../scripts/common.sh

POD_NAME="immich"

function run_pod_container() {
    name=$1
    image_source=$2
    echo "-> Running '$name' Container"

    case "$name" in
        "immich-server")
            echo "-> Making Required Directories & Running"
            # Making DB Data for Rootless Container
            # files=$(ls -A $(get_vol_dir ${POD_NAME})/${name}/data)
            # if [[ $? == 0 ]] && [[ -z "$files" ]]; then
            #     source ./scripts/postgres-rootless-data.sh
            # fi

            # --user $(id -u):$(id -g) \
            podman run \
                --replace \
                --annotation run.oci.keep_original_groups=1 \
                --privileged \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --network 'pasta:--map-host-loopback,10.0.2.2' `#Pasta w/ host loopback at 10.0.2.2. See docs/DNS_ARCHITECTURE.md` \
                --device /dev/rga:/dev/rga \
                --device /dev/dri:/dev/dri \
                --device /dev/dma_heap:/dev/dma_heap \
                --device /dev/mali0:/dev/mali0 `#Only required to enable OpenCL-accelerated HDR to SDR tonemapping` \
                --device /dev/mpp_service:/dev/mpp_service \
                --env-file "$(get_env_dir ${POD_NAME})/server.env" \
                -p 2283:2283 \
                -v "$HOME/media/Photos":/usr/src/app/photos \
                -v "$HOME/media/Photos/Immich":/usr/src/app/upload \
                -v /etc/OpenCL:/etc/OpenCL:ro \
                -v /usr/lib/aarch64-linux-gnu/libmali.so.1:/usr/lib/aarch64-linux-gnu/libmali.so.1:ro \
                --name "$name" \
                "$image_source"
            ;;
        "immich-machine-learning")
            # --user $(id -u):$(id -g) \
            podman run \
                --replace \
                --privileged \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --network 'pasta:--map-host-loopback,10.0.2.2' `#Pasta w/ host loopback at 10.0.2.2. See docs/DNS_ARCHITECTURE.md` \
                --device /dev/mali0:/dev/mali0 \
                --env-file "$(get_env_dir ${POD_NAME})/server.env" \
                -p 3003:3003 \
                -v model-cache:/cache \
                -v /lib/firmware/mali_csffw.bin:/lib/firmware/mali_csffw.bin:ro `# Mali firmware for your chipset (not always required depending on the driver)` \
                -v /usr/lib/aarch64-linux-gnu/libmali.so:/usr/lib/libmali.so:ro `# Mali driver for your chipset (always required)` \
                --name "$name" \
                "$image_source"
            ;;
        *)
            echo default
            ;;
    esac
}

for name in "immich-server" "immich-machine-learning"; do
    image_source="ghcr.io/immich-app/$name"
    if [[ "$name" == "immich-server" ]]; then
        tag="release"
    elif [[ "$name" == "immich-machine-learning" ]]; then
        tag="release-armnn"
    fi

    action_based_on_query "$1-con" "$name" "$image_source:$tag"

    run_pod_container "$name" "$image_source:$tag"

    # action_based_on_query "generate-con-quadlet" "$name"
    # action_based_on_query "install-con-quadlet" "$name" "$POD_NAME"
done

echo "Done :)"
