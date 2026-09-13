# PairDrop - Local Peer-to-Peer File Transfer

PairDrop is an open-source, browser-based AirDrop alternative. This deployment
uses the unmodified upstream client with a private Coturn server for reliable
WebRTC connectivity on the LAN and through Tailscale.

## Quick Reference

| Property | Value |
|---|---|
| **Image** | `lscr.io/linuxserver/pairdrop:1.11.2` |
| **Container** | `pairdrop` |
| **Internal port** | `3000` |
| **Host port** | `127.0.0.1:8034` |
| **Primary URL** | `http://pairdrop.aevion.lan` |
| **Aliases** | `http://pd.aevion.lan`, `http://drop.aevion.lan` |
| **Transport** | Direct WebRTC, then private Coturn relay |
| **TURN service** | `turn.aevion.lan:3478` |
| **Systemd service** | `pairdrop.service` |

## Access

HTTP is the requested and documented primary mode:

- `http://pairdrop.aevion.lan`
- `http://pd.aevion.lan`
- `http://drop.aevion.lan`
- `http://home.aevion.lan` dashboard

The existing HTTPS virtual host remains available as an optional alternative.
HTTP does not protect PairDrop signaling or page assets from observers on the
local network, and some browser capabilities such as PWA installation and
clipboard access may require a secure context. File payloads transferred by
WebRTC remain encrypted between the browsers, including when Coturn relays
them.

### VPN DNS override

The Mac's VPN replaces the normal AdGuard Home resolver. Add the PairDrop and
TURN names to `/etc/hosts`, using the same LAN mapping as the other Aevion
services:

```text
192.168.1.105 pairdrop.aevion.lan pd.aevion.lan drop.aevion.lan turn.aevion.lan
```

`turn.aevion.lan` is required even when the PairDrop page itself opens: the
browser resolves the TURN URL independently during ICE candidate gathering.
If a client is outside the LAN and connects through Tailscale, use Aevion's
Tailscale address instead of `192.168.1.105`.

## How Transfers Work

1. Both browsers connect to PairDrop's WebSocket signaling service through
   NGINX.
2. The browsers gather local, STUN-derived, and authenticated TURN relay ICE
   candidates.
3. ICE prefers a direct browser-to-browser route.
4. If direct candidates fail, the browser automatically selects the private
   Coturn relay without modifying PairDrop's frontend.
5. The file remains a WebRTC transfer; PairDrop and NGINX do not proxy the file
   body.

## Why Coturn

PairDrop v1.11.2's `WS_FALLBACK=true` is only selected when a browser reports
that WebRTC is unavailable. It is not a true fallback when WebRTC exists but
ICE negotiation fails. A previous workaround replaced PairDrop's complete
`public/scripts/network.js` file to add a three-second fallback timer.

That override was removed because it:

- had to remain compatible with every PairDrop image update;
- could relay connections that would have succeeded after three seconds;
- used PairDrop's base64 WebSocket transfer path, adding about 33% overhead;
- routed every fallback transfer through the application server; and
- lacked WebRTC's normal peer-to-peer transport-encryption properties.

Coturn solves the same connectivity problem through the standard WebRTC ICE
process. See [TURN_RELAY_DECISION.md](./TURN_RELAY_DECISION.md) for the complete
analysis and migration record.

## Configuration

Active settings in `environments/local.env`:

| Variable | Value | Purpose |
|---|---|---|
| `PUID` | `1001` | LinuxServer host file ownership |
| `PGID` | `1001` | LinuxServer host group ownership |
| `TZ` | `Etc/UTC` | Container timezone |
| `WS_FALLBACK` | `false` | Disable the non-standard application relay |
| `RTC_CONFIG` | `/config/rtc_config.json` | Load private STUN/TURN servers |
| `RATE_LIMIT` | `false` | Private deployment; no HTTP request limiter |
| `DEBUG_MODE` | `false` | Avoid peer-address logging |

Coturn's generator creates the ignored local RTC file:

```bash
cd ~/selfhost/apps/coturn
./scripts/generate-local-config.sh
```

The checked-in `configs/rtc_config_sample.json` documents its shape without
containing the real password.

## Directory Structure

```text
apps/pairdrop/
├── podman-setup.sh
├── pairdrop.container
├── environments/
│   ├── sample.env
│   └── local.env
├── configs/
│   └── rtc_config_sample.json
├── volumes/config/
│   └── rtc_config.json          # generated, secret, ignored
├── TURN_RELAY_DECISION.md
└── README.md
```

No PairDrop application source is mounted into the container.

## Deployment

Coturn must be deployed first so that its credentials and PairDrop's matching
RTC configuration exist:

```bash
cd ~/selfhost/apps/coturn
bash podman-setup.sh

cd ~/selfhost/apps/pairdrop
bash podman-setup.sh
```

## Verification

```bash
systemctl --user status coturn.service pairdrop.service
podman logs coturn
podman logs pairdrop
podman healthcheck run coturn
curl -I -H 'Host: pairdrop.aevion.lan' http://127.0.0.1
```

For a functional test, open the HTTP PairDrop URL on two devices. Use
`chrome://webrtc-internals` or the equivalent browser diagnostics to confirm:

- a `host`/`srflx` candidate pair is selected when direct connectivity works;
- a `relay` candidate pair is selected when the direct path is intentionally
  blocked; and
- file contents and sizes match at the receiver.

## Updates

The image uses the moving application-version tag `1.11.2`, not `latest`.
LinuxServer can continue publishing base-image and security rebuilds for that
tag, while a future PairDrop major version will not be adopted implicitly.

Because no PairDrop source is overridden, upgrading later consists of changing
the image tag, regenerating the Quadlet through `podman-setup.sh`, and running
the normal verification gates.

## Documentation

- [PairDrop repository](https://github.com/schlagmichdoch/PairDrop)
- [PairDrop self-hosting guide](https://github.com/schlagmichdoch/PairDrop/blob/master/docs/host-your-own.md)
- [LinuxServer PairDrop image](https://docs.linuxserver.io/images/docker-pairdrop/)
- [Private TURN decision](./TURN_RELAY_DECISION.md)
