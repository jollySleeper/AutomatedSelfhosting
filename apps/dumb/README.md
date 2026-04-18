# Dumb

Dumb is a simple, self-hosted pastebin service that allows sharing text snippets securely.

## Overview

Dumb is a minimalistic pastebin application that provides a clean interface for sharing text content. It offers secure, temporary text sharing with syntax highlighting and supports both public and private pastes.

## Features

- **Simple Interface**: Clean, minimalistic pastebin interface
- **Syntax Highlighting**: Support for various programming languages
- **Secure Sharing**: Private paste options with unique URLs
- **No Registration**: Anonymous paste creation
- **Expiration Options**: Configurable paste expiration times
- **Mobile Friendly**: Responsive design for all devices
- **HTTPS Only**: Forces HTTPS for secure access

## Prerequisites

- **System Requirements**: Minimum 128MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8016 (web UI), HTTPS forced
- **Storage**: Minimal (in-memory by default, optional persistence)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/dumb
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/dumb
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: Standard container security with network isolation

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/dumb.conf` - Reverse proxy with HTTPS enforcement

### Environment Variables

None - Dumb uses default configuration.

## Configuration

### Container Details

- **Image**: `ghcr.io/rramiachraf/dumb:latest`
- **Ports**: Internal 5555 → External 8016 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Dumb runs with minimal configuration:
- **Port**: 5555 (internal container port)
- **HTTPS Enforcement**: NGINX redirects all HTTP to HTTPS
- **Self-Signed SSL**: Uses self-signed certificates for HTTPS
- **No Persistence**: Pastes are stored in memory only

### Architecture

Dumb provides a simple pastebin service:

```
┌─────────────────┐
│   User Browser  │
│                 │
│ dumb.aevion.lan │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   NGINX Proxy   │    │   Dumb Service   │
│   (Port 1080)   │    │   (Port 8016)    │
│   HTTPS Force   │◄──►│   Pastebin       │
└─────────────────┘    └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   In-Memory      │
                       │   Storage        │
                       │   (No Persistence)│
                       └──────────────────┘
```

## Usage

### Accessing the Service

- **Domain Access**: https://dumb.aevion.lan (HTTPS only)
- **HTTP Redirect**: HTTP requests automatically redirect to HTTPS

### Getting Started

1. **Create Pastes**
   - Access the web interface at https://dumb.aevion.lan
   - Enter text content in the text area
   - Select syntax highlighting language (optional)
   - Set expiration time (optional)
   - Create paste

2. **Share Pastes**
   - Copy the generated URL to share with others
   - Pastes can be public or private
   - URLs are unique and hard to guess

3. **View Pastes**
   - Access paste URLs directly
   - Syntax highlighting applied automatically
   - Pastes expire based on settings

### Command Line Operations

```bash
# Service management
systemctl --user status dumb
systemctl --user restart dumb

# Container operations
podman logs dumb
podman exec -it dumb /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy with SSL termination
- **Privacy Suite**: Part of the self-hosted service collection

### API Integration

Dumb is a web interface only - no API for external integration.

## Backup & Recovery

### Important Data to Backup

No persistent data - Dumb is stateless and pastes are stored in memory only.

### Backup Commands

```bash
# No persistent data to backup
```

### Restore Commands

```bash
# Restart service (no data to restore)
systemctl --user restart dumb
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active dumb

# Container status
podman ps | grep dumb

# Web interface check
curl -I https://dumb.aevion.lan
```

### Logs

```bash
# View recent logs
podman logs --tail 50 dumb

# Follow logs
podman logs -f dumb
```

### Common Issues

**HTTPS Redirect Issues**
- Symptoms: HTTP requests not redirecting to HTTPS
- Cause: NGINX configuration issues
- Solution: Check nginx configuration and reload

**Container Access Issues**
- Symptoms: Cannot access web interface
- Cause: Container not running or port conflicts
- Solution: Check container status and port availability

**SSL Certificate Issues**
- Symptoms: Browser SSL warnings
- Cause: Self-signed certificate not trusted
- Solution: Accept self-signed certificate or configure proper SSL

### Performance Tuning

- **Memory**: Minimal resource requirements
- **Storage**: No persistent storage needed
- **Network**: Basic HTTP/HTTPS traffic

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: HTTPS enforcement with SSL/TLS
- **Data Protection**: No persistent data storage
- **Access Control**: No authentication required

## System Resources

- **Memory**: ~50-100MB typical usage
- **CPU**: Minimal CPU usage
- **Storage**: Minimal (no persistent storage)
- **Network**: Low network usage

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/rramiachraf/dumb:latest
systemctl --user restart dumb
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats dumb
```

## Notes

- **In-Memory Storage**: Pastes are not persisted and lost on restart
- **HTTPS Only**: All access forced through HTTPS
- **Self-Signed SSL**: Uses self-signed certificates
- **Simple Service**: Minimalistic pastebin functionality

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
