# FlareSolverr - Cloudflare Bypass Proxy

FlareSolverr is a proxy server that bypasses Cloudflare and DDoS-GUARD protection. It is used by Prowlarr to access indexer sites that are behind Cloudflare protection.

## Quick Reference

| Property | Value |
|----------|-------|
| **Image** | `ghcr.io/flaresolverr/flaresolverr:latest` |
| **Internal Port** | 8191 |
| **Host Port** | 8191 |
| **Container Name** | `flaresolverr` |

## Access

- API: `http://localhost:8191` (internal only, no reverse proxy needed)

## When to Install

Only install FlareSolverr if you encounter indexers in Prowlarr that are blocked by Cloudflare protection. Signs you need it:
- Prowlarr indexer tests fail with Cloudflare errors
- Search results return empty from known-working indexers

## Setup in Prowlarr

1. In Prowlarr, go to Settings → Indexers
2. Click "+" under Indexer Proxies
3. Select "FlareSolverr"
4. Configure:
   - Host: `http://10.0.2.2:8191`
   - Tag: `flaresolverr`
5. On indexers that need it, add the `flaresolverr` tag

## Resource Usage

FlareSolverr runs a headless Chromium browser internally. On an Orange Pi 5 Plus (8GB), expect:
- **RAM**: ~200-400MB when actively solving
- **CPU**: Spikes during Cloudflare challenge solving
- **Idle**: Minimal resources when not in use

Consider stopping this service when not needed: `systemctl --user stop flaresolverr.service`

## Documentation

- [FlareSolverr GitHub](https://github.com/FlareSolverr/FlareSolverr)

## ARM Compatibility Note

FlareSolverr's official image may have limited ARM support. If the container fails to start on the Orange Pi 5 Plus, try the community ARM build:

```
IMAGE_SOURCE="ghcr.io/flaresolverr/flaresolverr:latest"
# Alternative for ARM: docker.io/alexfozor/flaresolverr:latest
```
