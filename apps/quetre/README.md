# Quetre

Quetre is a privacy-focused alternative frontend for Quora that allows browsing questions and answers without tracking, ads, or other privacy-invasive elements.

## Overview

Quetre provides a clean, lightweight interface for browsing Quora content while protecting user privacy. It acts as a proxy between users and Quora, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading questions and answers.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Quora
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Question Browsing**: Full support for viewing questions, answers, and discussions
- **Search Functionality**: Search Quora questions and topics
- **Topic Navigation**: Browse questions by topics and categories
- **User Profiles**: View user profiles and activity (anonymously)
- **No JavaScript Required**: Works without JavaScript for basic question viewing
- **Mobile Friendly**: Responsive design that works on all devices
- **Caching Support**: Optional Redis caching for improved performance

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: Optional Redis for caching
- **Network**: HTTP port 8012 (web UI), internet access for Quora API
- **Storage**: Minimal (optional Redis for caching)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/quetre
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/quetre
   ```

2. **Configure Environment (optional)**
   ```bash
   # Environment file: environments/prod-http.env
   # Default configuration works out of the box
   NODE_ENV=production
   PORT=3000
   NO_UPGRADE=1
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

- **NGINX Config**: `apps/nginx/configs/sites/quetre.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| NODE_ENV | Environment mode | production | No |
| PORT | Internal port | 3000 | Yes |
| CACHE_PERIOD | Static file cache duration | 1h | No |
| NO_UPGRADE | Prevent HTTPS upgrades | 1 | No |
| REDIS_URL | Redis cache URL | (disabled) | No |
| REDIS_TTL | Redis cache TTL | 3600 | No |

## Configuration

### Container Details

- **Image**: `codeberg.org/video-prize-ranch/quetre:latest`
- **Ports**: Internal 3000 → External 8012 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

Quetre is configured for privacy-focused Quora browsing:
- **Production Mode**: Optimized for production deployment
- **HTTP Only**: Configured to prevent HTTPS upgrades
- **Caching**: Static file caching enabled
- **No Persistence**: Stateless operation

### Architecture

Quetre provides a clean proxy interface for Quora content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Quetre         │───▶│   Quora API     │
│                 │    │   (localhost:8012) │    │                 │
│ qo.aevion.lan   │    │   Node.js App     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   NGINX Proxy    │
                       │   (Port 1080)    │
                       │   Reverse Proxy  │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Redis Cache    │
                       │   (Optional)     │
                       │   For Performance│
                       └──────────────────┘
```

#### Key Components
- **Quetre Application**: Node.js web application providing Quora frontend
- **API Proxy**: Proxied requests to Quora's public API
- **Reverse Proxy**: NGINX for domain-based access
- **Optional Caching**: Redis for response caching (not configured)

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8012
- **Domain Access**: https://qo.aevion.lan or https://quetre.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Quora Content**
   - Visit https://qo.aevion.lan
   - Search for questions, topics, or browse categories
   - View content without ads or tracking

2. **Question Exploration**
   - Click on questions to view full Q&A threads
   - Read answers and discussions without distractions
   - Navigate between related questions

3. **Topic Browsing**
   - Browse questions by topics and categories
   - Discover trending and popular content
   - Follow topics of interest

### Command Line Operations

```bash
# Service management
systemctl --user status quetre
systemctl --user restart quetre

# Container operations
podman logs quetre
podman exec -it quetre /bin/bash
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Redis**: Optional caching for improved performance
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

Quetre is a web interface only - no API for external integration. It acts as a proxy for Quora's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - Quetre is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp environments/prod-http.env quetre-config-backup.env
```

### Restore Commands

```bash
# Restore configuration and restart
cp quetre-config-backup.env environments/prod-http.env
systemctl --user restart quetre
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active quetre

# Container status
podman ps | grep quetre

# Web interface check
curl -I http://localhost:8012
```

### Logs

```bash
# View recent logs
podman logs --tail 50 quetre

# Follow logs
podman logs -f quetre
```

### Common Issues

**Quora API Issues**
- Symptoms: Questions not loading or API errors
- Cause: Quora API changes or access restrictions
- Solution: Check Quora API status and Quetre compatibility

**Configuration Issues**
- Symptoms: Service not starting or environment errors
- Cause: Invalid environment variable syntax
- Solution: Validate prod-http.env file syntax

**Network Issues**
- Symptoms: Cannot reach Quora API
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Caching**: Enable Redis caching for better performance
- **Cache Period**: Adjust static file cache duration
- **Request Timeouts**: Configure API request timeouts

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~100-300MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on Quora content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull codeberg.org/video-prize-ranch/quetre:latest
systemctl --user restart quetre
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats quetre
```

## Notes

- **Quora Compatibility**: Designed as a privacy-focused alternative to Quora
- **No Account Required**: Access Quora content anonymously
- **Community Project**: Part of the privacy-focused frontend ecosystem
- **Source**: https://github.com/zyachel/quetre
- **Container Source**: https://codeberg.org/video-prize-ranch/quetre

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
