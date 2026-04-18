# LibreMDB

LibreMDB is a privacy-focused alternative frontend for IMDb (Internet Movie Database) that allows browsing movies, TV shows, and celebrity information without tracking, ads, or other privacy-invasive elements.

## Overview

LibreMDB provides a clean, lightweight interface for browsing IMDb content while protecting user privacy. It acts as a proxy between users and IMDb, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for browsing movie and TV show information.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from IMDb
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Movie Database**: Full access to movie and TV show information
- **Search Functionality**: Search movies, TV shows, and celebrities
- **Detailed Information**: Cast, crew, ratings, reviews, and plot summaries
- **Media Gallery**: Images, posters, and promotional materials
- **No JavaScript Required**: Works without JavaScript for basic browsing
- **Mobile Friendly**: Responsive design that works on all devices
- **Redis Caching**: Optional Redis for improved performance and media caching

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: Optional Redis for caching
- **Network**: HTTP port 8015 (web UI), internet access for IMDb
- **Storage**: Minimal (optional Redis for caching)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/libremdb
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/libremdb
   ```

2. **Configure Environment**
   ```bash
   cp environments/sample.env environments/local.env
   # Edit local.env with your desired configuration
   # At minimum, configure NEXT_PUBLIC_URL and AXIOS_USERAGENT
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with user namespace mapping
- **UID/GID**: User namespace mapping for file access
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: User namespace isolation with health checks

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/libremdb.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| NEXT_PUBLIC_URL | Public URL for the instance | - | Yes |
| AXIOS_USERAGENT | User agent for IMDb requests | - | Yes |
| AXIOS_ACCEPT | Accept header for requests | - | Yes |
| AXIOS_LANGUAGE | Language preference | en-US,en;q=0.5 | No |
| NEXT_TELEMETRY_DISABLED | Disable Next.js telemetry | 1 | No |
| USE_REDIS | Enable Redis caching | false | No |
| REDIS_URL | Redis server URL | localhost:6379 | No |
| REDIS_CACHE_TTL_API | API cache TTL | 3600 | No |
| REDIS_CACHE_TTL_MEDIA | Media cache TTL | 3600 | No |

## Configuration

### Container Details

- **Image**: `ghcr.io/zyachel/libremdb:main`
- **Ports**: Internal 3000 → External 8015 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

LibreMDB is configured for privacy-focused IMDb browsing:
- **Next.js Application**: React-based web application
- **API Proxy**: Proxied requests to IMDb with custom headers
- **Health Checks**: Built-in health monitoring
- **Redis Integration**: Optional caching for improved performance

### Architecture

LibreMDB provides a clean proxy interface for IMDb content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   LibreMDB       │───▶│   IMDb API      │
│                 │    │   (localhost:8015) │    │                 │
│ imdb.aevion.lan │    │   Next.js App     │    │                 │
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
- **LibreMDB Application**: Next.js web application providing IMDb frontend
- **API Proxy**: Proxied requests to IMDb with custom headers
- **Reverse Proxy**: NGINX for domain-based access
- **Optional Caching**: Redis for response and media caching

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8015
- **Domain Access**: https://imdb.aevion.lan or https://libremdb.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Access LibreMDB**
   - Visit https://imdb.aevion.lan
   - No authentication required

2. **Browse IMDb Content**
   - Search for movies, TV shows, and celebrities
   - View detailed information, cast, crew, and ratings
   - Browse recommendations and similar titles

3. **Movie Details**
   - View plot summaries, release dates, and runtime
   - Check user ratings and reviews
   - Browse cast and crew information

4. **Media Gallery**
   - View posters, stills, and promotional images
   - Cached media for faster loading (with Redis)

### Command Line Operations

```bash
# Service management
systemctl --user status libremdb
systemctl --user restart libremdb

# Container operations
podman logs libremdb
podman exec -it libremdb /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Redis**: Optional caching for improved performance
- **Media Applications**: Integration with movie/TV libraries
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

LibreMDB is a web interface only - no direct API integration. It acts as a proxy for IMDb's public content.

## Backup & Recovery

### Important Data to Backup

No persistent data - LibreMDB is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp environments/local.env libremdb-config-backup.env
```

### Restore Commands

```bash
# Restore configuration and restart
cp libremdb-config-backup.env environments/local.env
systemctl --user restart libremdb
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active libremdb

# Container status
podman ps | grep libremdb

# Web interface check
curl -I http://localhost:8015

# Health endpoint
curl http://localhost:8015/api/health
```

### Logs

```bash
# View recent logs
podman logs --tail 50 libremdb

# Follow logs
podman logs -f libremdb
```

### Common Issues

**IMDb API Issues**
- Symptoms: Content not loading or API errors
- Cause: IMDb changes or header requirements
- Solution: Update AXIOS_USERAGENT and AXIOS_ACCEPT headers

**Configuration Issues**
- Symptoms: Service not starting or missing environment variables
- Cause: Incomplete environment configuration
- Solution: Verify all required environment variables are set

**Network Issues**
- Symptoms: Cannot reach IMDb
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Redis Caching**: Enable Redis for improved response times
- **Cache TTL**: Adjust cache duration for API and media
- **Header Optimization**: Fine-tune request headers for better compatibility

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~150-400MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on IMDb content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/zyachel/libremdb:main
systemctl --user restart libremdb
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats libremdb
```

## Notes

- **IMDb Compatibility**: Designed as a privacy-focused alternative to IMDb
- **No Account Required**: Access IMDb content anonymously
- **Community Project**: Part of the privacy-focused frontend ecosystem
- **Next.js Framework**: Modern React-based implementation
- **Header Spoofing**: Custom headers to avoid IMDb restrictions

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
