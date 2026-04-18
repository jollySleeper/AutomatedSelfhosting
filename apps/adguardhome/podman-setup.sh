#!/bin/bash

source ../../scripts/common.sh

NAME="adguardhome"
IMAGE_SOURCE="docker.io/adguard/$NAME:latest"
action_based_on_query "$1-con" "$NAME" "$IMAGE_SOURCE"

echo "-> Making Required Directories"
mkdir -pv "$(get_vol_dir ${NAME})/work"

# Making Files Data for Rootless Container; Reqd by Both Folders
files=$(ls -A $(get_vol_dir ${NAME})/work)
if [[ $? == 0 ]] && [[ -z "$files" ]]; then
    source ./scripts/rootless-data.sh
fi

echo "-> Running '$NAME' Container"

# =============================================================================
# ROOTLESS NETWORKING OPTIONS
# =============================================================================
#
# OPTION 1: pasta (recommended for DNS servers, DEFAULT in Podman 5.x)
#   --network pasta  # Explicitly specified (though it's the default in Podman 5.x)
#   - Copies host IP addresses and routes into container namespace
#   - Forwards traffic at L4 (TCP/UDP/ICMP) - no NAT translation
#   - Real client IPs visible by default (essential for DNS query logs/stats)
#   - Appears to use host's IP directly, simplifies service exposure
#   - Requires active host network interface (may need config for offline/multi-NIC)
#
# OPTION 2: slirp4netns (LEGACY — no longer used anywhere in this repo)
#   --network slirp4netns:port_handler=slirp4netns
#   - Uses private subnet (10.0.2.0/24) with NAT to host
#   - Needed port_handler=slirp4netns flag to preserve real client IPs
#   - Works offline/air-gapped without active network interface
#   - Stronger isolation with clearly separate container subnet
#   - Retired from this stack in April 2026; kept here only as reference.
#     See docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md for the migration history.
#   - More predictable in unusual network configurations
#
# For AdGuard Home: pasta is preferred since real client IP visibility
# is crucial for per-device statistics, filtering rules, and query logs.
#
# NOTE: Since Podman 5.0.0, pasta is the DEFAULT rootless network mode.
#       We explicitly specify it for clarity and documentation purposes.
# =============================================================================

    #--cap-add NET_RAW \  # Only needed for DHCP server functionality
    #--userns keep-id     # Reqd for reading config; OR make files rootless (current approach)

# =============================================================================
# DNS SELF-LOOP BYPASS (see /docs/DNS_ARCHITECTURE.md)
# =============================================================================
# The system-wide /podman/containers.conf sets `dns_servers = ["192.168.1.105"]`
# for every container. Without an override, AGH itself would have 192.168.1.105
# in its /etc/resolv.conf — meaning it would try to resolve its own upstream
# hostnames (unfiltered.adguard-dns.com, Cloudflare DoH/DoT, update checks) via
# ITSELF. That creates a chicken-and-egg problem during startup.
#
# Two-part fix (same pattern as qbittorrent):
#
#   1) --dns 1.1.1.1 flag (captured into [Container] section by podlet).
#
#   2) Environment=CONTAINERS_CONF=/dev/null injected into [Service] section
#      of the generated quadlet. Needed because Podman 5.4.1 APPENDS --dns
#      values to containers.conf dns_servers instead of overriding them. Without
#      this env var, resolv.conf would end up with BOTH 192.168.1.105 and 1.1.1.1.
#
# Note: AGH primarily uses `bootstrap_dns` from AdGuardHome.yaml for resolving
# upstream DoH/DoT URLs, so /etc/resolv.conf only matters for system-level
# lookups (image update checks, CGO resolver paths, etc.). Still, clean
# resolv.conf avoids flaky startup behavior and is consistent with the qBT
# bypass pattern.
# =============================================================================
CONTAINERS_CONF=/dev/null podman run \
 --detach \
 --restart unless-stopped \
 --label io.containers.autoupdate=registry \
 --user $(id -u):$(id -g) \
 --network pasta \
 --dns 1.1.1.1 \
 -p 53:53/tcp       `# Plain DNS` \
 -p 53:53/udp       `# Plain DNS` \
 -p ${LOCALHOST_IP}:8000:8000/tcp     `# Dashboard` \
 -v "$(get_config_dir ${NAME})":/opt/adguardhome/conf \
 -v "$(get_vol_dir ${NAME})/work":/opt/adguardhome/work \
 --hostname "$NAME" \
 --name "$NAME" \
 "$IMAGE_SOURCE"

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "inject-quadlet-env" "$NAME" "Environment=CONTAINERS_CONF=/dev/null"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"

# Generate NGINX Conf File
action_based_on_query "generate-nginx-conf-file" "$NAME" "aevion" "lan" "8000" "http"

echo "Done :)"
