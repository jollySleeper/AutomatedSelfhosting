#!/bin/bash
set -euo pipefail

# Generates a random /admin password, stores only its Argon2id PHC hash as
# ADMIN_TOKEN in local.env, and writes the plaintext to a 600-permission file
# for the operator to move into their vault. Re-run to rotate the token.

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$APP_DIR/environments/local.env"
VOLUMES_DIR="$APP_DIR/volumes"
PASSWORD_FILE="$VOLUMES_DIR/admin-password.txt"
CONFIG_JSON="$VOLUMES_DIR/data/config.json"
HASH_IMAGE="docker.io/library/alpine:latest"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $1: $2"
}

if [[ ! -f "$ENV_FILE" ]]; then
    log ERROR "Missing $ENV_FILE"
    exit 1
fi

if [[ -e "$PASSWORD_FILE" ]]; then
    log ERROR "$PASSWORD_FILE already exists. Move the password into your vault and delete the file first."
    exit 1
fi

umask 077
mkdir -p "$VOLUMES_DIR"

password="$(openssl rand -base64 48 | tr -d '\n/+=' | cut -c1-40)"
salt="$(openssl rand -base64 32)"

# Bitwarden preset from the upstream wiki (m=64 MiB, t=3, p=4). The password
# is passed on stdin so it never appears in a process list.
log INFO "Hashing admin password with argon2id"
hash="$(printf '%s' "$password" | podman run --rm -i "$HASH_IMAGE" \
    sh -c 'apk add --no-cache --quiet argon2 >/dev/null && argon2 "$1" -e -id -k 65540 -t 3 -p 4' sh "$salt")"

if [[ "$hash" != '$argon2id$v=19$m=65540,t=3,p=4$'* ]]; then
    log ERROR "Unexpected argon2 output; local.env was not changed"
    exit 1
fi

# Podman env files are literal: the value must stay unquoted, and '$' needs no escaping.
tmp_file="$(mktemp "$VOLUMES_DIR/local.env.XXXXXX")"
grep -v '^ADMIN_TOKEN=' "$ENV_FILE" > "$tmp_file" || true
printf 'ADMIN_TOKEN=%s\n' "$hash" >> "$tmp_file"
mv "$tmp_file" "$ENV_FILE"

printf '%s\n' "$password" > "$PASSWORD_FILE"

log INFO "ADMIN_TOKEN updated in $ENV_FILE"
log INFO "Admin password written to $PASSWORD_FILE (mode 600)"

if [[ -f "$CONFIG_JSON" ]] && grep -q '"admin_token"' "$CONFIG_JSON"; then
    log WARN "$CONFIG_JSON contains admin_token, which overrides ADMIN_TOKEN from local.env."
    log WARN "Change the token in the admin panel instead, or remove that key and restart."
fi

echo "Apply it with: systemctl --user restart ${APP_DIR##*/}.service"
