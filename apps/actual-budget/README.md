# Actual Budget - Local-First Personal Finance

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `docker.io/actualbudget/actual-server:latest` |
| **Internal Port** | 5006 |
| **Host Port** | 8055 |
| **Subdomain** | `budget.aevion.lan` |
| **Data Volume** | `volumes/data` → `/data` |

## Access

- **URL**: `https://budget.aevion.lan`
- **First Login**: Set a password on first visit (stored in `/data/server-files/account.sqlite`)
- **Important**: Actual requires a secure context for `SharedArrayBuffer`. If your cert is self-signed, trust your homelab CA on the client device before logging in.

## Initial Setup

1. Run `bash podman-setup.sh`
2. Access via browser at `https://budget.aevion.lan`
3. Set a server password on first visit
4. Create a budget and start adding accounts

## Features

- Envelope-style budgeting
- Multi-device sync (local-first with server sync)
- CSV/OFX/QFX/QIF/CAMT import for transactions
- Optional end-to-end encryption
- Full API for programmatic transaction import

## Importing Data

### CSV Import (Bank Statements)
- Go to Account → Import → select CSV file
- Map columns: date, amount, payee, notes
- Supports custom date formats and delimiters

### API Import (Programmatic)
- Use `importTransactions(accountId, transactions)` for deduplication-aware import
- Use `addTransactions(accountId, transactions)` for raw bulk insert
- API docs: https://actualbudget.org/docs/api/reference

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/data` | `volumes/data` | All budget data, server config, user files |

## Dependencies

None (self-contained Node.js app with SQLite).

## Documentation

- Official: https://actualbudget.org/docs/
- Docker: https://actualbudget.org/docs/install/docker
- API: https://actualbudget.org/docs/api/
- Migration: https://actualbudget.org/docs/migration/
