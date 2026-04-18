# Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit originally built at SoundCloud.

## Overview

Prometheus collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts when specified conditions are observed. It is designed for reliability, with all components being stateless and with data stored locally.

## Features

- **Time Series Database**: Built-in high-performance time series database
- **Multi-dimensional Data Model**: Metrics with dimensions via labels
- **Powerful Query Language**: PromQL for complex queries and aggregations
- **Pull-based Metrics Collection**: HTTP pull model for reliability
- **Service Discovery**: Automatic service discovery and configuration
- **Alerting**: Alerting rules with Alertmanager integration
- **Visualization**: Integration with Grafana for dashboards
- **Scalability**: Horizontal scaling through federation
- **Client Libraries**: Official client libraries for major languages

## Prerequisites

- **System Requirements**: Minimum 2GB RAM, modern CPU
- **Dependencies**: Target services with metrics endpoints
- **Network**: HTTP port 9090 (web UI and API)
- **Storage**: Variable based on metrics retention (default 15 days)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/prometheus
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/prometheus
   ```

2. **Configure Prometheus**
   ```bash
   # Configuration file: configs/prometheus.yml
   # Configure scrape targets and alerting rules
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Non-root user with UID/GID mapping
- **UID/GID**: Default Prometheus user (65534:65534)
- **Volume Permissions**: User namespace mapping for data access
- **Security Notes**: Standard container security with network isolation

### Configuration Files Modified

- **Prometheus Config**: `apps/prometheus/configs/prometheus.yml` - Main configuration file

### Environment Variables

Prometheus uses configuration file instead of environment variables.

## Configuration

### Container Details

- **Image**: `quay.io/prometheus/prometheus:latest`
- **Ports**: Internal 9090 → External 9090 (web UI and API)
- **Volumes**:
  - `configs/prometheus.yml:/etc/prometheus/prometheus.yml` - Configuration file
  - `volumes/data:/prometheus` - Time series database storage
- **Networks**: `pasta:--map-host-loopback,10.0.2.2` for target scraping (cAdvisor, podman-exporter, node-exporter on host loopback)

### Service Configuration

Prometheus is configured for comprehensive monitoring:
- **Scrape Interval**: 15 seconds for real-time metrics
- **Evaluation Interval**: 15 seconds for rule evaluation
- **Retention**: Default 15 days data retention
- **Target Discovery**: Static configuration for local services

### Architecture

Prometheus collects metrics from various exporters and services:

```
┌─────────────────┐
│   Prometheus    │
│   Web UI        │
│   Port 9090     │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Prometheus    │    │   Time Series    │
│   Server        │    │   Database       │
│   (Container)   │    │   /prometheus    │
└─────────────────┘    └──────────────────┘
         │
    ┌────┼────┐
    │         │
┌───▼──┐ ┌────▼────┐ ┌──▼────┐
│ Node  │ │ cAdvisor│ │Podman │
│Exporter│ │ Metrics│ │Exporter│
│9100   │ │9091     │ │9882   │
└───────┘ └─────────┘ └───────┘
```

#### Key Components
- **Prometheus Server**: Core metrics collection and storage engine
- **Web UI**: Built-in interface for querying and visualization
- **Configuration**: YAML-based configuration for scrape targets
- **Time Series DB**: Local storage for metrics data

#### Scrape Targets
- **Prometheus**: Self-monitoring
- **Node Exporter**: System metrics (CPU, memory, disk, network)
- **cAdvisor**: Container metrics
- **Podman Exporter**: Podman-specific container metrics

## Usage

### Accessing the Service

- **Web Interface**: http://localhost:9090 (query and visualization)
- **API Endpoints**: REST API for programmatic access

### Getting Started

1. **Explore Metrics**
   - Access the web UI at http://localhost:9090
   - Use the query interface to explore available metrics
   - Execute PromQL queries for custom analysis

2. **View Dashboards**
   - Built-in expression browser for ad-hoc queries
   - Graph view for time-series visualization
   - Status pages for configuration and targets

3. **Monitor Targets**
   - Check target health and scrape status
   - View service discovery information
   - Monitor alerting rules and notifications

### Command Line Operations

```bash
# Service management
podman ps | grep prometheus
podman logs prometheus

# Container operations
podman exec -it prometheus /bin/sh

# Configuration validation
podman exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Query metrics
curl "http://localhost:9090/api/v1/query?query=up"
```

## Integration

### With Other Services

- **Grafana**: Primary dashboard and visualization tool
- **Alertmanager**: Alert routing and notification management
- **Node Exporter**: System-level metrics collection
- **cAdvisor**: Container performance metrics

### API Integration

Prometheus provides extensive APIs for:
- **Query API**: Execute PromQL queries programmatically
- **Metadata API**: Discover available metrics and labels
- **Series API**: Find time series by labels
- **Rules API**: Manage alerting and recording rules

## Backup & Recovery

### Important Data to Backup

- **Time Series Data**: `volumes/data/` - All metrics and historical data
- **Configuration**: `configs/prometheus.yml` - Scrape configuration

### Backup Commands

```bash
# Backup data directory
tar -czf prometheus-data-$(date +%Y%m%d).tar.gz volumes/data

# Backup configuration
cp configs/prometheus.yml prometheus-config-backup.yml

# Full backup
tar -czf prometheus-full-backup-$(date +%Y%m%d).tar.gz volumes/data configs/
```

### Restore Commands

```bash
# Restore data directory
tar -xzf prometheus-data-YYYYMMDD.tar.gz

# Restore configuration
cp prometheus-config-backup.yml configs/prometheus.yml

# Restart service
podman restart prometheus
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep prometheus

# Web interface check
curl -I http://localhost:9090

# API health check
curl -s "http://localhost:9090/api/v1/query?query=up" | jq .status
```

### Logs

```bash
# Container logs
podman logs prometheus

# Recent errors
podman logs prometheus | grep -i error

# Scrape failures
podman logs prometheus | grep -i "failed\|error"
```

### Common Issues

**Configuration Errors**
- Symptoms: Container fails to start or shows config errors
- Cause: Invalid YAML syntax or configuration issues
- Solution: Validate configuration with promtool

**Scrape Target Issues**
- Symptoms: Missing metrics or target down alerts
- Cause: Service not running or network connectivity issues
- Solution: Check target service status and network connectivity

**Storage Issues**
- Symptoms: Out of disk space or performance degradation
- Cause: Excessive data retention or high cardinality metrics
- Solution: Adjust retention settings or optimize metric collection

### Performance Tuning

- **Retention**: Adjust data retention period based on storage
- **Scrape Intervals**: Balance collection frequency with resource usage
- **Query Performance**: Use appropriate PromQL for efficient queries
- **Storage**: Monitor disk usage and plan for growth

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (no external exposure)
- **Data Protection**: Local metrics storage
- **Access Control**: No built-in authentication (use reverse proxy)

## System Resources

- **Memory**: 1-4GB depending on data volume and query load
- **CPU**: Variable based on scrape frequency and query complexity
- **Storage**: 10-100GB depending on retention and metrics volume
- **Network**: Minimal (local scraping and API access)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull quay.io/prometheus/prometheus:latest
podman restart prometheus
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clean old data (if needed)
# Note: Prometheus manages its own data retention
du -sh volumes/data
```

## Notes

- **Data Model**: Multi-dimensional metrics with powerful querying
- **Scalability**: Designed for high availability and federation
- **Ecosystem**: Large ecosystem of exporters and integrations
- **Self-Monitoring**: Includes its own metrics for monitoring health

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
