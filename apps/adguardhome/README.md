# AdGuard Home

AdGuard Home is a network-wide software for blocking ads and tracking. It operates as a DNS server that re-routes tracking domains to a "black hole", thus preventing your devices from connecting to those servers.

> **DNS architecture context**
>
> AGH is the central DNS authority for the LAN and tailnet. All server-hosted containers point at AGH via `192.168.1.105:53` (configured globally through `/podman/containers.conf`), except:
>
> - `qbittorrent` — fully bypasses AGH (resolv.conf has ONLY `1.1.1.1` + `9.9.9.9`) because AGH's StevenBlack Extra / SafeBrowsing blocks legitimate torrent trackers.
> - `adguardhome` itself — resolv.conf has ONLY `1.1.1.1` to avoid a self-referential loop and to bootstrap upstream lookups cleanly.
>
> Both bypasses require the two-part `CONTAINERS_CONF=/dev/null` pattern (working around a Podman 5.4.1 quirk where `--dns` appends instead of overrides). See [`/docs/DNS_ARCHITECTURE.md`](../../docs/DNS_ARCHITECTURE.md) §3.2–3.4 and [`.cursor/rules/podman-dns-bypass.mdc`](../../.cursor/rules/podman-dns-bypass.mdc) for the mechanism and rationale.
>
> IPv6 is returned empty (`aaaa_disabled: true`) to match the IPv4-only LAN policy.
>
> **Verify after deploy:** `podman exec adguardhome cat /etc/resolv.conf` should show exactly `nameserver 1.1.1.1` (and nothing else).
>
> Related files: `adguardhome.container` (auto-generated live quadlet), `adguardhome.container-manual` (hand-written reference for diffing / emergency bootstrap).

## Overview

AdGuard Home serves as a DNS-based ad and tracker blocker that protects all devices on your network from unwanted ads, trackers, and malicious domains. It goes beyond browser-based ad blockers by blocking ads and trackers at the network level, providing comprehensive protection for all devices including smart TVs, gaming consoles, and IoT devices.

## Features

- **Network-wide Protection**: Blocks ads and trackers for all devices on your network
- **Custom Filtering Rules**: Advanced filtering with custom blocklists and rules
- **DNS-over-HTTPS/TLS**: Encrypted DNS queries for privacy
- **Parental Controls**: Block adult content and restrict access to specific sites
- **Client Management**: Monitor and control individual devices on your network
- **Safe Browsing**: Protection against phishing and malware domains
- **Query Logging**: Detailed logs of DNS queries for analysis
- **Statistics Dashboard**: Comprehensive statistics and analytics
- **API Access**: RESTful API for automation and integration
- **Multiple Protocols**: Support for DNS, DHCP, DoH, DoT, DNSCrypt

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: DNS ports 53 (TCP/UDP), HTTP port 8000 (web UI)
- **Storage**: ~100MB for database and logs

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/adguardhome
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/adguardhome
   ```

2. **Configure AdGuard Home**
   ```bash
   # Configuration file: configs/AdGuardHome.yaml
   # Contains DNS settings, filtering rules, and client configurations
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: User namespace mapping for configuration access
- **Security Notes**: DNS server access requires careful network configuration

### Rootless Networking (Podman 5.x)

AdGuard Home uses **pasta** networking mode, which is the default in Podman 5.x. As of April 2026 the entire SelfHost stack is pasta-only (slirp4netns has been fully phased out — see [`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](../../docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md) for the history).

#### Why pasta for DNS?

Historically we compared pasta against slirp4netns for this container. Pasta wins on every axis that matters for a DNS server:

| Feature | pasta | slirp4netns (no longer used) |
|---------|-------|------------------------------|
| **Client IP Visibility** | ✅ Native (no config needed) | ⚠️ Required `port_handler=slirp4netns` flag |
| **NAT** | No NAT, uses host IPs directly | NAT via private 10.0.2.0/24 subnet |
| **Performance** | Generally faster (no NAT overhead) | Slower, extra NAT hop |
| **Podman 5.x Default** | ✅ Yes (since 5.0.0) | ❌ Legacy |

For a DNS server like AdGuard Home, seeing **real client IPs** is essential for:
- Per-device query statistics and logs
- Client-specific filtering rules
- Accurate network monitoring

#### Network Configuration

```bash
--network pasta

# Check default: podman info -f '{{.Host.RootlessNetworkCmd}}'
```

AdGuard Home also carries the `CONTAINERS_CONF=/dev/null` + `--dns 1.1.1.1` bypass so it doesn't point back at itself via pasta's default DNS-forward (`169.254.1.1`). See [`docs/DNS_ARCHITECTURE.md`](../../docs/DNS_ARCHITECTURE.md) §2.5 for the full story.

### Configuration Files Modified

- **AdGuard Home Config**: `apps/adguardhome/configs/AdGuardHome.yaml` - Main configuration file

### Environment Variables

AdGuard Home uses configuration file instead of environment variables.

## Configuration

### Container Details

- **Image**: `docker.io/adguard/adguardhome:latest`
- **Ports**:
  - 53:53 TCP/UDP (DNS queries)
  - 8000:8000 (Web interface)
- **Volumes**:
  - `configs/AdGuardHome.yaml:/opt/adguardhome/conf/AdGuardHome.yaml` - Configuration file
  - `volumes/work:/opt/adguardhome/work` - Working directory and database
- **Networks**: Host networking for DNS server access

### Service Configuration

AdGuard Home is extensively configured for network-wide ad blocking:
- **DNS Server**: Quad9 upstream with fallback DNS
- **Filtering**: Multiple blocklists for comprehensive ad blocking
- **Client Management**: Detailed client configurations for network devices
- **Safe Browsing**: Protection against malicious domains
- **Query Logging**: DNS query logging and statistics
- **Custom Rules**: Network-specific DNS rewrites and rules

### Architecture

AdGuard Home acts as the central DNS server for your network:

```
┌─────────────────┐
│   Network       │
│   Devices       │
│                 │
│ • Phones        │
│ • Laptops       │
│ • TVs           │
│ • IoT Devices   │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Router/       │    │   AdGuard Home   │
│   DHCP Server   │◄──►│   DNS Server      │
│   (DNS: local)  │    │   (Port 53)       │
└─────────────────┘    └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   Upstream DNS   │
         │              │   (Quad9, etc.)  │
         │              │                  │
         │              └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   AdGuard Home  │    │   Blocklists      │
│   Web Interface │    │   & Filtering     │
│   (Port 8000)   │    │   Rules            │
└─────────────────┘    └──────────────────┘
```

#### Key Components
- **DNS Server**: Core DNS resolver with filtering capabilities
- **Web Interface**: Management dashboard for configuration
- **Blocklists**: Multiple curated blocklists for ad/tracker domains
- **Client Management**: Device-specific filtering and monitoring
- **Query Logs**: DNS query analysis and statistics

#### DNS Resolution Flow
1. Client sends DNS query to AdGuard Home
2. Query is checked against blocklists
3. Blocked domains return null/0.0.0.0 response
4. Allowed queries forwarded to upstream DNS
5. Response cached and returned to client

## Usage

### Accessing the Service

- **Web Interface**: http://localhost:8000 (management dashboard)
- **DNS Server**: Automatic (configured via DHCP/router settings)

### Getting Started

1. **Initial Setup**
   - Access the web interface at http://localhost:8000
   - Create admin account and configure basic settings
   - Set up upstream DNS servers

2. **Configure Filtering**
   - Enable desired blocklists for ad/tracker blocking
   - Configure safe browsing and parental controls
   - Set up client-specific filtering rules

3. **Client Management**
   - Add network devices for monitoring
   - Configure per-client filtering settings
   - Set up blocked services and safe search

### Command Line Operations

```bash
# Service management
podman ps | grep adguardhome
podman logs adguardhome

# Container operations
podman exec -it adguardhome /bin/bash

# Check DNS resolution
nslookup google.com 127.0.0.1
dig @127.0.0.1 google.com
```

## Integration

### With Other Services

- **DHCP Server**: Router DHCP configuration to use AdGuard as DNS
- **Tailscale**: DNS rewrites for Tailscale network access
- **Network Devices**: All network clients automatically protected
- **Monitoring Stack**: Query logs available for analysis

### API Integration

AdGuard Home provides comprehensive APIs for:
- **Filtering Control**: Enable/disable filtering and blocklists
- **Client Management**: Add/manage network clients programmatically
- **Statistics Access**: Retrieve query statistics and logs
- **Configuration**: Automated configuration management

## Backup & Recovery

### Important Data to Backup

- **Configuration**: `configs/AdGuardHome.yaml` - All settings and rules
- **Database**: `volumes/work/` - Query logs, statistics, and client data

### Backup Commands

```bash
# Backup configuration
cp configs/AdGuardHome.yaml AdGuardHome-backup.yaml

# Backup working directory
tar -czf adguardhome-work-$(date +%Y%m%d).tar.gz volumes/work

# Full backup
tar -czf adguardhome-full-backup-$(date +%Y%m%d).tar.gz configs/ volumes/
```

### Restore Commands

```bash
# Restore configuration
cp AdGuardHome-backup.yaml configs/AdGuardHome.yaml

# Restore working directory
tar -xzf adguardhome-work-YYYYMMDD.tar.gz

# Restart service
podman restart adguardhome
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep adguardhome

# Web interface check
curl -I http://localhost:8000

# DNS health check
nslookup google.com 127.0.0.1

# API health check
curl http://localhost:8000/control/status
```

### Logs

```bash
# Container logs
podman logs adguardhome

# Query logs (via web interface)
# Access /#logs in web interface

# Statistics (via web interface)
# Access /#stats in web interface
```

### Common Issues

**DNS Not Working**
- Symptoms: Devices can't resolve domain names
- Cause: DHCP not configured to use AdGuard as DNS server
- Solution: Update router DHCP settings to use local DNS server

**Ads Not Blocked**
- Symptoms: Ads still appearing on devices
- Cause: Client DNS settings override router settings
- Solution: Configure client DNS manually or check DHCP configuration

**Web Interface Inaccessible**
- Symptoms: Cannot access management interface
- Cause: Port conflicts or network configuration issues
- Solution: Check port availability and network access

**Blocklists Not Updating**
- Symptoms: Blocklists not updating automatically
- Cause: Network connectivity or update interval issues
- Solution: Check network access and manual blocklist updates

### Performance Tuning

- **DNS Cache**: Adjust cache settings for performance vs memory usage
- **Blocklist Optimization**: Balance blocking effectiveness with query speed
- **Client Limits**: Configure rate limiting for high-traffic scenarios
- **Query Logging**: Enable/disable logging based on storage and privacy needs

## Security

- **Network Security**: DNS-based filtering protects all network devices
- **Safe Browsing**: Protection against malicious and phishing domains
- **Access Control**: Web interface authentication required
- **Query Privacy**: Local DNS resolution prevents ISP monitoring

## System Resources

- **Memory**: 256-512MB depending on query volume and caching
- **CPU**: Low baseline, spikes during blocklist updates
- **Storage**: ~100MB base + variable for query logs and statistics
- **Network**: Minimal (DNS query overhead only)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/adguard/adguardhome:latest
podman restart adguardhome
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear query logs (if needed)
# Use web interface or API to manage log retention
```

## Notes

- **Network-wide Protection**: Protects all devices without individual configuration
- **Blocklist Management**: Extensive curated blocklists for comprehensive filtering
- **Client-specific Rules**: Granular control over filtering per device
- **Privacy Focus**: Local DNS resolution prevents third-party tracking

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
