# Grafana

Grafana is an open-source platform for monitoring and observability that provides beautiful, interactive dashboards for time series data visualization.

## Overview

Grafana allows you to query, visualize, alert on and understand your metrics no matter where they are stored. Create, explore, and share dashboards with your team and foster a data-driven culture. This deployment integrates with Prometheus for comprehensive monitoring and visualization.

## Features

- **Interactive Dashboards**: Create dynamic, interactive dashboards with panels and widgets
- **Multiple Data Sources**: Support for Prometheus, InfluxDB, Elasticsearch, and many others
- **Advanced Queries**: Powerful query editor with auto-completion and syntax highlighting
- **Alerting System**: Define alert rules and notification channels
- **User Management**: Multi-user support with role-based access control
- **Plugin Ecosystem**: Extensive plugin system for data sources, panels, and apps
- **Dashboard Templating**: Template variables for dynamic, reusable dashboards
- **Annotation Support**: Add context to graphs with annotations
- **Export/Import**: Share dashboards and data sources across instances
- **Mobile Support**: Responsive design that works on all devices

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, modern web browser
- **Dependencies**: Data sources (Prometheus, etc.), optional database for advanced features
- **Network**: HTTP port 3300 (web UI)
- **Storage**: Variable based on dashboard complexity and data retention

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/grafana
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/grafana
   ```

2. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Non-root user with UID/GID mapping
- **UID/GID**: 472:472 (default Grafana user)
- **Volume Permissions**: User namespace mapping for data access
- **Security Notes**: Standard container security with user isolation

### Configuration Files Modified

- **Grafana Config**: `apps/grafana/configs/grafana.ini` - Main configuration file

### Environment Variables

Grafana uses configuration file instead of environment variables in this setup.

## Configuration

### Container Details

- **Image**: `docker.io/grafana/grafana-oss:latest`
- **Ports**: Internal 3000 → External 3300 (web UI)
- **Volumes**:
  - `volumes/data:/var/lib/grafana` - Dashboard data, users, and configurations
- **Networks**: `pasta:--map-host-loopback,10.0.2.2` (reaches Prometheus and other scrape targets on host loopback)

### Service Configuration

Grafana is configured for monitoring and visualization:
- **Data Sources**: Pre-configured for Prometheus integration
- **Dashboards**: Ready for system and application monitoring
- **Users**: Admin access for dashboard management
- **Plugins**: Basic plugin support for extended functionality

### Architecture

Grafana serves as the visualization layer for monitoring data:

```
┌─────────────────┐
│   Web Browser   │
│                 │
│ grafana.aevion.lan│
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   NGINX Proxy   │    │   Grafana Web    │
│   (Port 1080)   │◄──►│   Interface      │
│                 │    │   (Port 3300)    │
└─────────────────┘    └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   Grafana DB     │
         │              │   (SQLite)       │
         │              │   /var/lib/      │
         │              │   grafana        │
         │              └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Data Sources  │◄──►│   Prometheus     │
│   (Metrics)     │    │   (Port 9090)    │
│                 │    │                  │
│ • Node Exporter │    │ • System Metrics │
│ • cAdvisor      │    │ • App Metrics    │
│ • Podman        │    │ • Custom Metrics │
└─────────────────┘    └──────────────────┘
```

#### Key Components
- **Grafana Web UI**: Main interface for dashboard creation and management
- **Data Sources**: Connections to monitoring backends (Prometheus, etc.)
- **Dashboard Engine**: Rendering and interaction engine for visualizations
- **User Management**: Authentication and authorization system

## Usage

### Accessing the Service

- **Web Interface**: https://grafana.aevion.lan or http://localhost:3300
- **API Endpoints**: RESTful API for programmatic access

### Getting Started

1. **Initial Login**
   - Access the web interface
   - Default credentials: admin/admin (change immediately)
   - Set up organization preferences

2. **Add Data Sources**
   - Configure Prometheus as data source
   - Add other monitoring endpoints as needed
   - Test connections and save configurations

3. **Create Dashboards**
   - Import pre-built dashboards
   - Create custom panels and visualizations
   - Set up alerting rules and notifications

### Command Line Operations

```bash
# Service management
podman ps | grep grafana
podman logs grafana

# Container operations
podman exec -it grafana /bin/bash

# Grafana CLI (limited in container)
podman exec grafana grafana --version
```

## Integration

### With Other Services

- **Prometheus**: Primary data source for metrics and monitoring
- **Node Exporter**: System-level metrics collection
- **cAdvisor**: Container performance metrics
- **Podman Exporter**: Podman-specific container metrics

### API Integration

Grafana provides extensive APIs for:
- **Dashboard Management**: Create, update, and delete dashboards
- **Data Source Configuration**: Programmatic data source management
- **User Management**: User and organization administration
- **Alert Management**: Alert rule and notification management

## Backup & Recovery

### Important Data to Backup

- **Dashboard Data**: `volumes/data/` - All dashboards, users, and configurations
- **Data Sources**: Configured data source connections
- **Alert Rules**: Custom alerting configurations

### Backup Commands

```bash
# Backup data directory
tar -czf grafana-data-$(date +%Y%m%d).tar.gz volumes/data

# Export dashboards via API
curl -H "Authorization: Bearer <api-key>" \
  http://localhost:3300/api/dashboards/db > dashboards.json
```

### Restore Commands

```bash
# Restore data directory
tar -xzf grafana-data-YYYYMMDD.tar.gz

# Import dashboards via API
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer <api-key>" \
  -d @dashboards.json \
  http://localhost:3300/api/dashboards/import
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep grafana

# Web interface check
curl -I http://localhost:3300

# API health check
curl http://localhost:3300/api/health
```

### Logs

```bash
# Container logs
podman logs grafana

# Recent errors
podman logs grafana | grep -i error

# Startup logs
podman logs grafana | head -50
```

### Common Issues

**Login Issues**
- Symptoms: Cannot log in with admin credentials
- Cause: Default password not changed or authentication misconfiguration
- Solution: Reset admin password or check authentication settings

**Data Source Connection Issues**
- Symptoms: No data in dashboards or connection errors
- Cause: Prometheus not accessible or connection misconfigured
- Solution: Verify data source URL and authentication

**Dashboard Loading Issues**
- Symptoms: Dashboards not displaying or panels showing errors
- Cause: Data source issues or query problems
- Solution: Check data source health and query syntax

**Plugin Installation Issues**
- Symptoms: Plugins not installing or loading
- Cause: Permission issues or plugin compatibility
- Solution: Check plugin permissions and Grafana version compatibility

### Performance Tuning

- **Query Caching**: Enable query result caching for better performance
- **Dashboard Refresh**: Adjust auto-refresh intervals appropriately
- **Resource Limits**: Monitor container resource usage
- **Data Source Optimization**: Optimize queries and reduce data volume

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (use reverse proxy for external access)
- **User Authentication**: Built-in user management and authentication
- **Data Source Security**: Secure connections to data sources

## System Resources

- **Memory**: 256-1GB depending on dashboard complexity and concurrent users
- **CPU**: Low baseline, spikes during dashboard queries and rendering
- **Storage**: ~100MB base + variable for dashboard data and plugins
- **Network**: Minimal (primarily local data source connections)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/grafana/grafana-oss:latest
podman restart grafana
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear temporary files
podman exec grafana rm -rf /tmp/*
```

## Notes

- **Dashboard Ecosystem**: Extensive library of pre-built dashboards
- **Plugin System**: Rich ecosystem for extended functionality
- **Multi-tenancy**: Organization and team-based access control
- **Alerting Integration**: Native alerting with notification channels

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
