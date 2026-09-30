# Priviblur

Priviblur is a privacy-focused alternative frontend for Tumblr that allows browsing Tumblr content without tracking, ads, or other privacy-invasive elements.

## Overview

Priviblur provides a clean, lightweight interface for browsing Tumblr blogs and posts while protecting user privacy. It acts as a proxy between users and Tumblr, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading and viewing Tumblr content.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Tumblr
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Blog Browsing**: Full support for viewing Tumblr blogs and posts
- **Search Functionality**: Search Tumblr blogs and posts
- **Feed Exploration**: Browse trending and featured content
- **No JavaScript Required**: Works without JavaScript for basic browsing
- **Mobile Friendly**: Responsive design that works on all devices
- **Customizable Preferences**: User preferences for theme and language

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8010 (web UI), internet access for Tumblr API
- **Storage**: Minimal (configuration only)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/priviblur
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/priviblur
   ```

2. **Configure Environment (optional)**
   ```bash
   # Configuration file: configs/config.toml
   # Default configuration works out of the box
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with root user (commented out user flags)
- **UID/GID**: Root user (0:0) - container runs as root
- **Volume Permissions**: Read-only config file mount with SELinux labels
- **Security Notes**: Simple stateless service with minimal security requirements

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/priviblur.conf` - Reverse proxy configuration for domain access

### Environment Variables

Priviblur uses configuration file instead of environment variables.

## Configuration

### Container Details

- **Image**: `quay.io/syeopite/priviblur:latest`
- **Ports**: Internal 8000 → External 8010 (localhost)
- **Volumes**: `configs/config.toml:/priviblur/config.toml:ro,Z` - Configuration file
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Priviblur runs with minimal configuration:
- **Host**: 0.0.0.0 (accepts connections from any interface)
- **Port**: 8000 (internal container port)
- **HTTPS**: Disabled (handled by reverse proxy)
- **Caching**: Disabled by default (can be enabled with Redis)

### Architecture

Priviblur follows a simple proxy architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Priviblur      │───▶│   Tumblr API    │
│                 │    │   (localhost:8010) │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   NGINX Proxy    │
                       │   (priviblur.    │
                       │    aevion.lan)   │
                       └──────────────────┘
```

#### Key Components
- **Priviblur Application**: Python/Sanic-based web application
- **Configuration**: TOML-based configuration file
- **Reverse Proxy**: NGINX for domain-based access
- **Tumblr API**: Proxied requests to Tumblr's public API

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8010
- **Domain Access**: https://priviblur.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Tumblr Content**
   - Visit https://priviblur.aevion.lan
   - Search for Tumblr blogs or explore trending content
   - View posts without ads or tracking

2. **Blog Exploration**
   - Enter Tumblr blog URLs or usernames
   - Browse posts, photos, and content
   - Navigate between posts and blogs

3. **Search Features**
   - Search for blogs by name or topic
   - Explore featured and trending content
   - Browse different categories and tags

### Command Line Operations

```bash
# Service management
systemctl --user status priviblur
systemctl --user restart priviblur

# Container operations
podman logs priviblur
podman exec -it priviblur /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

Priviblur is a web interface only - no API for external integration. It acts as a proxy for Tumblr's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - Priviblur is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp configs/config.toml priviblur-config-backup.toml
```

### Restore Commands

```bash
# Restore configuration and restart
cp priviblur-config-backup.toml configs/config.toml
systemctl --user restart priviblur
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active priviblur

# Container status
podman ps | grep priviblur

# Web interface check
curl -I http://localhost:8010
```

### Logs

```bash
# View recent logs
podman logs --tail 50 priviblur

# Follow logs
podman logs -f priviblur
```

### Common Issues

**Tumblr API Issues**
- Symptoms: Content not loading or API errors
- Cause: Tumblr API changes or rate limiting
- Solution: Check Tumblr API status and Priviblur logs

**Configuration Issues**
- Symptoms: Service not starting or configuration errors
- Cause: Invalid TOML syntax in config file
- Solution: Validate config.toml syntax

**Network Issues**
- Symptoms: Cannot reach Tumblr API
- Cause: Network connectivity or DNS issues
- Solution: Check internet connectivity and DNS resolution

### Performance Tuning

- **Workers**: Increase worker count for higher traffic
- **Caching**: Enable Redis caching for improved performance
- **Timeouts**: Adjust API timeouts based on network conditions

## Security

- **Container Security**: Rootless container with minimal privileges
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~100-200MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on Tumblr content browsing

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull quay.io/syeopite/priviblur:latest
systemctl --user restart priviblur
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats priviblur
```

## Notes

- **Tumblr Compatibility**: Designed as a drop-in replacement for Tumblr browsing
- **No Posting Support**: Read-only interface, cannot post to Tumblr
- **Privacy First**: Built specifically to avoid Tumblr's tracking and ads
- **Community Project**: Part of the privacy-focused frontend ecosystem

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
