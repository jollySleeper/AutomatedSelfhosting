#!/bin/bash

# Usage
#   `./podman-setup.sh`
#       Will Try to Install and Start All the Containers in App Folder 
#   `./podman-setup.sh 'start'`
#       Will Start All the Containers in App Folder 
#   `./podman-setup.sh 'stop'`
#       Will Stop All the Containers in App Folder 

for folder in ~/selfhost/apps/*; do
    if [[ "$folder" != *".bak" ]] && [[ -f "$folder/podman-setup.sh" ]]; then
        cd "$folder"
        # Starting Container
        ./podman-setup.sh "$1"

        if [[ "$1" == "start" ]] && [[ $? != 0 ]]; then
            # Installing & Starting Container
            ./podman-setup.sh
        fi
        
        sleep 5
    fi
done
