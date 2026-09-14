#!/bin/bash

echo "Running Temporary Container For Copying Assets from Image"
podman run --name "$name-tmp" "$image_source"

echo "-> Making Required Directories & Running"
touch "$(get_vol_dir ${POD_NAME})/$name/nginx-off"
chmod 777 "$(get_vol_dir ${POD_NAME})/$name/nginx-off"
mkdir -pv "$(get_vol_dir ${POD_NAME})/$name/assets"

podman cp "$name-tmp":/usr/share/nginx/html/assets "$(get_vol_dir ${POD_NAME})/$name/."

echo "-> Replacing Piped-API URL of Assets"
sed -i \
    's|https|http|g' \
    "$(get_vol_dir ${POD_NAME})/$name/assets/"*
sed -i \
    's|pipedapi.kavin.rocks|piped-api.aevion.lan|g' \
    "$(get_vol_dir ${POD_NAME})/$name/assets/"*
sed -i \
    's|pipedproxy.kavin.rocks|piped-proxy.aevion.lan|g' \
    "$(get_vol_dir ${POD_NAME})/$name/assets/"*

# Not Reqd as Working without It
#echo "Replacing Piped-Proxy URL of Assets"
#sed -i 's|https://pipedproxy.kavin.rocks|http://192.168.1.235:8091|g' /usr/share/nginx/html/assets/*

echo "-> Stopping Temp Container"
podman stop "$name-tmp"
echo "-> Removing Temp Container"
podman rm -f "$name-tmp"
