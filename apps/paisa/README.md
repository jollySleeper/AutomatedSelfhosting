# Paisa — Personal Finance Manager (India-focused)

A personal finance manager built on ledger/hledger (plaintext double-entry accounting). Especially strong for Indian investment tracking — mutual funds, NPS, PPF, stocks, gold.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `docker.io/ananthakumaran/paisa:latest` |
| **Internal Port** | 7500 |
| **Host Port** | 8057 |
| **Subdomain** | `paisa.aevion.lan` |
| **Data Format** | Ledger journal files (plaintext) |
| **Database** | SQLite (auto-generated, rebuildable from journal) |

## Access

- **URL**: `https://paisa.aevion.lan`
- **Data directory**: `volumes/data/` (contains journal files + paisa.yaml)

## Initial Setup

1. Run the setup script:
   ```bash
   cd apps/paisa
   bash podman-setup.sh
   ```

2. Access `https://paisa.aevion.lan` and create your `paisa.yaml` configuration.

3. Import data using one of:
   - **From MyExpenses**: Use `actual-helpers-india` converter:
     ```bash
     cd /path/to/actual-helpers-india
     node convert-csv-to-ledger.mjs --input-dir /path/to/migration-output --output main.ledger
     cp main.ledger ~/selfhost/apps/paisa/volumes/data/
     ```
   - **From bank CSVs**: Use Paisa's built-in import templates (SBI, HDFC, ICICI, Zerodha)
   - **Manual entry**: Write Ledger journal entries directly

## Data Storage

Paisa stores all data in **plaintext Ledger journal files**. The SQLite database (`paisa.db`) is a cache that's fully rebuildable from the journal — safe to delete and regenerate via "Sync" in the UI.

```
volumes/data/
├── paisa.yaml          # Configuration (commodities, accounts, import templates)
├── main.ledger         # Your transaction journal
├── investments.ledger  # Optional: separate file for investments
└── paisa.db            # Auto-generated SQLite cache (rebuildable)
```

## India-Specific Features

| Feature | How It Works |
|---------|-------------|
| **Mutual Fund NAV** | Auto-fetches from AMFI via mfapi.in |
| **NPS Tracking** | Auto-fetches from NPS Trust via finbodhi.com |
| **Gold/Silver Prices** | IBJA prices via finbodhi.com |
| **Cost Inflation Index** | For capital gains indexation |
| **Zerodha Import** | Built-in CSV template for trades |
| **HDFC/SBI/ICICI Import** | Built-in templates for bank statements |
| **Tax Analysis** | Capital gains, Schedule AL, tax harvesting |
| **XIRR Returns** | Investment performance analysis |

## Volumes

| Volume | Container Path | Purpose |
|--------|---------------|---------|
| `volumes/data` | `/root/Documents/paisa` | Journal files, config, SQLite cache |

## Dependencies

- None (self-contained single binary + embedded Ledger CLI)

## Documentation

- [Paisa Docs](https://paisa.fyi/)
- [Paisa GitHub](https://github.com/ananthakumaran/paisa)
- [Ledger CLI Reference](https://www.ledger-cli.org/3.0/doc/ledger3.html)
- [hledger + Paisa](https://hledger.org/paisa.html)
