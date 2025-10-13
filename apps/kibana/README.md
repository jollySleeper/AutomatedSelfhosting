# Kibana

Kibana is an open-source data visualization and exploration tool used for log and time-series analytics, application monitoring, and operational intelligence use cases. It provides powerful and beautiful dashboards that leverage the full power of Elasticsearch.

## Overview

Kibana is the user interface that lets you visualize your Elasticsearch data and navigate the Elastic Stack. It provides search and data visualization capabilities for data indexed in Elasticsearch. Kibana gives you the freedom to select the way you give shape to your data.

## Features

- **Data Visualization**: Create charts, graphs, and dashboards from Elasticsearch data
- **Interactive Dashboards**: Build dynamic, interactive dashboards with real-time data
- **Advanced Queries**: Use Kibana Query Language (KQL) and Lucene query syntax
- **Index Patterns**: Define and manage index patterns for data exploration
- **Discover Interface**: Search and explore your data with filtering and aggregation
- **Canvas**: Create pixel-perfect presentations and reports
- **Maps**: Visualize geospatial data on interactive maps
- **Machine Learning**: Anomaly detection and forecasting capabilities
- **Alerting**: Define and manage alerts based on Elasticsearch data

## Prerequisites

- **System Requirements**: Minimum 1GB RAM, modern web browser
- **Dependencies**: Elasticsearch (data source)
- **Network**: HTTP port 5601 (web interface)
- **Storage**: Minimal (stateless, data stored in Elasticsearch)

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/kibana
./podman-setup.sh start
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/kibana
   ```

2. **Ensure Elasticsearch is Running**
   ```bash
   # Kibana requires Elasticsearch to be accessible
   podman ps | grep elasticsearch
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh start
   ```

### Rootless Container Configuration

- **User Mode**: Root container (Kibana requires root for Node.js operations)
- **UID/GID**: Root user (0:0) required for Kibana daemon
- **Volume Permissions**: No persistent volumes (stateless)
- **Security Notes**: Connects to Elasticsearch for data access

### Configuration Files Modified

None - Kibana auto-discovers Elasticsearch and uses defaults.

### Environment Variables

Kibana uses default configuration with auto-discovery of Elasticsearch.

## Configuration

### Container Details

- **Image**: `docker.io/library/kibana:8.10.4`
- **Ports**: 5601:5601 (Web interface)
- **Volumes**: None (stateless, data stored in Elasticsearch)
- **Networks**: Host networking for Elasticsearch access

### Service Configuration

Kibana is configured for automatic Elasticsearch discovery:
- **Auto-Discovery**: Automatically detects local Elasticsearch instance
- **Default Settings**: Uses default configuration for development
- **Web Interface**: Port 5601 for dashboard access
- **Stateless**: No persistent storage required

### Architecture

Kibana serves as the visualization layer for Elasticsearch data:

```
┌─────────────────┐
│   Web Browser   │
│                 │
│ kibana.aevion.lan│
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│   Kibana Web    │    │   Kibana Server  │
│   Interface     │    │   (Port 5601)    │
│   (Dashboards)  │    │   Container      │
└─────────────────┘    └──────────────────┘
         │                       │
         │                       ▼
         │              ┌──────────────────┐
         │              │   Elasticsearch  │
         │              │   (Port 9200)    │
         │              │   Data Source    │
         │              └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Data Sources  │
│   (Indexes)     │
│                 │
│ • Logs          │
│ • Metrics       │
│ • Custom Data   │
└─────────────────┘
```

#### Key Components
- **Web Interface**: Dashboard creation and data visualization
- **Query Engine**: KQL and Lucene query processing
- **Visualization Engine**: Chart and graph rendering
- **Data Connectors**: Elasticsearch integration and data access

## Usage

### Accessing the Service

- **Web Interface**: http://localhost:5601 (Kibana dashboard)
- **No External Access**: Local access only (no reverse proxy configured)

### Getting Started

1. **Initial Setup**
   - Access Kibana at http://localhost:5601
   - Kibana will automatically detect Elasticsearch
   - Wait for setup completion

2. **Create Index Patterns**
   - Go to Management → Stack Management → Index Patterns
   - Create patterns for your Elasticsearch indexes
   - Define time field for time-series data

3. **Build Visualizations**
   - Use Discover to explore data
   - Create visualizations (charts, graphs, maps)
   - Build dashboards with multiple visualizations

4. **Create Dashboards**
   - Combine visualizations into interactive dashboards
   - Add filters and controls for user interaction
   - Share dashboards with other users

### Command Line Operations

```bash
# Service management
podman ps | grep kibana
podman logs kibana

# Container operations
podman exec -it kibana /bin/bash

# Check Elasticsearch connection
curl -X GET "localhost:5601/api/status"
```

## Integration

### With Other Services

- **Elasticsearch**: Primary data source for all visualizations
- **Logstash**: Data ingestion pipeline integration
- **Filebeat**: Log shipping integration
- **Metricbeat**: Metrics collection integration

### API Integration

Kibana provides APIs for:
- **Dashboard Management**: Create and manage dashboards programmatically
- **Visualization Control**: Build and modify visualizations via API
- **Saved Objects**: Manage saved searches, visualizations, and dashboards
- **Index Patterns**: Create and manage index patterns

## Backup & Recovery

### Important Data to Backup

Kibana stores data in Elasticsearch - backup Elasticsearch for data preservation.

### Backup Commands

```bash
# Kibana configuration stored in Elasticsearch
# Backup Elasticsearch for complete data preservation
```

### Restore Commands

```bash
# Restore Elasticsearch data
# Kibana will automatically detect restored data
podman restart kibana
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep kibana

# Web interface check
curl -I http://localhost:5601

# Status API
curl -X GET "localhost:5601/api/status"
```

### Logs

```bash
# Container logs
podman logs kibana

# Elasticsearch connection logs
podman logs kibana | grep elasticsearch
```

### Common Issues

**Elasticsearch Connection Issues**
- Symptoms: Kibana shows connection errors
- Cause: Elasticsearch not running or network issues
- Solution: Check Elasticsearch status and network connectivity

**Index Pattern Issues**
- Symptoms: No data visible in visualizations
- Cause: Index patterns not configured or data missing
- Solution: Create proper index patterns and verify data

**Memory Issues**
- Symptoms: Kibana slow or unresponsive
- Cause: Insufficient memory for large datasets
- Solution: Increase container memory limits

### Performance Tuning

- **Memory Allocation**: Adjust container memory for large datasets
- **Query Optimization**: Use efficient queries and aggregations
- **Dashboard Optimization**: Limit visualizations per dashboard
- **Caching**: Enable query caching for better performance

## Security

- **Container Security**: Root container (required for Kibana)
- **Network Security**: Local access only (no external exposure)
- **Data Security**: Depends on Elasticsearch security settings
- **Access Control**: Basic authentication available

## System Resources

- **Memory**: 512MB - 2GB depending on dashboard complexity
- **CPU**: Low baseline, higher during data processing
- **Storage**: Minimal (configuration stored in Elasticsearch)
- **Network**: Variable based on data visualization requests

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull docker.io/library/kibana:8.10.4
podman restart kibana
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Clear browser cache if needed
# Kibana manages its own cache
```

## Notes

- **Elasticsearch Dependency**: Requires running Elasticsearch instance
- **Auto-Discovery**: Automatically detects local Elasticsearch
- **Development Setup**: Basic configuration for development/testing
- **Visualization Focus**: Powerful dashboard and visualization capabilities

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
