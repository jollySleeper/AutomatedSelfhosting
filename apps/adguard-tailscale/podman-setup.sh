#!/bin/bash

source ../../scripts/common.sh

POD_NAME="adguard-tailscale"

# action_based_on_query "$1-pod" "$POD_NAME" "$IMAGE_SOURCE"

echo "Creating '$POD_NAME' Pod"

# Not Needed Both Options as Dont Know
 #--network slirp4netns:port_handler=slirp4netns,allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
# Allows External IPs Without Proxy to Container
 #--network slirp4netns:port_handler=slirp4netns \
# Now Using Pasta which will allow External IP & Connection to Host, Other Use Cases of Pasta Not Working
 #--network pasta:--map-gw \
# podman pod create \
#  --network slirp4netns:port_handler=slirp4netns,allow_host_loopback=true `#Allows 127.0.0.1 of Host in Container` \
#  -p 53:53/tcp       `# AGH Plain DNS` \
#  -p 53:53/udp       `# AGH Plain DNS` \
#  -p ${LOCALHOST_IP}:8000:8000/tcp     `# Dashboard` \
#  -p 8001:8000/tcp     `# Dashboard` \
#  --name "$POD_NAME"

# NOTE: Podlet doesn't Support Creation of .pod files for Pods
# action_based_on_query "install-pod-quadlet" "$POD_NAME"

function run_pod_container() {
    name=$1
    image_source=$2
    echo "-> Running '$name' Container"

    case "$name" in
        "adguardhome")
            echo "-> Making Required Directories"
            mkdir -pv "$(get_vol_dir ${name})/work"

            # Making Files Data for Rootless Container; Reqd by Both Folders
            files=$(ls -A $(get_vol_dir ${name})/work)
            if [[ $? == 0 ]] && [[ -z "$files" ]]; then
                source ../${name}/scripts/rootless-data.sh
            fi

            podman run \
                --pod "$POD_NAME" \
                --detach \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --user $(id -u):$(id -g) \
                -v "$(get_config_dir ${name})":/opt/adguardhome/conf \
                -v "$(get_vol_dir ${name})/work":/opt/adguardhome/work \
                --name "$name" \
                "$image_source"

            #action_based_on_query "generate-nginx-conf-file" "$name" "aevion" "lan" "8001" "http"
            ;;

         "tailscale")
            echo "-> Making Required Directories"
            mkdir -pv "$(get_vol_dir ${name})/lib/$name"

	        # Making Files Data for Rootless Container
            files=$(ls -A $(get_vol_dir ${name})/lib/${name})
            if [[ $? == 0 ]] && [[ ! -z "$files" ]]; then
                source ../${name}/scripts/rootless-data.sh
            fi

                #--sysctl net.ipv4.conf.all.forwarding=1 \
		        #--detach \
                #--cap-add=NET_RAW `#Makes all the traffic for tailIP`\
                #--sysctl net.ipv4.ip_forward=1 \
            podman run \
                --pod "$POD_NAME" \
                --privileged \
                --restart unless-stopped \
                --label io.containers.autoupdate=registry \
                --cap-add=NET_ADMIN \
                --cap-add=SYS_MODULE \
                --device /dev/net/tun:/dev/net/tun \
                --env-file "$(get_env_dir ${name})/$name.env" \
                -v "$(get_config_dir ${name})/resolv.conf":/etc/resolv.conf:ro \
                -v "$(get_vol_dir ${name})/lib":/var/lib \
                -v "$(get_vol_dir ${name})/lib/$name":/var/lib/tailscale \
                --name "$name" \
                "$image_source"
            # podman run \
            #     --restart unless-stopped \
            #     --label io.containers.autoupdate=registry \
            #     --cap-add=NET_ADMIN \
            #     --cap-add=NET_RAW \
            #     --device /dev/net/tun:/dev/net/tun \
            #     --user $(id -u):$(id -g) \
            #     --env-file "$(get_env_dir ${POD_NAME})/$name.env" \
            # 	-v "$(get_config_dir ${POD_NAME})/$name/resolv.conf":/etc/resolv.conf:ro \
            #     -v "$(get_vol_dir ${POD_NAME})/$name/lib":/var/lib \
            #     -v "$(get_vol_dir ${POD_NAME})/$name/lib/$name":/var/lib/tailscale \
            #     --name "$name" \
            #     "$image_source"
            ;;
        *)
            echo default
            ;;
    esac

}

#for name in "adguardhome" "tailscale"; do
for name in "tailscale"; do
    if [[ "$name" == "adguardhome" ]]; then
        image_source="docker.io/adguard/$name:latest"
    else
        image_source="docker.io/$name/$name:latest"
    fi

    action_based_on_query "$1-con" "$name" "$image_source"

    run_pod_container "$name" "$image_source"

    # action_based_on_query "generate-con-quadlet" "$name"
    # action_based_on_query "install-con-quadlet" "$name" "$POD_NAME"
done

echo "Done :)"
