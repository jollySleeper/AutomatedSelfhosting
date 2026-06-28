# Paperless-ngx - Document Management System

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/paperless-ngx/paperless-ngx:latest` |
| **Internal Port** | 8000 |
| **Host Port** | 8033 |
| **Subdomain** | `paperless.aevion.lan` |
| **Database** | Shared PostgreSQL (`postgres-vector` on port 5432) |
| **Cache** | Shared Redis/Valkey (port 6379) |

## Access

- **URL**: `http://paperless.aevion.lan`
- **First Login**: Use admin credentials set via `PAPERLESS_ADMIN_USER` / `PAPERLESS_ADMIN_PASSWORD` env vars

## Prerequisites

1. **PostgreSQL**: Shared `postgres-vector` must be running with a `paperless` database created
2. **Redis**: Shared Valkey/Redis must be running on port 6379

### Database Setup

Add the paperless database to the `postgres-vector` multi-db entrypoint by updating the `POSTGRES_MULTIPLE_DATABASES` env var in `apps/postgres-vector/environments/db.env`:

```
POSTGRES_MULTIPLE_DATABASES=...:paperless,paperless,<password>
```

Or create manually:

```sql
CREATE USER paperless WITH PASSWORD '<password>';
CREATE DATABASE paperless OWNER paperless;
```

## Initial Setup

1. Ensure PostgreSQL and Redis are running
2. Create the `paperless` database in PostgreSQL
3. Generate a secret key: `python3 -c "import secrets; print(secrets.token_urlsafe(64))"`
4. Update `local.env` with the DB password and generated secret key
5. Run `bash podman-setup.sh`
6. Create admin user: `podman exec -it paperless-ngx python3 manage.py createsuperuser`

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/usr/src/paperless/data` | `volumes/data` | Search index, classification model, logs |
| `/usr/src/paperless/media` | `volumes/media` | Stored documents and thumbnails |
| `/usr/src/paperless/export` | `volumes/export` | Document export directory |
| `/usr/src/paperless/consume` | `volumes/consume` | Inbox: drop files here for auto-import |

## Usage

### Adding Documents
- **Web UI**: Upload via the browser interface
- **Consume folder**: Drop files into `volumes/consume/` for automatic processing
- **API**: POST to `/api/documents/post_document/`

### Document Types
- PDF, images (JPEG, PNG, TIFF), plain text
- Office documents (requires Tika/Gotenberg, see sample.env)

## Dependencies

- **PostgreSQL** (shared `postgres-vector` on host, port 5432)
- **Redis/Valkey** (shared instance on host, port 6379)
- Optional: Tika + Gotenberg for Office document support

## Documentation

- Official: https://docs.paperless-ngx.com/
- Configuration: https://docs.paperless-ngx.com/configuration/
- API: https://docs.paperless-ngx.com/api/
- Setup: https://docs.paperless-ngx.com/setup/
