# Syncthing

Syncthing is a continuous file synchronization program that synchronizes files between two or more computers in real time.

## Overview

Syncthing replaces proprietary sync and cloud services with a free, open-source, and decentralized alternative. It synchronizes files between devices on a local network or over the internet using a peer-to-peer architecture, ensuring data privacy and security.

## Features

- **Decentralized Sync**: Peer-to-peer synchronization without central servers
- **Privacy First**: No data stored on external servers, full control over data
- **Real-time Sync**: Continuous, real-time file synchronization
- **Cross-Platform**: Works on Windows, macOS, Linux, Android, and more
- **Secure**: End-to-end encryption for data in transit
- **Selective Sync**: Choose which folders to sync on each device
- **Conflict Resolution**: Automatic conflict resolution with version control
- **Web Interface**: Modern web UI for management and monitoring

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8031 (web UI), ports 22000 (sync), 21027 (discovery)
- **Storage**: Variable based on files being synchronized

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/syncthing
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/syncthing
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user and user namespace mapping
- **UID/GID**: 1001:1001 with `keep-id` user namespace for file permission compatibility
- **Volume Permissions**: Uses user namespace mapping to maintain host file permissions
- **Security Notes**: Advanced rootless setup with user namespace isolation for secure file access

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/syncthing.conf` - Reverse proxy configuration for domain access

### Environment Variables

Syncthing uses default configuration with no environment variables in this setup.

## Configuration

### Container Details

- **Image**: `docker.io/syncthing/syncthing:latest`
- **Ports**:
  - Internal 8384 → External 8031 (web UI)
  - 22000 TCP/UDP (sync protocol)
  - 21027 UDP (local discovery)
- **Volumes**:
  - `volumes/config:/var/syncthing/config` - Syncthing configuration
  - `~/selfhost:/home/selfhost` - Selfhost directory sync
  - `~/media/Docs/Logseq:/home/docs/Logseq` - Logseq notes sync
  - `~/media/Songs:/home/songs` - Music library sync
- **Networks**: plain pasta with direct port publishing for sync (peer-to-peer — no host services needed)

### Service Configuration

Syncthing is configured for personal file synchronization:
- **Web UI**: Accessible via reverse proxy on port 8031
- **Sync Ports**: Direct port exposure for peer-to-peer sync
- **User Namespace**: `keep-id` mapping for seamless file permission handling
- **Multiple Folders**: Pre-configured sync folders for different data types

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8031
- **Domain Access**: https://sync.aevion.lan or https://syncthing.aevion.lan
- **API Endpoints**: REST API available for automation

### Getting Started

1. **Initial Setup**
   - Access the web interface
   - Set an admin password
   - Review the device ID for adding peers

2. **Add Remote Devices**
   - Get device ID from another Syncthing instance
   - Add device in web interface
   - Accept connection on both devices

3. **Configure Folders**
   - Pre-configured folders are available
   - Share folders with remote devices
   - Set sync preferences (send-only, receive-only, etc.)

### Command Line Operations

```bash
# Service management
systemctl --user status syncthing
systemctl --user restart syncthing

# Container operations
podman logs syncthing
podman exec -it syncthing /bin/sh

# Check sync status
podman exec syncthing syncthing --version
```

## Integration

### With Other Services

- **File Storage**: Direct access to selfhost configuration and media files
- **NGINX Proxy**: Reverse proxy for secure web interface access
- **Backup Strategy**: Part of broader data synchronization strategy

### API Integration

Syncthing provides a REST API for:
- **Device Management**: Adding/removing devices programmatically
- **Folder Management**: Creating and configuring sync folders
- **Monitoring**: Checking sync status and statistics
- **Configuration**: Automated configuration management

## Backup & Recovery

### Important Data to Backup

- **Configuration**: `volumes/config/` - Device settings, folder configurations, certificates
- **Version Vectors**: Sync state information for conflict resolution
- **File Data**: The actual synchronized files in mounted directories

### Backup Commands

```bash
# Backup configuration
tar -czf syncthing-config-$(date +%Y%m%d).tar.gz volumes/config

# Backup with sync state
podman exec syncthing syncthing --pause-all
tar -czf syncthing-full-backup-$(date +%Y%m%d).tar.gz volumes/config ~/selfhost ~/media/Docs/Logseq ~/media/Songs
podman exec syncthing syncthing --resume-all
```

### Restore Commands

```bash
# Restore configuration
tar -xzf syncthing-config-YYYYMMDD.tar.gz

# Restart service
systemctl --user restart syncthing
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active syncthing

# Container status
podman ps | grep syncthing

# Web interface check
curl -I http://localhost:8031
```

### Logs

```bash
# View recent logs
podman logs --tail 50 syncthing

# Follow logs
podman logs -f syncthing
```

### Common Issues

**Connection Issues**
- Symptoms: Devices can't connect for synchronization
- Cause: Firewall blocking sync ports or network configuration
- Solution: Check firewall rules and port accessibility

**Permission Issues (Rootless)**
- Symptoms: Cannot access or sync certain files
- Cause: User namespace mapping conflicts with file permissions
- Solution: Verify user namespace configuration and file ownership

**Sync Conflicts**
- Symptoms: Duplicate files with conflict names
- Cause: Simultaneous file modifications on multiple devices
- Solution: Review and resolve conflicts in web interface

### Performance Tuning

- **Network Bandwidth**: Monitor and limit sync bandwidth if needed
- **File Monitoring**: Adjust file system monitoring sensitivity
- **Compression**: Enable compression for slower network connections
- **Folder Types**: Use send-only folders for backup scenarios

## Security

- **Container Security**: Rootless with user namespace isolation
- **Network Security**: Direct port exposure for sync (firewall recommended)
- **Data Protection**: End-to-end encryption for data in transit
- **Access Control**: Web interface authentication required

## System Resources

- **Memory**: 100-500MB depending on number of files and connections
- **CPU**: Variable based on sync activity and file scanning
- **Storage**: Minimal overhead beyond synchronized files
- **Network**: Variable based on sync volume and compression settings

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/syncthing/syncthing:latest
systemctl --user restart syncthing
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check disk usage of config
du -sh volumes/config
```

## Notes

- **User Namespace**: Uses advanced `keep-id` mapping for seamless file permission handling
- **Port Exposure**: Direct port publishing required for peer-to-peer sync functionality
- **Multiple Folders**: Pre-configured for different data types (config, docs, music)
- **Decentralized**: No central server dependency, fully peer-to-peer architecture

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
