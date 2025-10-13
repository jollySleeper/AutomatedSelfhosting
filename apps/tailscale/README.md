# Tailscale

Tailscale is a zero-config VPN that creates a secure network between your servers, computers, and cloud instances using WireGuard.

## Overview

Tailscale provides secure, private networking between devices using the open-source WireGuard protocol. It creates a mesh VPN that allows devices to communicate as if they were on the same local network, regardless of their physical location. This setup integrates with AdGuard Home for DNS and provides secure remote access to the self-hosted services.

## Features

- **Zero-Config VPN**: Automatic network configuration without complex setup
- **WireGuard Protocol**: Fast, modern VPN technology
- **Device Management**: Web-based admin console for managing devices
- **NAT Traversal**: Works through firewalls and NAT without port forwarding
- **End-to-End Encryption**: All traffic encrypted with WireGuard's cryptography
- **Access Controls**: Granular permissions for device-to-device communication
- **DNS Integration**: Built-in DNS with magic DNS feature
- **Subnet Routing**: Route traffic to entire subnets

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, Linux kernel with WireGuard support
- **Dependencies**: TUN device access, network administrative capabilities
- **Network**: Internet connection for coordination server communication
- **Storage**: ~50MB for configuration and state

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/tailscale
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/tailscale
   ```

2. **Configure Environment**
   ```bash
   # Environment file: environments/local.env
   # TS_AUTHKEY should be configured with your Tailscale auth key
   # TS_HOSTNAME=aevion
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Privileged root container for network device access
- **UID/GID**: Root user (0:0) required for TUN device and network configuration
- **Volume Permissions**: Root access to network devices and configuration
- **Security Notes**: Privileged capabilities required for VPN functionality (NET_ADMIN, SYS_MODULE)

### Configuration Files Modified

No NGINX configuration - Tailscale provides direct network access.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| TS_AUTHKEY | Tailscale authentication key | - | Yes |
| TS_STATE_DIR | State directory path | /var/lib/tailscale | No |
| TS_HOSTNAME | Device hostname | (container hostname) | No |
| TS_USERSPACE | Userspace networking mode | 1 | No |
| TS_ACCEPT_DNS | Accept DNS from admin console | false | No |

## Configuration

### Container Details

- **Image**: `docker.io/tailscale/tailscale:latest`
- **Ports**:
  - 3000 (Tailscale coordination)
  - 8001 → 8000 (internal web interface)
- **Volumes**:
  - `volumes/lib:/var/lib` - Tailscale state and configuration
  - `volumes/lib/tailscale:/var/lib/tailscale` - Tailscale-specific data
  - `configs/resolv.conf:/etc/resolv.conf:ro` - DNS configuration
  - AdGuard Home volumes for DNS integration
- **Devices**: `/dev/net/tun:/dev/net/tun` - TUN device for VPN
- **Capabilities**: NET_ADMIN, SYS_MODULE for network configuration

### Service Configuration

Tailscale is configured for secure remote access:
- **Userspace Networking**: Uses userspace WireGuard implementation
- **AdGuard Integration**: Shares AdGuard Home configuration for DNS
- **Custom Entrypoint**: Includes containerboot for proper initialization
- **State Persistence**: Maintains VPN state across container restarts

## Usage

### Accessing the Service

- **Tailscale Network**: All devices accessible via Tailscale-assigned IPs
- **Web Interface**: https://login.tailscale.com for device management
- **Admin Console**: https://controlplane.tailscale.com for network management

### Getting Started

1. **Authentication**
   - Container starts with pre-configured auth key
   - Device appears in Tailscale admin console
   - Approve device access if required

2. **Network Access**
   - Remote devices can access local services via Tailscale IPs
   - Example: `http://aevion:8041` for Jellyfin access
   - All self-hosted services accessible remotely

3. **Device Management**
   - Manage device access through Tailscale web interface
   - Configure subnet routes if needed
   - Set up access controls and permissions

### Command Line Operations

```bash
# Service management
podman ps | grep tailscale
podman logs tailscale

# Check Tailscale status (inside container)
podman exec tailscale tailscale status

# Check IP addresses
podman exec tailscale tailscale ip -4
podman exec tailscale tailscale ip -6
```

## Integration

### With Other Services

- **AdGuard Home**: DNS integration for network-wide ad blocking
- **All Self-Hosted Apps**: Provides secure remote access to entire stack
- **Network Infrastructure**: Creates secure overlay network

### API Integration

Tailscale provides:
- **Device API**: Programmatic device management
- **Network API**: Network configuration and monitoring
- **Admin API**: Administrative operations

## Backup & Recovery

### Important Data to Backup

- **State Directory**: `volumes/lib/tailscale/` - VPN state and keys
- **Configuration**: Authentication and network settings

### Backup Commands

```bash
# Backup Tailscale state
tar -czf tailscale-state-$(date +%Y%m%d).tar.gz volumes/lib/tailscale

# Full configuration backup
tar -czf tailscale-config-$(date +%Y%m%d).tar.gz volumes/lib
```

### Restore Commands

```bash
# Restore state (container must be stopped)
tar -xzf tailscale-state-YYYYMMDD.tar.gz

# Restart service
podman restart tailscale
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep tailscale

# Tailscale status
podman exec tailscale tailscale status

# Network connectivity
podman exec tailscale ping -c 3 100.64.0.1  # Tailscale coordination server
```

### Logs

```bash
# View recent logs
podman logs --tail 50 tailscale

# Follow logs
podman logs -f tailscale
```

### Common Issues

**Authentication Failures**
- Symptoms: Device not appearing in admin console
- Cause: Invalid or expired auth key
- Solution: Generate new auth key and update configuration

**Network Connectivity Issues**
- Symptoms: Cannot reach devices on Tailscale network
- Cause: Firewall blocking or network configuration issues
- Solution: Check firewall rules and Tailscale status

**DNS Resolution Problems**
- Symptoms: Cannot resolve .ts.net domains
- Cause: DNS configuration issues
- Solution: Check AdGuard Home integration and DNS settings

### Performance Tuning

- **MTU Settings**: Tailscale handles MTU automatically
- **Connection Monitoring**: Use Tailscale admin console for network monitoring
- **Subnet Routing**: Configure only necessary routes to minimize overhead

## Security

- **Container Security**: Privileged root container (required for VPN)
- **Network Security**: WireGuard encryption for all traffic
- **Access Control**: Device-level access controls through admin console
- **Zero Trust**: No default access - explicit approval required

## System Resources

- **Memory**: 50-200MB depending on network activity
- **CPU**: Low baseline, spikes during connection establishment
- **Storage**: ~50MB for state and configuration
- **Network**: Minimal overhead beyond encrypted payload

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/tailscale/tailscale:latest
podman restart tailscale
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check state directory size
du -sh volumes/lib/tailscale
```

## Notes

- **Privileged Access**: Requires root privileges for network device access
- **AdGuard Integration**: Shares DNS configuration with AdGuard Home
- **Userspace Mode**: Uses userspace networking for container compatibility
- **Remote Access**: Primary method for secure remote access to all services

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
