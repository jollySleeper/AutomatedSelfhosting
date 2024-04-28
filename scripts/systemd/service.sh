#!/bin/bash

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
