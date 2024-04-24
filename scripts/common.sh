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
