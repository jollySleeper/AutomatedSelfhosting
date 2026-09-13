#!/bin/bash

function check_pod() {
    echo "-> Checking for Existing '$1' Pod"
    podman pod exists "$1"
    if [[ $? == 1 ]]; then
        echo "-> Pod '$1' Does not Exist"
        export pod_status=1
    else
        echo "-> Pod '$1' Already Exists"
        export pod_status=0
    fi
}

function start_pod() {
    check_pod "$1"
    if [[ ${pod_status} == 0 ]]; then
        echo "-> Starting Pod '$1'"
        podman pod start "$1"
    fi
}

function start_pod_and_exit() {
    check_pod "$1"
    if [[ ${pod_status} == 0 ]]; then
        echo "-> Starting Pod '$1'"
        podman pod start "$1"
    fi
    exit ${pod_status}
}

function stop_pod() {
    check_pod "$1"
    if [[ ${pod_status} == 0 ]]; then
        echo "-> Stopping Pod '$1'"
        podman pod stop "$1"
    fi
}

function stop_pod_and_exit() {
    check_pod "$1"
    if [[ ${pod_status} == 0 ]]; then
        echo "-> Stopping Pod '$1'"
        podman pod stop "$1"
    fi
    exit ${pod_status}
}

function remove_pod() {
    check_pod "$1"
    if [[ ${pod_status} == 0 ]]; then
        echo "-> Removing Pod '$1'"
        podman pod rm -f "$1"
    fi
}

function install_pod_quadlet() {
    if [[ ! -f "$HOME/selfhost/apps/$1/$1.pod" ]]; then
        echo "-> '$1' Pod's Quadlet File Does Not Exists"
        exit 1
    fi

    mkdir -p ~/.config/containers/systemd
    cd ~/.config/containers/systemd
    echo "-> Installing '$1' Pod's Quadlet File"
    ln -sf "${SELFHOST_ROOT_DIR:-$HOME/selfhost}/apps/$1/$1.pod" .
}
