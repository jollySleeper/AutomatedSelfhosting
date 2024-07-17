#!/bin/bash

function check_image () {
    echo "-> Checking for Existing '$1' Image"
    if [[ -z $(podman images -q "$1") ]]; then
        echo "-> Image Doesnot Exsits"
        export status=1
    else
        echo "-> Image Already Exsits"
        export status=0
    fi 
}

function build_image() {
    check_image "$2"
    if [[ ${status} != 0 ]]; then
        echo "-> Building '$1' Image"
        cp docker/Dockerfile .
        podman build -f Dockerfile
        if [[ $? == 0 ]]; then
            podman tag $(podman images | awk '{print $3}' | awk 'NR==2') "$2"
            echo "-> Deleting Image Used for Building"
            remove_old_images
        fi
        rm Dockerfile
    fi
}

function remove_old_images() {
    podman images --format '{{.Tag}},{{.ID}}' | grep '<none>' | cut -d ',' -f 2 | xargs podman rmi
} 
