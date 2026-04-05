# PostgreSQL Vector Database

PostgreSQL Vector Database is a centralized PostgreSQL instance with vector extensions, providing efficient database services for multiple applications including AI/ML workloads that require vector similarity search.

## Overview

This deployment runs a single PostgreSQL instance with PGVectoRS extensions that hosts multiple databases for different applications. Instead of running separate PostgreSQL containers for each application, this centralized approach provides resource efficiency, simplified management, and consistent versioning across all services.

## Features

- **Vector Extensions**: Built-in PGVectoRS for AI/ML vector operations
- **Multi-Database Support**: Single instance hosting multiple application databases
- **Resource Efficiency**: Reduced memory and CPU usage vs multiple containers
- **Centralized Management**: Unified backup, monitoring, and maintenance
- **Data Checksums**: Enabled for data integrity verification
- **Automatic Updates**: Registry-based container updates

## Prerequisites

- **System Requirements**: Minimum 512MB RAM, modern storage with checksums
- **Dependencies**: None (standalone PostgreSQL with extensions)
- **Network**: PostgreSQL port 5432 (localhost only)
- **Storage**: Variable based on application data volume

## Installation & Deployment

### Quick Deploy

```bash
cd ~/selfhost/apps/postgres-vector
./podman-setup.sh run-con postgres-vector
```

### Manual Deployment Steps

1. **Setup Service Directory**
   ```bash
   cd ~/selfhost/apps/postgres-vector
   ```

2. **Configure Environment**
   ```bash
   cp environments/db-sample.env environments/db.env
   # Edit db.env with your desired configuration
   ```

3. **Deploy Container**
   ```bash
   ./podman-setup.sh run-con postgres-vector
   ```

4. **Generate Quadlet**
   ```bash
   ./podman-setup.sh generate-con-quadlet postgres-vector
   ./podman-setup.sh install-con-quadlet postgres-vector postgres-vector
   ```

### Rootless Container Configuration

- **User Mode**: Rootless with non-root user
- **UID/GID**: 1001:1001 (non-root user for security)
- **Volume Permissions**: User namespace mapping for data access
- **Security Notes**: Local access only, user isolation between databases

### Configuration Files Modified

- **Environment Config**: `apps/postgres-vector/environments/db.env` - Database configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| POSTGRES_USER | Superuser username | postgresql | Yes |
| POSTGRES_PASSWORD | Superuser password | - | Yes |
| POSTGRES_INITDB_ARGS | Initialization arguments | --data-checksums | No |
| POSTGRES_MULTIPLE_DATABASES | Auto-create databases | - | No |

## Configuration

### Container Details

- **Image**: `tensorchord/pgvecto-rs:pg16-v0.2.0`
- **Ports**: 5432:5432 (PostgreSQL protocol)
- **Volumes**: Data persisted in container (no external volumes)
- **Networks**: Host networking for direct port access

### Service Configuration

PostgreSQL Vector is configured for multi-tenant database hosting:
- **Vector Extensions**: PGVectoRS for similarity search operations
- **Data Checksums**: Enabled for data integrity
- **Multi-Database**: Automatic database creation from environment
- **Superuser Access**: Centralized administration

### Architecture

Centralized PostgreSQL instance serving multiple applications:

```
┌─────────────────┐    ┌──────────────────┐
│   Applications  │    │ PostgreSQL       │
│                 │    │ Vector Database  │
│ • Piped         │◄──►│ (Port 5432)      │
│ • Immich        │    ├──────────────────┤
│ • Wger          │    │ piped_db         │
│ • Jellystat     │    │ immich_db        │
│ • Paperless-ngx │    │ wger_db          │
│ • Future Apps   │    │ jfstat_db        │
│                 │    │ paperless_db     │
└─────────────────┘    │ ...              │
                       └──────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   Vector         │
                       │   Extensions     │
                       │   (PGVectoRS)    │
                       └──────────────────┘
```

#### Key Components
- **PostgreSQL Engine**: Core database with vector extensions
- **Multi-Database Setup**: Isolated databases per application
- **Vector Operations**: Similarity search and AI/ML support
- **Data Integrity**: Checksums for corruption detection

#### Current Databases

| Application | Database | User | Purpose |
|-------------|----------|------|---------|
| Piped | `piped` | `piped` | YouTube proxy service |
| Immich | `immich` | `immich` | Photo management with AI |
| Wger | `wger` | `wger` | Workout/fitness tracking |
| Jellystat | `jfstat` | `jellystat` | Jellyfin usage analytics |
| Paperless-ngx | `paperless` | `paperless` | Document management system |

## Usage

### Accessing the Service

- **Local Access**: PostgreSQL protocol on localhost:5432
- **Application Access**: Automatic (configured per application)
- **Admin Access**: psql client for database administration

### Getting Started

1. **Connect to Database**
   ```bash
   psql -h localhost -p 5432 -U postgresql -d postgres
   ```

2. **Create Application Database**
   ```sql
   CREATE USER newapp WITH PASSWORD 'password';
   CREATE DATABASE newapp_db;
   GRANT ALL PRIVILEGES ON DATABASE newapp_db TO newapp;
   ```

3. **Enable Vector Extensions**
   ```sql
   \c newapp_db
   CREATE EXTENSION vectors;
   ```

### Command Line Operations

```bash
# Service management
podman ps | grep postgres-vector
podman logs postgres-vector

# Database operations
psql -h localhost -p 5432 -U postgresql -d postgres
pg_dump -h localhost -p 5432 -U dbuser dbname > backup.sql
```

## Integration

### With Other Services

- **Piped**: YouTube proxy database backend
- **Immich**: Photo management with AI features
- **Wger**: Workout and fitness tracking
- **Jellystat**: Jellyfin usage analytics
- **Paperless-ngx**: Document management system
- **Future Applications**: Centralized database for new services

### API Integration

PostgreSQL Vector provides standard PostgreSQL connectivity:
- **JDBC**: Java applications
- **Psycopg2**: Python applications
- **PG Driver**: Various language drivers
- **Vector Operations**: Similarity search APIs

## Backup & Recovery

### Important Data to Backup

- **All Databases**: Complete database cluster data
- **Configuration**: Environment files and setup scripts
- **Application Schemas**: Database schemas and extensions

### Backup Commands

```bash
# Full instance backup
podman stop postgres-vector
pg_dumpall -h localhost -p 5432 -U postgresql > full_backup.sql
podman start postgres-vector

# Individual database backup
pg_dump -h localhost -p 5432 -U dbuser dbname > dbname_backup.sql
```

### Restore Commands

```bash
# Full restore (empty instance)
psql -h localhost -p 5432 -U postgresql < full_backup.sql

# Individual database restore
psql -h localhost -p 5432 -U postgresql -d dbname < dbname_backup.sql
```

## Monitoring & Troubleshooting

### Health Checks

```bash
# Container status
podman ps | grep postgres-vector

# Database connectivity
psql -h localhost -p 5432 -U postgresql -d postgres -c "SELECT version();"

# Active connections
psql -h localhost -p 5432 -U postgresql -d postgres -c "
SELECT datname, usename, state
FROM pg_stat_activity
WHERE state = 'active';
"
```

### Logs

```bash
# Container logs
podman logs postgres-vector

# Database logs
podman exec postgres-vector tail -f /var/lib/postgresql/data/log/postgresql-*.log
```

### Common Issues

**Connection Refused**
- Symptoms: Cannot connect to database
- Cause: Container not running or port issues
- Solution: Check container status and port availability

**Authentication Failed**
- Symptoms: Login rejected
- Cause: Incorrect credentials or user permissions
- Solution: Verify environment variables and user setup

**Vector Extension Issues**
- Symptoms: Vector operations fail
- Cause: Extension not enabled
- Solution: Run `CREATE EXTENSION vectors;` in database

### Performance Tuning

- **Memory Allocation**: Monitor and adjust container memory
- **Connection Pooling**: Consider PgBouncer for high-traffic apps
- **Index Optimization**: Create appropriate indexes for queries
- **Vector Indexing**: Use HNSW indexes for vector similarity search

## Security

- **Container Security**: Rootless container with user isolation
- **Network Security**: Local access only (no external exposure)
- **User Isolation**: Separate users and databases per application
- **Data Encryption**: Optional TLS for connections

## System Resources

- **Memory**: 512MB-2GB depending on database size and connections
- **CPU**: Variable based on query complexity and vector operations
- **Storage**: Variable based on application data volume
- **Network**: Low usage (database protocol traffic only)

## Maintenance

### Updates

```bash
# Container updates automatically via registry
# Manual update if needed
podman pull tensorchord/pgvecto-rs:pg16-v0.2.0
podman restart postgres-vector
```

### Cleanup

```bash
# Remove old images
podman image prune -f

# Vacuum databases
psql -h localhost -p 5432 -U postgresql -d postgres -c "VACUUM;"
```

## Notes

- **Centralized Architecture**: Single instance for multiple applications
- **Vector Support**: PGVectoRS extensions for AI/ML workloads
- **Resource Efficiency**: Reduced overhead vs separate containers
- **Data Integrity**: Checksums enabled for corruption detection

---

*Last updated: October 13, 2025*
*Deployed on: legion (aevion.lan)*
