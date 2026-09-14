#!/bin/ash

echo "Piped Frontend Started"

# EntryPoint
ash -c '/docker-entrypoint.sh && echo "Starting Nginx" && nginx -g "daemon off;"'
