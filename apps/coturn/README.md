# Coturn - Private TURN Relay for PairDrop

Coturn supplies standards-based STUN/TURN connectivity for the stock PairDrop
client. Browsers use direct WebRTC when possible and automatically select this
relay when direct ICE candidates cannot connect.

## Quick Reference

| Property | Value |
|---|---|
| **Image** | `docker.io/coturn/coturn:4.18.0` |
| **Container** | `coturn` |
| **Listener** | TCP/UDP `3478` |
| **UDP relay range** | `49160-49200` |
| **DNS name / realm** | `turn.aevion.lan` |
| **Network mode** | Plain rootless `pasta` |
| **Systemd service** | `coturn.service` |

## Access and Scope

Coturn is published directly on the server because TURN is not an HTTP reverse
proxy workload. AdGuard Home resolves `turn.aevion.lan` to the appropriate
`aevion` address for LAN and Tailscale clients.

The service uses plain `turn:` over UDP first and TCP second. This matches the
requested HTTP-mode deployment and avoids maintaining certificates for a
private `.lan` name. WebRTC still encrypts the browser-to-browser data carried
through TURN. TURN authentication/control traffic itself does not receive the
additional protection that TURN-over-TLS would provide, so the listener must
remain limited to the trusted LAN/Tailnet and must not be port-forwarded from
the public Internet.

## Security Controls

- Long-term, randomly generated credentials are required.
- Secrets live only in ignored `environments/local.env` and the generated,
  ignored PairDrop `rtc_config.json`.
- The upstream image runs as `nobody`; the container is additionally rootless,
  read-only, and uses `no-new-privileges`. All capabilities are dropped except
  `NET_BIND_SERVICE`, which is required for TCP/UDP 3478.
- Writable state is limited to small tmpfs mounts.
- TLS/DTLS listener ports are disabled because this is a private HTTP-mode
  deployment.
- Multicast and loopback relay destinations are disabled.
- Unauthorized-response rate limiting and household-sized allocation quotas
  reduce abuse potential.
- Only 41 UDP relay ports are exposed instead of Coturn's default 16,384-port
  range.

The generated Quadlet needs a small post-generation transformation. Podlet
copies `${TURN_*}` into `Exec=`, where systemd would expand it before Podman
loads the container environment. The setup script changes those references to
`$${TURN_*}` so the official Coturn entrypoint receives and expands them.
`coturn.container-manual` is the required reference-only explanation of this
and the other non-trivial flags; it is never installed.

## Initial Setup

Generate credentials and PairDrop's matching RTC configuration:

```bash
cd ~/selfhost/apps/coturn
./scripts/generate-local-config.sh
```

The generator is idempotent: it preserves an existing Coturn password and
regenerates PairDrop's JSON from it.

Deploy Coturn before redeploying PairDrop:

```bash
bash podman-setup.sh
cd ../pairdrop
bash podman-setup.sh
```

## Generated Local Files

| File | Purpose |
|---|---|
| `apps/coturn/environments/local.env` | Coturn username, password, and realm |
| `apps/pairdrop/volumes/config/rtc_config.json` | Matching browser ICE configuration |

Both paths are gitignored. Never paste their contents into logs or tickets.

## Operations

```bash
systemctl --user status coturn.service
podman logs coturn
podman healthcheck run coturn
ss -lntup | grep -E ':(3478|4916[0-9]|491[7-9][0-9]|49200)\b'
```

The server itself is not included in AdGuard Home's client-specific
`*.aevion.lan` rewrite, so resolving `turn.aevion.lan` from Aevion may return
NXDOMAIN. LAN and named Tailnet clients are covered by the source-aware rules.
For a server-side allocation test, target `192.168.1.105`; use the hostname
from an actual client.

## Dependencies

- AdGuard Home for `turn.aevion.lan` source-aware DNS.
- PairDrop with `RTC_CONFIG=/config/rtc_config.json`.
- LAN/Tailscale routing to TCP/UDP 3478 and UDP 49160-49200.

## Documentation

- [Coturn Docker documentation](https://github.com/coturn/coturn/tree/master/docker/coturn)
- [PairDrop self-hosting guide](https://github.com/schlagmichdoch/PairDrop/blob/master/docs/host-your-own.md)
- [Deployment decision](../pairdrop/TURN_RELAY_DECISION.md)
