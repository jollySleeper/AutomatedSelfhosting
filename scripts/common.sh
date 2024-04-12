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

