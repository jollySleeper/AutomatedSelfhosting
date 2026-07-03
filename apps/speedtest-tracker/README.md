# Speedtest Tracker

Speedtest Tracker is a self-hosted application that monitors the performance and uptime of your internet connection through automated speed tests.

## Overview

Speedtest Tracker provides comprehensive internet performance monitoring with automated testing, historical data analysis, and customizable notifications. It tracks download/upload speeds, ping latency, and packet loss over time to help identify connectivity issues and performance trends.

## Features

- **Automated Speed Tests**: Schedule regular speed tests using Ookla's speedtest CLI
- **Comprehensive Metrics**: Track download/upload speeds, ping, jitter, and packet loss
- **Historical Analytics**: View performance trends and identify patterns over time
- **Threshold Alerts**: Get notifications when performance drops below configured thresholds
- **Web Dashboard**: Modern web interface for viewing results and managing settings
- **Multiple Database Support**: SQLite (default) or PostgreSQL
- **Custom Scheduling**: Flexible cron-based scheduling for tests
- **API Access**: RESTful API for integration with other tools

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, internet connection for speed tests
- **Dependencies**: None (standalone service)
- **Network**: HTTP access (port 8054 internally), internet access for speed tests
- **Storage**: ~50MB for application + variable for database growth

## Installation

### Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd /home/legion/selfhost/apps/speedtest-tracker
   ```

2. **Configure Environment**
   ```bash
   # Copy sample configuration
   cp environments/sample.env environments/local.env

   # Generate Laravel application key
   APP_KEY=$(openssl rand -base64 32)
   sed -i "s|REPLACE_WITH_YOUR_GENERATED_APP_KEY|${APP_KEY}|g" environments/local.env

   # Edit other settings as needed
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

4. **Configure Reverse Proxy**
   - NGINX configuration automatically generated
   - Server name: `speedtest.aevion.lan`
   - Internal port: 8054

5. **Start Service**
   ```bash
   # Service starts automatically via systemd
   systemctl --user start speedtest-tracker
   ```

### Configuration Files Modified

- **NGINX Configuration**: Automatically generated reverse proxy configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| APP_KEY | Laravel encryption key (32-char base64) | - | Yes |
| PUID/PGID | Container user/group IDs | 1000/1000 | Yes |
| DB_CONNECTION | Database type (sqlite/postgres) | sqlite | Yes |
| DB_DATABASE | Database path/name | /config/database.sqlite | Yes |
| SPEEDTEST_SCHEDULE | Cron schedule for tests | 0 */1 * * * | No |
| APP_TIMEZONE | Application timezone | UTC | No |
| THRESHOLD_* | Performance alert thresholds | See sample.env | No |
| PRUNE_RESULTS_OLDER_THAN | Auto-delete old results (days) | 90 | No |

## Configuration

### Container Configuration

- **Image**: `lscr.io/linuxserver/speedtest-tracker:latest`
- **Ports**: Internal 80 → External 8054 (localhost)
- **User**: Non-root user (PUID/PGID from environment)
- **Volumes**: `volumes/config:/config` - Application data and database
- **Auto-update**: Registry-based automatic updates

### Service-Specific Configuration

Speedtest Tracker stores all data in the `/config` volume:
- SQLite database (or external PostgreSQL)
- Application settings and user preferences
- Speedtest results and historical data
- Log files and temporary data

### Speedtest Schedule Configuration

```bash
# Examples of different schedules
SPEEDTEST_SCHEDULE="*/30 * * * *"    # Every 30 minutes
SPEEDTEST_SCHEDULE="0 */1 * * *"     # Every hour
SPEEDTEST_SCHEDULE="0 9,14,19 * * *" # 3x daily (9am, 2pm, 7pm)
SPEEDTEST_SCHEDULE="0 2 * * *"       # Daily at 2am
```

## Usage

### Accessing the Service

- **Local Access**: http://localhost:8054
- **Domain Access**: https://speedtest.aevion.lan
- **API Endpoints**: RESTful API available for programmatic access

### Basic Usage Instructions

1. **Initial Setup**
   - Access the web interface
   - Complete the setup wizard
   - Configure speedtest preferences

2. **Monitoring Results**
   - View real-time speedtest results
   - Analyze historical performance data
   - Set up performance thresholds and alerts

3. **Configuration**
   - Adjust speedtest schedule and server preferences
   - Configure notification channels
   - Set performance thresholds

### Command Line Usage

```bash
# Check service status
systemctl --user status speedtest-tracker

# View logs
podman logs speedtest-tracker

# Restart service
systemctl --user restart speedtest-tracker

# Manual speedtest (inside container)
podman exec speedtest-tracker speedtest
```

## Integration

### With Other Services

- **Database**: Can use PostgreSQL (postgres-vector) instead of SQLite
- **Reverse Proxy**: NGINX provides secure domain-based access
- **Monitoring**: Can integrate with Prometheus/Grafana for advanced monitoring

### API Integration

Speedtest Tracker provides a REST API for:
- Retrieving speedtest results
- Managing test schedules
- Configuring settings
- Integration with external monitoring tools

## Backup and Recovery

### What to Backup

- **Database**: `volumes/config/database.sqlite` (for SQLite)
- **Configuration**: Application settings stored in database
- **Results Data**: Historical speedtest results

### Backup Commands

```bash
# Backup SQLite database
cp volumes/config/database.sqlite speedtest-backup-$(date +%Y%m%d).sqlite

# Full configuration backup
tar -czf speedtest-config-$(date +%Y%m%d).tar.gz volumes/config/
```

### Restore Commands

```bash
# Restore from backup
cp speedtest-backup-YYYYMMDD.sqlite volumes/config/database.sqlite
systemctl --user restart speedtest-tracker
```

## Monitoring

### Health Checks

```bash
# Check if service is running
systemctl --user is-active speedtest-tracker

# Check web interface
curl -I http://localhost:8054
```

### Logs

```bash
# View recent logs
podman logs --tail 50 speedtest-tracker

# Follow logs in real-time
podman logs -f speedtest-tracker
```

### Metrics

Speedtest Tracker provides performance metrics through its web interface and can be monitored for:
- Test success/failure rates
- Average performance metrics
- Alert frequency

## Troubleshooting

### Common Issues

**APP_KEY Errors**
- Symptoms: Application fails to start with encryption errors
- Cause: Missing or invalid APP_KEY
- Solution: Generate proper 32-character base64 key

**Database Connection Issues**
- Symptoms: Cannot access web interface
- Cause: File permissions or database corruption
- Solution: Check permissions and restore from backup if needed

**Speedtest Failures**
- Symptoms: Tests fail or return no results
- Cause: Network issues, blocked servers, or container limitations
- Solution: Check internet connectivity and container logs

### Logs Analysis

```bash
# Check for speedtest errors
podman logs speedtest-tracker | grep -i "failed\|error"

# Check database issues
podman logs speedtest-tracker | grep -i "database\|sqlite"
```

### Performance Tuning

- **Test Frequency**: Balance monitoring needs with resource usage
- **Data Retention**: Configure automatic pruning of old results
- **Server Selection**: Use specific speedtest servers for consistent results

## Security Considerations

- **Authentication**: Built-in user authentication system
- **Network Security**: Reverse proxy provides additional security layer
- **Data Protection**: Speedtest results contain no sensitive information
- **Updates**: Keep container image updated for security patches

## System Resource Usage

- **Memory**: 256MB - 512MB depending on usage
- **CPU**: Low baseline, spikes during speedtests
- **Storage**: ~50MB base + ~1MB/month for results (with pruning)
- **Network**: Variable - speedtests consume bandwidth being measured

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull lscr.io/linuxserver/speedtest-tracker:latest
systemctl --user restart speedtest-tracker
```

### Cleanup

```bash
# Clean up old images
podman image prune -f

# Database optimization (SQLite)
podman exec speedtest-tracker sqlite3 /config/database.sqlite "VACUUM;"
```

## Notes

- Uses Ookla's speedtest CLI for accurate measurements
- Supports multiple speedtest servers for redundancy
- Can be configured to skip tests when on VPN connections
- Community-driven project with active development

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
