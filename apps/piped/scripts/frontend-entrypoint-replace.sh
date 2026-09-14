#!/bin/ash

echo "Piped Frontend Started"

# NOTE: ASSET folder to be attached to the Container with 777 for Rootless Operation
echo "Copying NGINX/HTML to TMP/HTML Folder"
cp -r /usr/share/nginx/html /tmp/html
ls -la /tmp/html

echo "Greping Kavin API"
grep -ioH 'pipedapi.kavin.rocks' /tmp/html/*
grep -ioH 'pipedapi.kavin.rocks' /tmp/html/assets/*
echo "Replacing Piped-API URL"
sed -i 's|https://pipedapi.kavin.rocks|http://piped-api.aevion.lan|g' /tmp/html/assets/*
echo "Greping Aevion API"
grep -ioH 'piped-api.aevion.lan' /tmp/html/*
grep -ioH 'piped-api.aevion.lan' /tmp/html/assets/*

echo "Greping Kavin Proxy"
grep -ioH 'pipedproxy.kavin.rocks' /tmp/html/*
grep -ioH 'pipedproxy.kavin.rocks' /tmp/html/assets/*
echo "Replacing Piped-Proxy URL"
sed -i 's|https://pipedproxy.kavin.rocks|http://piped-proxy.aevion.lan|g' /tmp/html/assets/*
echo "Greping Aevion Proxy"
grep -ioH 'piped-proxy.aevion.lan' /tmp/html/*
grep -ioH 'piped-proxy.aevion.lan' /tmp/html/assets/*

# EntryPoint
ash -c '/docker-entrypoint.sh && echo "Starting Nginx" && nginx -g "daemon off;"'
