#!/bin/bash

LOCALHOST_IP="127.0.0.1"
SELFHOSTED_APPS_PATH="$HOME/selfhost/apps"
REL_DIR=$(echo ${BASH_SOURCE[0]} | sed "s|/common.sh||")

function print_install() {
    echo "Installing '$1' Using Podman"
}

function get_vol_dir() {
    echo "$SELFHOSTED_APPS_PATH/$1/volumes"
}

function get_env_dir() {
    echo "$SELFHOSTED_APPS_PATH/$1/environments"
}

function get_script_dir() {
    echo "$SELFHOSTED_APPS_PATH/$1/scripts"
}

function get_config_dir() {
    echo "$SELFHOSTED_APPS_PATH/$1/configs"
}

function source_container() {
    source ${REL_DIR}/podman/container.sh
}

function source_image() {
    source ${REL_DIR}/podman/image.sh
}

function generate_nginx_conf_file() {
    subdomain=${1}
    domain=${2}
    tld=${3}
    port=${4}
    protocol=${5}
    template="$SELFHOSTED_APPS_PATH/nginx/configs/site-templates/$protocol-template.conf"
    conf_file="$SELFHOSTED_APPS_PATH/nginx/configs/sites/$subdomain.conf"

    echo "-> Making Nginx Confg File for '$subdomain'"
    cp "$template" "$conf_file"
    sed -i "s|{{subdomain}}|$subdomain|g" "$conf_file"
    sed -i "s|{{domain}}|$domain|g" "$conf_file"
    sed -i "s|{{tld}}|$tld|g" "$conf_file"
    sed -i "s|{{port}}|$port|g" "$conf_file"
}
function action_based_on_query() {
    appName=${2}
    imageSource=${3}

    case "$1" in
        "start-con")
            source_container
            start_container_and_exit "$appName"
            ;;
        "stop-con")
            source_container
            stop_container_and_exit "$appName"
            ;;
        "generate-nginx-conf-file")
            generate_nginx_conf_file "$appName" ${3} ${4} ${5} ${6}
            ;;
        "-con")
            # Install
            print_install "$appName"
            source_container
            # Stopping & Removing Pod Removes all of its Containers
            # But Doing it Anyways as Containers with same Name can exist
            stop_container "$appName"
            remove_container "$appName"
            source_image
            pull_image "$appName" "$imageSource"
            ;;
        *)
            echo "lol"
            ;;
    esac
}
