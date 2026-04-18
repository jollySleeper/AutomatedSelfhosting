# AnonymousOverflow

AnonymousOverflow is a privacy-focused alternative frontend for Stack Overflow that allows browsing questions and answers without tracking, ads, or other privacy-invasive elements.

## Overview

AnonymousOverflow provides a clean, lightweight interface for browsing Stack Overflow content while protecting user privacy. It acts as a proxy between users and Stack Overflow, removing ads, tracking scripts, and other privacy-invasive elements while maintaining full functionality for reading questions and answers.

## Features

- **Privacy Protection**: Removes ads, tracking scripts, and analytics from Stack Overflow
- **Clean Interface**: Minimalist, distraction-free browsing experience
- **Question Browsing**: Full support for viewing questions, answers, and comments
- **Search Functionality**: Search Stack Overflow questions and answers
- **Tag Navigation**: Browse questions by tags and topics
- **User Profiles**: View user profiles and activity (anonymously)
- **No JavaScript Required**: Works without JavaScript for basic question viewing
- **Mobile Friendly**: Responsive design that works on all devices

## Prerequisites

- **System Requirements**: Minimum 256MB RAM, modern web browser
- **Dependencies**: None (standalone service)
- **Network**: HTTP port 8011 (web UI), internet access for Stack Overflow API
- **Storage**: Minimal (no persistent storage required)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/anonymousoverflow
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/anonymousoverflow
   ```

2. **Configure Environment (optional)**
   ```bash
   # Environment file: environments/local.env
   APP_URL=http://ao.aevion.lan
   JWT_SIGNING_SECRET=your_secret_here
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with user namespace mapping
- **UID/GID**: User namespace mapping for file access
- **Volume Permissions**: No persistent volumes required
- **Security Notes**: User namespace isolation with JWT-based security

### Configuration Files Modified

- **NGINX Config**: `apps/nginx/configs/sites/anonymousoverflow.conf` - Reverse proxy configuration for domain access

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| APP_URL | Application URL | - | Yes |
| JWT_SIGNING_SECRET | JWT signing secret | secret | Yes |

## Configuration

### Container Details

- **Image**: `ghcr.io/httpjamesm/anonymousoverflow:release`
- **Ports**: Internal 8080 → External 8011 (localhost)
- **Volumes**: None (stateless service)
- **Networks**: plain pasta (stateless privacy frontend — outbound internet only, no host services needed)

### Service Configuration

AnonymousOverflow is configured for privacy-focused Stack Overflow browsing:
- **Domain**: ao.aevion.lan (configured in environment)
- **JWT Security**: Token-based authentication for sessions
- **Health Checks**: Built-in health check monitoring
- **No Persistence**: Stateless operation

### Architecture

AnonymousOverflow provides a clean proxy interface for Stack Overflow content:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   Anonymous      │───▶│   Stack Overflow│
│                 │    │   Overflow       │    │   API           │
│ ao.aevion.lan   │    │   (localhost:8011)│    │                 │
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
- **AnonymousOverflow App**: Web application providing Stack Overflow frontend
- **JWT Authentication**: Session management and security
- **API Proxy**: Proxied requests to Stack Overflow's public API
- **Reverse Proxy**: NGINX for domain-based access

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8011
- **Domain Access**: https://ao.aevion.lan or https://anonymousoverflow.aevion.lan
- **API Endpoints**: None (web interface only)

### Getting Started

1. **Browse Stack Overflow Content**
   - Visit https://ao.aevion.lan
   - Search for questions, answers, or browse by tags
   - View content without ads or tracking

2. **Question Exploration**
   - Click on questions to view full Q&A threads
   - Read answers and comments without distractions
   - Navigate between related questions

3. **Search Features**
   - Search questions by keywords or tags
   - Filter by tags, users, or date ranges
   - Browse trending and popular questions

### Command Line Operations

```bash
# Service management
systemctl --user status anonymousoverflow
systemctl --user restart anonymousoverflow

# Container operations
podman logs anonymousoverflow
podman exec -it anonymousoverflow /bin/sh
```

## Integration

### With Other Services

- **NGINX Proxy**: Reverse proxy for secure domain-based access
- **Privacy Suite**: Part of the privacy-focused frontend collection

### API Integration

AnonymousOverflow is a web interface only - no API for external integration. It acts as a proxy for Stack Overflow's public API.

## Backup & Recovery

### Important Data to Backup

No persistent data - AnonymousOverflow is stateless and can be recreated from configuration.

### Backup Commands

```bash
# Backup configuration
cp environments/local.env anonymousoverflow-config-backup.env
```

### Restore Commands

```bash
# Restore configuration and restart
cp anonymousoverflow-config-backup.env environments/local.env
systemctl --user restart anonymousoverflow
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Service status
systemctl --user is-active anonymousoverflow

# Container status
podman ps | grep anonymousoverflow

# Web interface check
curl -I http://localhost:8011

# Health endpoint
curl http://localhost:8011/health
```

### Logs

```bash
# View recent logs
podman logs --tail 50 anonymousoverflow

# Follow logs
podman logs -f anonymousoverflow
```

### Common Issues

**Stack Overflow API Issues**
- Symptoms: Questions not loading or API errors
- Cause: Stack Overflow API changes or rate limiting
- Solution: Check Stack Overflow API status and compatibility

**JWT Issues**
- Symptoms: Session or authentication problems
- Cause: JWT secret misconfiguration
- Solution: Verify JWT_SIGNING_SECRET in environment

**Network Issues**
- Symptoms: Cannot reach Stack Overflow API
- Cause: Network connectivity or blocking
- Solution: Check internet connectivity and network restrictions

### Performance Tuning

- **Caching**: Consider enabling response caching
- **Workers**: Adjust worker processes for traffic
- **Timeouts**: Configure API request timeouts

## Security

- **Container Security**: Rootless container with user namespace isolation
- **Network Security**: Reverse proxy protection, no direct external access
- **Data Protection**: No user data stored or processed
- **Privacy**: Designed specifically for privacy protection

## System Resources

- **Memory**: ~100-300MB typical usage
- **CPU**: Low CPU usage (primarily proxying requests)
- **Storage**: Minimal (configuration file only)
- **Network**: Variable based on Stack Overflow content access

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull ghcr.io/httpjamesm/anonymousoverflow:release
systemctl --user restart anonymousoverflow
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Check resource usage
podman stats anonymousoverflow
```

## Notes

- **Stack Overflow Compatibility**: Designed as a privacy-focused alternative
- **No Account Required**: Access Stack Overflow content anonymously
- **Community Project**: Part of the privacy-focused frontend ecosystem
- **Source**: https://github.com/httpjamesm/AnonymousOverflow
- **Version**: Based on v1.12.1

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
