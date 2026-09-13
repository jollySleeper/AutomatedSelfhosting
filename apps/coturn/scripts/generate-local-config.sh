#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SELFHOST_DIR="$(cd -- "$APP_DIR/../.." && pwd)"
ENV_FILE="$APP_DIR/environments/local.env"
RTC_CONFIG_FILE="$SELFHOST_DIR/apps/pairdrop/volumes/config/rtc_config.json"
PAIRDROP_ENV_FILE="$SELFHOST_DIR/apps/pairdrop/environments/local.env"

for command in openssl jq; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Required command not found: $command" >&2
        exit 1
    fi
done

umask 077
mkdir -p "$(dirname -- "$RTC_CONFIG_FILE")"

if [[ ! -f "$ENV_FILE" ]]; then
    turn_password="$(openssl rand -hex 32)"
    {
        echo "# Coturn - Local Configuration"
        echo "# Generated credentials; do not commit this file"
        echo
        echo "TURN_USERNAME=pairdrop"
        echo "TURN_PASSWORD=$turn_password"
        echo "TURN_REALM=turn.aevion.lan"
    } > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${TURN_USERNAME:?TURN_USERNAME is required in $ENV_FILE}"
: "${TURN_PASSWORD:?TURN_PASSWORD is required in $ENV_FILE}"
: "${TURN_REALM:?TURN_REALM is required in $ENV_FILE}"

if [[ ! -f "$PAIRDROP_ENV_FILE" ]]; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Missing $PAIRDROP_ENV_FILE" >&2
    exit 1
fi

# LinuxServer changes /config ownership to the configured PUID/PGID. Source
# those non-secret numeric values so regeneration also works after first boot.
# shellcheck disable=SC1090
source "$PAIRDROP_ENV_FILE"
: "${PUID:?PUID is required in $PAIRDROP_ENV_FILE}"
: "${PGID:?PGID is required in $PAIRDROP_ENV_FILE}"

if [[ ! "$PUID" =~ ^[0-9]+$ || ! "$PGID" =~ ^[0-9]+$ ]]; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: PairDrop PUID/PGID must be numeric" >&2
    exit 1
fi

if [[ ! "$TURN_USERNAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: TURN_USERNAME contains unsupported characters" >&2
    exit 1
fi

if [[ ! "$TURN_REALM" =~ ^[A-Za-z0-9.-]+$ ]]; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: TURN_REALM is not a valid DNS-style realm" >&2
    exit 1
fi

rtc_config_tmp="$(mktemp "${TMPDIR:-/tmp}/pairdrop-rtc-config.XXXXXX")"
trap 'rm -f "$rtc_config_tmp"' EXIT

jq -n \
    --arg turn_host "$TURN_REALM" \
    --arg username "$TURN_USERNAME" \
    --arg credential "$TURN_PASSWORD" \
    '{
        sdpSemantics: "unified-plan",
        iceServers: [
            {urls: ("stun:" + $turn_host + ":3478")},
            {
                urls: [
                    ("turn:" + $turn_host + ":3478?transport=udp"),
                    ("turn:" + $turn_host + ":3478?transport=tcp")
                ],
                username: $username,
                credential: $credential
            }
        ]
    }' > "$rtc_config_tmp"

if [[ -w "$(dirname -- "$RTC_CONFIG_FILE")" ]]; then
    install -m 600 "$rtc_config_tmp" "$RTC_CONFIG_FILE"
elif command -v podman >/dev/null 2>&1; then
    # Enter the rootless Podman user namespace so the generated file is owned
    # by the same in-container UID/GID as the LinuxServer PairDrop process.
    podman unshare install -m 600 -o "$PUID" -g "$PGID" \
        "$rtc_config_tmp" "$RTC_CONFIG_FILE"
else
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] ERROR: Cannot write $RTC_CONFIG_FILE" >&2
    exit 1
fi

rm -f "$rtc_config_tmp"
trap - EXIT

echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] INFO: Coturn credentials and PairDrop RTC configuration are ready"
