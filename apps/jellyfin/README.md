# Jellyfin

Jellyfin is a free software media system that puts you in control of managing and streaming your media.

## Overview

Jellyfin is a media server software that allows you to collect, manage, and stream your personal media collection. It features hardware acceleration support, multiple client applications, and extensive customization options for organizing and streaming movies, TV shows, music, and photos.

## Features

- **Media Management**: Organize and stream movies, TV shows, music, and photos
- **Hardware Acceleration**: GPU-accelerated video transcoding and encoding
- **Multi-Platform Clients**: Apps for all major platforms (web, mobile, TV, etc.)
- **Live TV & DVR**: Support for HDHomeRun and other TV tuners
- **User Management**: Multiple user accounts with individual permissions
- **Plugins**: Extensible with plugins for additional functionality
- **DLNA Support**: Compatible with DLNA-certified devices
- **API Access**: RESTful API for third-party integrations

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern CPU with hardware acceleration support
- **Dependencies**: Hardware acceleration devices (GPU/DMA), media storage
- **Network**: HTTP port 8041 (web UI), various ports for streaming
- **Storage**: Variable based on media library size + ~1GB for cache/config

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/jellyfin
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/jellyfin
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Hardware Acceleration Configuration

The following configurations are required for successful hardware acceleration on Rockchip devices (and generally for GPU access in rootless Podman). Ensure your host user has sufficient Linux groups (audio, video, render).

#### Root Mode (Current Setup)
- **Privileged Flag**: `privileged` must be kept enabled. Without it, the GPU will not be passed to the container, and playback/transcoding will fail.
- **Annotation**: `--annotation run.oci.keep_original_groups=1` is required.
  - *Note*: This works with the `crun` runtime (Podman default).
  - This annotation is necessary for sharing GPU access, even in privileged mode.
- **Result**: Enables full GPU decoding and encoding.

#### User Mode (Alternative)
If running as a specific user, the following flags are compulsory:
- **Keep Original Groups**: `--annotation run.oci.keep_original_groups=1`
- **User Namespace**: `--userns keep-id`
- **User ID**: `--user <uid>:<gid>` (or just pass the user/group args)
- **Group Add**: `--group-add keep-groups` (Crucial: shares host Audio, Video, & Render groups with the container).
  - *Warning*: Only using `--user` will lead to permission errors.
  - *Warning*: Only using `--user` + `--annotation` without `keep-groups` results in no GPU access.
- **Result**: Enables GPU decoding with proper user permission isolation.

### Rootless Container Configuration

- **User Mode**: Privileged root container for hardware acceleration
- **UID/GID**: Root user (0:0) required for GPU device access
- **Volume Permissions**: Custom entrypoint handles permission setup
- **Security Notes**: Privileged mode required for hardware acceleration device access

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/jellyfin.conf` - Reverse proxy configuration for domain access

### Environment Variables

Jellyfin uses default configuration with no environment variables in this setup.

## Configuration

### Container Details

- **Image**: `ghcr.io/jellyfin/jellyfin:10.11`
- **Ports**: Internal 8096 → External 8041 (localhost)
- **Volumes**:
  - `volumes/config:/config` - Application configuration and database
  - `volumes/cache:/cache` - Transcoding cache and temporary files
  - `~/media:/media` - Media library directory
- **Devices**: Hardware acceleration devices (/dev/dri, /dev/dma_heap, etc.)
- **Networks**: plain pasta (media server — serves content, no host services needed)

### Service Configuration

Jellyfin is configured with hardware acceleration for optimal performance:
- **Hardware Acceleration**: Full GPU access for video transcoding
- **Privileged Mode**: Required for device access and performance
- **Custom Entrypoint**: Includes yt-dlp for YouTube metadata plugin
- **User Groups**: Maintains original user groups for device access

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8041
- **Domain Access**: https://jf.aevion.lan or https://jellyfin.aevion.lan
- **API Endpoints**: RESTful API available for client applications

### Getting Started

1. **Initial Setup**
   - Access the web interface
   - Create an admin account
   - Configure media libraries

2. **Add Media Libraries**
   - Point to mounted media directories
   - Configure library types (movies, TV shows, music)
   - Set up metadata fetching

3. **Client Applications**
   - Use official Jellyfin apps for various platforms
   - Web interface works on all modern browsers
   - Configure user accounts and permissions

### Command Line Operations

```bash
# Service management
systemctl --user status jellyfin
systemctl --user restart jellyfin

# Container operations
podman logs jellyfin
podman exec -it jellyfin /bin/bash

# Check hardware acceleration
podman exec jellyfin vainfo
```

## Integration

### With Other Services

- **Media Storage**: Direct access to media files in ~/media
- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Hardware Acceleration**: GPU integration for video processing

### API Integration

Jellyfin provides extensive APIs for:
- **Media Management**: Library scanning and organization
- **User Management**: Account and permission management
- **Playback Control**: Remote control and status monitoring
- **Plugin System**: Third-party plugin integration

## Backup & Recovery

### Important Data to Backup

- **Configuration**: `volumes/config/` - User accounts, library settings, metadata
- **Cache**: `volumes/cache/` - Transcoding cache (can be regenerated)
- **Media Files**: External media directory (backed up separately)

### Backup Commands

```bash
# Backup configuration
tar -czf jellyfin-config-$(date +%Y%m%d).tar.gz volumes/config

# Full backup including cache
tar -czf jellyfin-full-backup-$(date +%Y%m%d).tar.gz volumes/config volumes/cache
```

### Restore Commands

```bash
# Restore configuration
tar -xzf jellyfin-config-YYYYMMDD.tar.gz

# Restart service
systemctl --user restart jellyfin
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active jellyfin

# Container status
podman ps | grep jellyfin

# Web interface check
curl -I http://localhost:8041
```

### Logs

```bash
# View recent logs
podman logs --tail 50 jellyfin

# Follow logs
podman logs -f jellyfin
```

### Common Issues

**Hardware Acceleration Issues**
- Symptoms: High CPU usage during transcoding, poor performance
- Cause: GPU devices not properly accessible or drivers missing
- Solution: Verify device passthrough and GPU driver installation

**Permission Issues**
- Symptoms: Cannot access media files or GPU devices
- Cause: Privileged mode not working correctly or permission setup failed
- Solution: Check container logs and device access

**Transcoding Failures**
- Symptoms: Videos not playing or buffering issues
- Cause: Hardware acceleration not working or codec support missing
- Solution: Check GPU status and fallback to software transcoding

**Playback Freezes During Direct Stream / HLS (Wi-Fi clients)**
- Symptoms: Both audio and video freeze for 30-60 seconds, then resume automatically. Happens several times per hour. No buffering spinner appears.
- Cause: NGINX `proxy_buffering off` causes TCP backpressure when the Wi-Fi client is slower than the localhost upstream. Data backs up in TCP queues and the pipeline stalls.
- Diagnosis: `ss -tn state established | grep ":8041"` during a freeze will show megabytes stuck in Recv-Q/Send-Q on the NGINX↔Jellyfin backend connection, while client connections show 0 bytes (no data flowing).
- Solution: Enable NGINX proxy buffering with tmpfs-backed temp files. See the NGINX Proxy Configuration section below.
- Evidence: Bypassing NGINX (direct connection to Jellyfin on port 8041) eliminates the freezes completely, confirming NGINX is the bottleneck.

### NGINX Proxy Configuration

Config history in `apps/nginx/configs/sites/`:

| Config | Buffering | Status | Notes |
|--------|-----------|--------|-------|
| `jellyfin.conf.v1-buffering-off` | OFF | **Deprecated** | Official Jellyfin recommendation. Causes playback freezes on Wi-Fi. |
| `jellyfin.conf.v2-buffering-on` | ON (RAM only, 512KB) | **Deprecated** | Fixed HLS but broke Direct Play: 512KB too small for 800MB MKV files. |
| `jellyfin.conf` (v4) | ON (256MB temp-file on tmpfs) | **Active** | Fixes all playback modes. Temp files go to RAM via tmpfs mount. Also fixes header inheritance and WebSocket timeout bugs from earlier versions. |

**Why we diverge from official Jellyfin docs:**

The [official NGINX config](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/nginx/) uses `proxy_buffering off` with the comment "Disable buffering when the nginx proxy gets very resource heavy upon streaming." This works when the client and server are on the same fast network. However, in our setup:

- **Upstream** (Jellyfin → NGINX) runs over localhost — effectively unlimited speed
- **Downstream** (NGINX → browser) runs over Wi-Fi — variable, sometimes slow

With `proxy_buffering off`, NGINX passes data through in tiny chunks. When Wi-Fi slows down, TCP backpressure propagates from browser → NGINX → Jellyfin → FFmpeg, stalling the entire pipeline.

**SSD wear concern:** NGINX's `proxy_temp_path` is `/tmp/proxy_temp`. Inside Podman containers, `/tmp` defaults to the overlay filesystem backed by the NVMe SSD. The NGINX container mounts `/tmp` as tmpfs (1GB RAM disk) so proxy buffer temp files go to RAM, not SSD. See `apps/nginx/README.md` for the full buffering strategy.

### Performance Tuning

- **Hardware Acceleration**: Ensure GPU drivers are properly installed
- **Transcoding**: Configure quality vs speed trade-offs
- **Library Scanning**: Schedule scans during low-usage periods
- **Cache Management**: Monitor and clean transcoding cache periodically

## Security

- **Container Security**: Privileged root container (required for hardware access)
- **Network Security**: Reverse proxy protection, no direct external access
- **User Authentication**: Built-in user management with permissions
- **Media Access**: File-level access controls through Jellyfin

## System Resources

- **Memory**: 1-4GB depending on transcoding activity and library size
- **CPU**: Variable - low when idle, high during transcoding
- **Storage**: ~1GB for config/cache + media library size
- **Network**: Variable based on streaming bitrate and concurrent users

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/jellyfin/jellyfin:10.11
systemctl --user restart jellyfin
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear transcoding cache if needed
rm -rf volumes/cache/transcoding-temp/*
systemctl --user restart jellyfin
```

## Notes

- **Hardware Acceleration**: Complex privileged setup required for GPU access
- **Custom Entrypoint**: Includes yt-dlp for enhanced YouTube metadata support
- **Privileged Mode**: Required for device access but reduces container security
- **Resource Intensive**: Higher resource requirements due to media processing

---

*Last updated: March 23, 2026*
*Deployed on: legion (aevion.lan)*
