#!/bin/bash

function check_container() {
    echo "-> Checking for Existing '$1' Container"
    if [[ -z $(podman ps -a --format "{{.Names}}" | grep "$1") ]]; then
        echo "-> Container '$1' Doesnot Exsits"
        export status=1
    else
        echo "-> Container '$1' Already Exsits"
        export status=0
    fi 
}

function start_container() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Starting Container '$1'"
        podman start "$1"
    fi
}

function start_container_and_exit() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Starting Container '$1'"
        podman start "$1"
    fi
    exit ${status}
}

function stop_container() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Stopping Container '$1'"
        podman stop "$1"
    fi
}

function stop_container_and_exit() {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Stopping Container '$1'"
        podman stop "$1"
    fi
    exit ${status}
}

function remove_container () {
    check_container "$1"
    if [[ ${status} == 0 ]]; then
        echo "-> Removing Container '$1'"
        podman rm -f "$1"
    fi
}

