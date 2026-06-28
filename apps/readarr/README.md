# Readarr (Bookshelf Fork) - Book & Audiobook Management

Bookshelf is an actively maintained fork of Readarr (which has been officially retired). It manages book and audiobook collections for Usenet and BitTorrent users, with metadata sourced from Hardcover.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/alvaroestradadev/bookshelf:hardcover` (temporary; see below) |
| **Internal Port** | 8067 |
| **Host Port** | 8067 |
| **Subdomain** | `readarr.aevion.lan` |
| **Container Name** | `readarr` |

**Why Bookshelf?** The original Readarr project was retired due to unusable metadata. Bookshelf (by pennydreadful) is the most popular fork with ARM64 support, best file matching rates (93-105%), and active maintenance. It uses [rreading-glasses](https://github.com/blampe/rreading-glasses) for metadata via the shared `hardcover.bookinfo.pro` instance.

### Upstream image (temporary community fork)

We use `ghcr.io/alvaroestradadev/bookshelf:hardcover` until [pennydreadful/bookshelf#158](https://github.com/pennydreadful/bookshelf/pull/158) is merged and a new official `hardcover` image is published. Upstream v0.4.20.129 rejects qBittorrent 5.2+ login (HTTP 204); Radarr/Sonarr/Lidarr already handle this.

**Watch upstream (pick one or more):**

1. **GitHub PR** — Subscribe on [PR #158](https://github.com/pennydreadful/bookshelf/pull/158) (merged = fix is in `develop`).
2. **GitHub repo** — Watch [pennydreadful/bookshelf](https://github.com/pennydreadful/bookshelf) → Custom → Releases (new `hardcover` build after merge).
3. **Image digest** — Periodically on the server, compare upstream vs what you run:

```bash
# Upstream (switch back when digest changes from the broken build)
podman pull ghcr.io/pennydreadful/bookshelf:hardcover
podman image inspect ghcr.io/pennydreadful/bookshelf:hardcover --format '{{.Digest}} {{.Created}}'

# Current fork
podman image inspect ghcr.io/alvaroestradadev/bookshelf:hardcover --format '{{.Digest}} {{.Created}}'
```

Broken upstream digest (Feb 2026, no qBit 5.2 fix): `sha256:22abf676f59c61629f8bdfbd610e3bd496d431986170c84886b45d7ce06daf5b`

**Switch back to official Bookshelf:**

1. Confirm PR #158 is merged and a newer `hardcover` image exists (digest ≠ value above).
2. In `podman-setup.sh`, set `IMAGE_SOURCE="ghcr.io/pennydreadful/bookshelf:hardcover"`.
3. Redeploy: `cd ~/selfhost/apps/readarr && bash podman-setup.sh`.
4. Settings → Download Clients → qBittorrent → **Test** (should succeed against qBittorrent 5.2+).

## Access

- HTTP: `http://readarr.aevion.lan`

## Initial Setup

1. Open the Readarr web UI
2. Set authentication method under Settings → General → Security
3. Configure Hardcover metadata source:
   - Navigate to `http://readarr.aevion.lan/settings/development` (manual URL entry required)
   - Set Metadata Provider Source to `https://hardcover.bookinfo.pro`
   - Click Save
4. Add download client: Settings → Download Clients → Add → qBittorrent
   - Host: `10.0.2.2`
   - Port: `8061`
   - Category: `books`
5. Add root folder for ebooks: `/media/Books`
6. Prowlarr will auto-sync indexers

### Integration with Calibre-Web & Audiobookshelf

- **Ebooks**: Readarr downloads to `~/media/Books`, which is the same directory Calibre-Web-Automated monitors
- **Audiobooks**: Readarr can also manage audiobooks that Audiobookshelf reads from `~/media/Books`

### Hardlinking Path Layout

```
/media/                    (container) = ~/media/ (host)
├── Downloads/
│   └── complete/
│       └── books/         ← qBittorrent downloads here
└── Books/                 ← Readarr moves/hardlinks here
```

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | Readarr configuration and database |
| `/media` | `~/media` | Shared media root (downloads + libraries) |

## Dependencies

- Download client: qBittorrent (port 8061)
- Indexer manager: Prowlarr (auto-syncs indexers)
- Metadata: Shared Hardcover instance at `https://hardcover.bookinfo.pro`
- Book management: Calibre-Web-Automated (port 8083), Audiobookshelf (port 8042)

## Documentation

- [Bookshelf GitHub](https://github.com/pennydreadful/bookshelf)
- [rreading-glasses (metadata)](https://github.com/blampe/rreading-glasses)
- [Readarr Wiki](https://wiki.servarr.com/readarr) (original docs, still mostly applicable)
- [FORKS.md comparison](https://github.com/blampe/rreading-glasses/blob/main/FORKS.md)
