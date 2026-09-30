# Redlib

Redlib is a privacy-focused alternative frontend for Reddit that allows browsing subreddits, posts, and comments without tracking, ads, or other privacy-invasive elements.

## Overview

Redlib provides a clean, lightweight interface for browsing Reddit content while protecting user privacy. It acts as a proxy between users and Reddit, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading posts and comments.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Reddit
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Subreddit Browsing**: Full support for viewing subreddits and posts
- **Comment Threads**: Complete comment system with nested discussions
- **User Profiles**: View user profiles and post/comment history (anonymously)
- **Search Functionality**: Search Reddit posts and subreddits
- **Multiple Themes**: Various theme options including dark mode
- **SFW-Only Mode**: Optional safe-for-work content filtering
- **Mobile Friendly**: Responsive design that works on all devices
- **No JavaScript Required**: Works without JavaScript for basic browsing

## Prerequisites

- **System Requirements**: Minimum 128MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8013 (web UI), internet access for Reddit API
- **Storage**: Minimal (no persistent storage required)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/redlib
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/redlib
   ```

2. **Configure Environment (optional)**
   ```bash
   # Environment file: environments/safe.env
   # Default configuration works out of the box
   REDLIB_SFW_ONLY=on
   REDLIB_DEFAULT_THEME=system
   REDLIB_DEFAULT_BLUR_NSFW=on
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: Standard container security with network isolation

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/redlib.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| REDLIB_SFW_ONLY | Enable SFW-only mode | on | No |
| REDLIB_BANNER | Instance banner message | - | No |
| REDLIB_DEFAULT_THEME | Default theme | system | No |
| REDLIB_DEFAULT_FRONT_PAGE | Default front page | default | No |
| REDLIB_DEFAULT_LAYOUT | Default layout | card | No |
| REDLIB_DEFAULT_WIDE | Enable wide mode | off | No |
| REDLIB_DEFAULT_BLUR_NSFW | Blur NSFW content | on | No |
| REDLIB_DEFAULT_HIDE_AWARDS | Hide post awards | off | No |

## Configuration

### Container Details

- **Image**: `ghcr.io/cycneuramus/containers:redlib` (temporary fix; upstream is `quay.io/redlib/redlib:latest`)
- **Ports**: Internal 8080 → External 8013 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Redlib is configured for privacy-focused Reddit browsing:
- **SFW-Only Mode**: Safe-for-work content filtering enabled
- **System Theme**: Default theme follows system preference
- **NSFW Blurring**: NSFW content blurred by default
- **Card Layout**: Clean card-based post layout
- **No Persistence**: Stateless operation

### Architecture

Redlib provides a clean proxy interface for Reddit content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Redlib         │───▶│   Reddit API    │
│                 │    │   (localhost:8013) │    │                 │
│ rd.aevion.lan   │    │   Rust Application│    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   NGINX Proxy    │
                       │   (Port 1080)    │
                       │   Reverse Proxy  │
                       └──────────────────┘
```

#### Key Components
- **Redlib Application**: Rust-based web application providing Reddit frontend
- **API Proxy**: Proxied requests to Reddit's public API
- **Reverse Proxy**: NGINX for domain-based access
- **Configuration System**: Environment-based settings for user preferences

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8013
- **Domain Access**: https://rd.aevion.lan or https://redlib.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Reddit Content**
   - Visit https://rd.aevion.lan
   - Browse subreddits, posts, or search for content
   - View content without ads or tracking

2. **Subreddit Exploration**
   - Click on subreddit links to view posts
   - Browse different sorting options (hot, new, top, etc.)
   - Navigate through post listings

3. **Post and Comments**
   - Click on posts to view full content and comments
   - Read nested comment threads
   - View user profiles and post history

4. **Search and Discovery**
   - Search for posts, subreddits, or users
   - Browse trending and popular content
   - Discover new communities

### Command Line Operations

```bash
# Service management
systemctl --user status redlib
systemctl --user restart redlib

# Container operations
podman logs redlib
podman exec -it redlib /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

Redlib is a web interface only - no API for external integration. It acts as a proxy for Reddit's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - Redlib is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp environments/safe.env redlib-config-backup.env
```

### Restore Commands

```bash
# Restore configuration and restart
cp redlib-config-backup.env environments/safe.env
systemctl --user restart redlib
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active redlib

# Container status
podman ps | grep redlib

# Web interface check
curl -I http://localhost:8013
```

### Logs

```bash
# View recent logs
podman logs --tail 50 redlib

# Follow logs
podman logs -f redlib
```

### Common Issues

**Reddit API Issues**
- Symptoms: Posts not loading or API errors
- Cause: Reddit API changes or access restrictions
- Solution: Check Reddit API status and Redlib compatibility

**Configuration Issues**
- Symptoms: Settings not applying or service errors
- Cause: Invalid environment variable syntax
- Solution: Validate safe.env file syntax and restart service

**Network Issues**
- Symptoms: Cannot reach Reddit API
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Caching**: Enable response caching for better performance
- **Worker Processes**: Adjust for concurrent request handling
- **Timeout Settings**: Configure API request timeouts

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~50-150MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on Reddit content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/cycneuramus/containers:redlib
systemctl --user restart redlib
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats redlib
```

## Notes

- **Reddit Compatibility**: Designed as a privacy-focused alternative to Reddit
- **No Account Required**: Access Reddit content anonymously
- **Community Project**: Part of the privacy-focused frontend ecosystem
- **Rust-based**: Fast and memory-efficient implementation
- **SFW-First**: Safe-for-work mode enabled by default

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
