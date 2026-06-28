# qBittorrent - Torrent Download Client

qBittorrent is a full-featured, open-source BitTorrent client. It integrates with Radarr, Sonarr, Lidarr, and Readarr for automated media downloading.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/linuxserver/qbittorrent:latest` |
| **Internal Port** | 8080 (Web UI), 6881 (BitTorrent) |
| **Host Port** | 8061 (Web UI) |
| **Subdomain** | `qbt.aevion.lan` |
| **Container Name** | `qbittorrent` |

## Access

- HTTP: `http://qbt.aevion.lan`
- Default credentials: admin / check container logs for temporary password on first launch

## Initial Setup

1. Check container logs for the temporary admin password: `podman logs qbittorrent`
2. Log in and change the password immediately
3. Set the default download path to `/downloads/complete`
4. Under Downloads → Categories, create categories:
   - `movies` → Save path: `/downloads/complete/movies`
   - `tv` → Save path: `/downloads/complete/tv`
   - `music` → Save path: `/downloads/complete/music`
   - `books` → Save path: `/downloads/complete/books`

### Hardlinking Configuration

The `/downloads` volume is mounted under `~/media/Downloads`. All *arr apps also mount `~/media` as `/media`, so completed downloads and library folders share the same filesystem — enabling instant hardlinks instead of slow copies.

## Volumes

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/config` | `volumes/config` | qBittorrent configuration |
| `/downloads` | `~/media/Downloads` | Shared download directory |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8061 → 8080 | TCP | Web UI |
| 6881 | TCP/UDP | BitTorrent incoming connections |

## DNS (bypasses AdGuardHome)

qBittorrent is the only container (alongside AGH itself) that does not use AdGuardHome for DNS. Its resolv.conf contains ONLY `1.1.1.1` (Cloudflare) and `9.9.9.9` (Quad9 Secure), set by `--dns` flags in `podman-setup.sh`.

**Why:** AGH's StevenBlack Extra list and built-in SafeBrowsing feed classify several legitimate torrent trackers as malware/porn domains. Confirmed blocked trackers include `bt.xxx-tracker.com`, `tracker.bittor.pw`, `glotorrents.pw`, `tracker1.520.jp`, `tracker1.myporn.club`, `p4p.arenabg.ch`. Bypassing AGH for this specialized outbound workload eliminates these false positives without weakening filtering for any other service.

### Implementation detail — the Podman `--dns` append quirk

Podman 5.4.1 APPENDS `--dns` values to `containers.conf` `dns_servers` instead of overriding them (contrary to the manpage). Because `podman/containers.conf` globally points every container at AGH (`192.168.1.105`), a plain `--dns 1.1.1.1` would leave AGH in resolv.conf *in addition* to the intended servers — and this image's musl libc resolver queries all nameservers in parallel, letting AGH's sinkhole IP win races.

The fix has two parts, both applied automatically by `podman-setup.sh`:

1. The initial `podman run` is prefixed with `CONTAINERS_CONF=/dev/null`.
2. After the quadlet is generated, `Environment=CONTAINERS_CONF=/dev/null` is injected into the `[Service]` section so subsequent systemd restarts keep the bypass.

**Verify after deploy:**

```bash
podman exec qbittorrent cat /etc/resolv.conf
# Must be exactly:
# nameserver 1.1.1.1
# nameserver 9.9.9.9
```

If `192.168.1.105` appears, the bypass failed. See [`/docs/DNS_ARCHITECTURE.md`](../../docs/DNS_ARCHITECTURE.md) § 3.2-3.4 and [`.cursor/rules/podman-dns-bypass.mdc`](../../.cursor/rules/podman-dns-bypass.mdc) for the full pattern.

### Related files

- `qbittorrent.container` — live quadlet (symlinked into `~/.config/containers/systemd/`)
- `qbittorrent.container-manual` — hand-written reference for diffing and emergency bootstrap (never installed)

## Comparison with aria2

| Feature | qBittorrent | aria2 |
|---------|-------------|-------|
| Torrent support | Full featured | Basic |
| *arr integration | Native, excellent | Requires plugins |
| Web UI | Built-in | Requires AriaNg |
| HTTP/FTP downloads | No | Yes |
| Resource usage | ~100-200MB RAM | ~20-50MB RAM |
| Best for | *arr stack automation | Direct/HTTP downloads |

## Documentation

- [LinuxServer qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/)
- [TRaSH Guides - qBittorrent](https://trash-guides.info/Downloaders/qBittorrent/)
