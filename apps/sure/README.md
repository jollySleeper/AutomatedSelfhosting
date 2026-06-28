# Sure — Personal Finance & Wealth Dashboard

A comprehensive personal finance platform for tracking net worth, investments, spending, and budgets with an AI assistant. Forked from [Maybe Finance](https://github.com/maybe-finance/maybe).

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/we-promise/sure:stable` |
| **Internal Port** | 3000 |
| **Host Port** | 8056 |
| **Subdomain** | `sure.aevion.lan` |
| **Architecture** | Rails + PostgreSQL + Redis + Sidekiq |

## Access

- **URL**: `https://sure.aevion.lan`
- **First visit**: Creates initial admin account

## Initial Setup

1. Run the setup script:
   ```bash
   cd apps/sure
   bash podman-setup.sh
   ```

2. Generate a proper `SECRET_KEY_BASE`:
   ```bash
   openssl rand -hex 64
   ```
   Update `environments/local.env` with the generated value.

3. Set a strong `POSTGRES_PASSWORD` in `environments/local.env` and update `DATABASE_URL` to match.

4. Access `https://sure.aevion.lan` and create your account.

## Architecture

Sure runs as a Podman pod with 4 containers sharing a network namespace:

```
┌──────────────────────────────────────────────┐
│  sure-pod (port 8056 → 3000)                 │
│                                              │
│  ┌──────────────┐  ┌──────────────┐          │
│  │  sure-web    │  │  sure-worker │          │
│  │  (Rails)     │  │  (Sidekiq)   │          │
│  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │
│  ┌──────▼───────┐  ┌──────▼───────┐          │
│  │ sure-postgres│  │  sure-redis  │          │
│  │ (PG 16)      │  │  (Redis 7)   │          │
│  └──────────────┘  └──────────────┘          │
└──────────────────────────────────────────────┘
```

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `volumes/postgres-data` | `/var/lib/postgresql/data` | PostgreSQL database |
| `volumes/redis-data` | `/data` | Redis persistence |
| `volumes/app-storage` | `/rails/storage` | Active Storage uploads |

## Dependencies

- Self-contained pod (PostgreSQL + Redis bundled)
- NGINX reverse proxy for HTTPS termination

## Features

- Net worth tracking across all accounts
- Investment portfolio tracking (stocks, crypto, real estate)
- Category budgets with rollover
- Split transactions
- AI-powered auto-categorization (requires OpenAI key)
- AI financial assistant
- CSV, QIF, and PDF import
- Privacy mode
- Multi-currency support

## Documentation

- [Sure GitHub](https://github.com/we-promise/sure)
- [Self-Hosting Guide](https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md)
- [AI Setup](https://github.com/we-promise/sure/blob/main/docs/hosting/ai.md)
- [Demo](https://app.sure.am)
