# LibMedium

LibMedium is a privacy-focused alternative frontend for Medium.com that allows browsing Medium articles without tracking, ads, or other privacy-invasive elements.

## Overview

LibMedium provides a clean, lightweight interface for browsing Medium.com content while protecting user privacy. It acts as a proxy between users and Medium, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading articles.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Medium
- **Clean Interface**: Minimalist, distraction-free reading experience
- **Article Browsing**: Full support for viewing Medium articles and stories
- **Search Functionality**: Search Medium articles and publications
- **User Authentication**: Support for Medium user accounts and interactions
- **RSS Feeds**: Generate RSS feeds for publications and users
- **Mobile Friendly**: Responsive design that works on all devices
- **No JavaScript Required**: Works without JavaScript for basic article viewing

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8014 (web UI), internet access for Medium API
- **Storage**: Minimal (no persistent storage required)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/libmedium
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/libmedium
   ```

2. **Configure Environment (optional)**
   ```bash
   # Configuration file: configs/local.toml
   # Default configuration works out of the box
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with user namespace mapping
- **UID/GID**: User namespace mapping for file access
- **Volume Permissions**: Read-only config file mount
- **Security Notes**: User namespace isolation for enhanced security

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/libmedium.conf` - Reverse proxy configuration for domain access

### Environment Variables

LibMedium uses configuration file instead of environment variables.

## Configuration

### Container Details

- **Image**: `docker.io/realaravinth/libmedium:latest`
- **Ports**: Internal 7000 → External 8014 (localhost)
- **Volumes**: `configs/local.toml:/etc/libmedium/config.toml:ro` - Configuration file
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

LibMedium is configured for privacy-focused Medium browsing:
- **Domain**: mid.aevion.lan (configured in config file)
- **Debug Mode**: Enabled for troubleshooting
- **Health Checks**: Built-in health check endpoint
- **User Registration**: Enabled for account management

### Architecture

LibMedium provides a clean proxy interface for Medium content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   LibMedium      │───▶│   Medium API    │
│                 │    │   (localhost:8014) │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   NGINX Proxy    │
                       │   (mid.aevion.   │
                       │    lan)          │
                       └──────────────────┘
```

#### Key Components
- **LibMedium Application**: Web application providing Medium frontend
- **Configuration**: TOML-based configuration file
- **Reverse Proxy**: NGINX for domain-based access
- **Health Monitoring**: Built-in health check system

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8014
- **Domain Access**: https://mid.aevion.lan or https://libmedium.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Medium Content**
   - Visit https://mid.aevion.lan
   - Search for articles, publications, or users
   - View content without ads or tracking

2. **Article Reading**
   - Click on articles to start reading
   - Full article content with clean formatting
   - No distractions from Medium's interface

3. **User Features**
   - Sign in with Medium account (optional)
   - Access saved articles and bookmarks
   - Follow publications and writers

### Command Line Operations

```bash
# Service management
systemctl --user status libmedium
systemctl --user restart libmedium

# Container operations
podman logs libmedium
podman exec -it libmedium /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

LibMedium is a web interface only - no API for external integration. It acts as a proxy for Medium's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - LibMedium is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp configs/local.toml libmedium-config-backup.toml
```

### Restore Commands

```bash
# Restore configuration and restart
cp libmedium-config-backup.toml configs/local.toml
systemctl --user restart libmedium
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active libmedium

# Container status
podman ps | grep libmedium

# Web interface check
curl -I http://localhost:8014

# Health endpoint
curl http://localhost:8014/health
```

### Logs

```bash
# View recent logs
podman logs --tail 50 libmedium

# Follow logs
podman logs -f libmedium
```

### Common Issues

**Medium API Issues**
- Symptoms: Articles not loading or API errors
- Cause: Medium API changes or access restrictions
- Solution: Check Medium API status and LibMedium compatibility

**Configuration Issues**
- Symptoms: Service not starting or configuration errors
- Cause: Invalid TOML syntax in config file
- Solution: Validate local.toml syntax

**Network Issues**
- Symptoms: Cannot reach Medium API
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Caching**: Consider enabling caching for better performance
- **Workers**: Increase worker processes for higher traffic
- **Timeouts**: Adjust API timeouts based on network conditions

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~100-300MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on Medium content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/realaravinth/libmedium:latest
systemctl --user restart libmedium
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats libmedium
```

## Notes

- **Medium Compatibility**: Designed as a drop-in replacement for Medium reading
- **No Publishing Support**: Read-only interface, cannot publish to Medium
- **Privacy First**: Built specifically to avoid Medium's tracking and ads
- **Community Project**: Part of the privacy-focused frontend ecosystem

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
