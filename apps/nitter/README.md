# Nitter

Nitter is a privacy-focused alternative frontend for Twitter that allows browsing tweets, profiles, and timelines without tracking, ads, or other privacy-invasive elements.

## Overview

Nitter provides a clean, lightweight interface for browsing Twitter content while protecting user privacy. It acts as a proxy between users and Twitter, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading tweets and interacting with Twitter content.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Twitter
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Tweet Browsing**: Full support for viewing tweets, replies, and threads
- **Profile Viewing**: Access user profiles and tweet history (anonymously)
- **Search Functionality**: Search Twitter posts and users
- **RSS Feeds**: RSS support for timelines and searches
- **Media Proxy**: Proxy images and videos through Nitter
- **No JavaScript Required**: Works without JavaScript for basic tweet viewing
- **Mobile Friendly**: Responsive design that works on all devices
- **Guest Accounts**: Automatic account rotation for rate limiting
- **Redis Caching**: Optional Redis for improved performance

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: Optional Redis for caching
- **Network**: HTTP port 8018 (web UI), internet access for Twitter API
- **Storage**: Minimal (configuration and cache data)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/nitter
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/nitter
   ```

2. **Configure Environment**
   ```bash
   # Environment file: environments/nitter2.env
   # Configure Twitter credentials and settings
   TWITTER_USERNAME=your_username
   TWITTER_PASSWORD=your_password
   INSTANCE_RSS_PASSWORD=rss_password
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with user namespace mapping
- **UID/GID**: User namespace mapping for file access
- **Volume Permissions**: Configuration and data volume access
- **Security Notes**: Twitter credentials required for API access

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/nitter.conf` - Reverse proxy configuration for domain access
- **Nitter Config**: `apps/nitter/configs/nitter.conf` - Main application configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| TWITTER_USERNAME | Twitter account username | - | Yes |
| TWITTER_PASSWORD | Twitter account password | - | Yes |
| INSTANCE_RSS_PASSWORD | Password for RSS feeds | - | No |
| DISABLE_NGINX | Disable internal nginx | 1 | No |
| NITTER_ACCOUNTS_FILE | Guest accounts JSON file | - | No |

## Configuration

### Container Details

- **Image**: `ghcr.io/sekai-soft/nitter-self-contained:latest`
- **Ports**: Internal 8080 → External 8018 (localhost)
- **Volumes**:
  - `environments/nitter.env:/src/.env` - Environment configuration
  - `configs/nitter.conf:/src/nitter.conf` - Application config
  - `volumes/data:/nitter-data` - Data and cache storage
- **Networks**: plain pasta (self-contained image — bundled Redis, no host services needed)

### Service Configuration

Nitter is configured for privacy-focused Twitter browsing:
- **Guest Accounts**: Automatic account rotation to avoid rate limits
- **RSS Support**: RSS feeds for timelines and searches
- **Media Proxy**: Proxy all images and videos
- **HLS Playback**: Support for Twitter video streaming
- **Redis Caching**: Optional caching for improved performance

### Architecture

Nitter provides a clean proxy interface for Twitter content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Nitter         │───▶│   Twitter API   │
│                 │    │   (localhost:8018) │    │                 │
│ nitter.aevion.lan│    │   Nim Application │    │                 │
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
- **Nitter Application**: Nim-based web application providing Twitter frontend
- **API Proxy**: Proxied requests to Twitter's public API
- **Guest Accounts**: Multiple Twitter accounts for rate limit avoidance
- **Media Proxy**: Proxy for images and videos
- **Reverse Proxy**: NGINX for domain-based access

#### Guest Accounts System

Nitter uses multiple Twitter accounts to avoid rate limiting:
- **Automatic Rotation**: Switches between accounts automatically
- **Rate Limit Management**: Distributes requests across multiple accounts
- **Account Pool**: JSON file storing account credentials
- **Failover**: Continues working if some accounts are rate limited

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8018
- **Domain Access**: https://nitter.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Access Nitter**
   - Visit https://nitter.aevion.lan
   - No authentication required

2. **Browse Twitter Content**
   - View tweets from any public account
   - Browse timelines, threads, and conversations
   - Search for tweets, users, and hashtags

3. **RSS Feeds**
   - Access RSS feeds for user timelines
   - Subscribe to searches and hashtags via RSS
   - Use RSS password for protected feeds

4. **Media Viewing**
   - View images and videos proxied through Nitter
   - HLS video playback support
   - No tracking on media content

### Command Line Operations

```bash
# Service management
systemctl --user status nitter
systemctl --user restart nitter

# Container operations
podman logs nitter
podman exec -it nitter /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Redis**: Optional caching for improved performance
- **RSS Readers**: RSS integration for timeline following
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

Nitter is a web interface only - no direct API integration. It acts as a proxy for Twitter's public API.

## Backup & Recovery

### Important Data to Backup

- **Configuration**: Environment files and nitter.conf
- **Guest Accounts**: Account credentials and rotation data
- **Cache Data**: Optional Redis cache (if used)

### Backup Commands

```bash
# Backup configuration
cp -r environments/ configs/ nitter-config-backup/

# Backup data volume
tar -czf nitter-data-backup-$(date +%Y%m%d).tar.gz volumes/data/

# Full backup
tar -czf nitter-full-backup-$(date +%Y%m%d).tar.gz environments/ configs/ volumes/
```

### Restore Commands

```bash
# Restore configuration
cp -r nitter-config-backup/* .

# Restore data volume
tar -xzf nitter-data-backup-YYYYMMDD.tar.gz

# Restart service
systemctl --user restart nitter
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active nitter

# Container status
podman ps | grep nitter

# Web interface check
curl -I http://localhost:8018
```

### Logs

```bash
# View recent logs
podman logs --tail 50 nitter

# Follow logs
podman logs -f nitter
```

### Common Issues

**Rate Limiting**
- Symptoms: "Rate limit exceeded" errors
- Cause: Twitter API rate limits on accounts
- Solution: Add more guest accounts or reduce request frequency

**Twitter Login Issues**
- Symptoms: Cannot access Twitter content
- Cause: Invalid credentials or account issues
- Solution: Verify Twitter account credentials and status

**Media Loading Issues**
- Symptoms: Images/videos not loading
- Cause: Proxy configuration or network issues
- Solution: Check media proxy settings and network connectivity

**RSS Access Issues**
- Symptoms: RSS feeds not accessible
- Cause: Missing or incorrect RSS password
- Solution: Configure INSTANCE_RSS_PASSWORD environment variable

### Performance Tuning

- **Guest Accounts**: Add more accounts to reduce rate limiting
- **Redis Caching**: Enable Redis for improved response times
- **Connection Limits**: Adjust HTTP connection limits in config
- **Token Management**: Configure token pool size for API access

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~200-500MB typical usage
- **CPU**: Low to moderate CPU usage (depends on traffic)
- **Storage**: Minimal (configuration and cache data)
- **Network**: Variable based on Twitter content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/sekai-soft/nitter-self-contained:latest
systemctl --user restart nitter
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check data directory size
du -sh volumes/data/
```

## Notes

- **Twitter Compatibility**: Designed as a privacy-focused alternative to Twitter
- **Rate Limit Management**: Guest account system to avoid Twitter restrictions
- **No Account Required**: Access Twitter content anonymously
- **Community Project**: Part of the privacy-focused frontend ecosystem
- **Nim-based**: Fast and efficient implementation

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
