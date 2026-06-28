# Rimgo

Rimgo is a privacy-focused alternative frontend for Imgur that allows viewing images without tracking or ads.

## Overview

Rimgo provides a clean, lightweight interface for browsing Imgur content while protecting user privacy. It acts as a proxy between users and Imgur, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for viewing images and albums.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Imgur
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Image Viewing**: Full support for viewing individual images and albums
- **Direct Links**: Provides direct links to original images
- **No JavaScript Required**: Works without JavaScript for basic image viewing
- **Mobile Friendly**: Responsive design that works on all devices

## Prerequisites

- **System Requirements**: Minimum 128MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP access (port 8019 internally), internet access for Imgur API
- **Storage**: Minimal (no persistent storage required)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/rimgo
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/rimgo
   ```

2. **Configure Environment (if needed)**
   ```bash
   # Environment file: environments/local.env
   # IMGUR_CLIENT_ID is pre-configured
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: Runs as non-root user with network isolation via pasta

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/rimgo.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| ADDRESS | Bind address | 0.0.0.0 | Yes |
| PORT | Internal port | 3000 | Yes |
| IMGUR_CLIENT_ID | Imgur API client ID | 546c25a59c58ad7 | Yes |
| SECURE | HTTPS mode | true | No |
| FIBER_PREFORK | Multi-process mode | false | No |

## Configuration

### Container Details

- **Image**: `codeberg.org/rimgo/rimgo:latest`
- **Ports**: Internal 3000 → External 8019 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Rimgo is configured for privacy-focused operation:
- **Imgur Client ID**: Pre-configured for basic functionality
- **Privacy Settings**: Configured to not collect user data
- **HTTPS Mode**: Enabled for secure connections
- **No Prefork**: Single-process mode for container efficiency

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8019
- **Domain Access**: https://rimgo.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Imgur Content**
   - Visit https://rimgo.aevion.lan
   - Enter Imgur URLs or search terms
   - View images without ads or tracking

2. **Direct Image Links**
   - Rimgo provides clean URLs for direct image access
   - Example: `https://rimgo.aevion.lan/a/album_id` for albums

3. **Privacy Features**
   - No ads or tracking scripts
   - No user data collection
   - Clean, minimal interface

### Command Line Operations

```bash
# Service management
systemctl --user status rimgo
systemctl --user restart rimgo

# Container operations
podman logs rimgo
podman exec -it rimgo /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

Rimgo is a web interface only - no API for external integration. It acts as a proxy for Imgur's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - Rimgo is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp environments/local.env rimgo-config-backup.env
```

### Restore Commands

```bash
# Restore configuration and restart
cp rimgo-config-backup.env environments/local.env
systemctl --user restart rimgo
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active rimgo

# Container status
podman ps | grep rimgo

# Web interface check
curl -I http://localhost:8019
```

### Logs

```bash
# View recent logs
podman logs --tail 50 rimgo

# Follow logs
podman logs -f rimgo
```

### Common Issues

**Imgur API Issues**
- Symptoms: Images not loading or API errors
- Cause: Imgur API changes or client ID issues
- Solution: Check Imgur API status and client ID validity

**Permission Issues (Rootless)**
- Symptoms: Container fails to start with permission errors
- Cause: Non-root user unable to bind to low ports
- Solution: Container correctly configured for high port binding

**Network Issues**
- Symptoms: Cannot reach Imgur API
- Cause: Network connectivity or DNS issues
- Solution: Check internet connectivity and DNS resolution

### Performance Tuning

- **Memory**: Lightweight service, minimal resource tuning needed
- **Caching**: No local caching configured
- **Rate Limiting**: Consider rate limiting for high-traffic scenarios

## Security

- **Container Security**: Rootless container with non-root user
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~50-100MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (no persistent storage)
- **Network**: Variable based on image viewing (proxies Imgur traffic)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull codeberg.org/rimgo/rimgo:latest
systemctl --user restart rimgo
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats rimgo
```

## Notes

- **Imgur Compatibility**: Designed as a drop-in replacement for Imgur viewing
- **No Upload Support**: Read-only interface, cannot upload to Imgur
- **Privacy First**: Built specifically to avoid Imgur's tracking and ads
- **Community Project**: Part of the Librarian project for ethical frontends

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
