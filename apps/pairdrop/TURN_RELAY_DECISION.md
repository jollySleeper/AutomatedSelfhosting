# PairDrop Connectivity Decision: Stock Client with Private Coturn

## Decision

Use the unmodified PairDrop v1.11.2 client with an authenticated private Coturn
service. Prefer direct WebRTC and let the browser automatically select a TURN
relay when direct ICE negotiation fails.

The deployment intentionally does not mount or patch any PairDrop JavaScript.
HTTP is the primary requested access mode. Coturn uses plain `turn:` over UDP
with TCP fallback and is limited to the trusted LAN/Tailnet.

## Context

The original deployment used `lscr.io/linuxserver/pairdrop:latest`, local
WebSocket signaling through NGINX, and `WS_FALLBACK=true`. Mac and Android
clients reached the site but did not appear to each other. Chromium reported:

```text
RTCPeerConnectionIceErrorEvent
errorCode: 701
errorText: STUN host lookup received error
url: stun:stun.l.google.com:19302
```

AdGuard Home is configured with `aaaa_disabled: true`. A live comparison
confirmed that public DNS returned IPv4 and IPv6 records for Google's STUN
name while AdGuard returned only IPv4. That explains why an IPv6 host candidate
could emit error 701, but it does not prove that the warning caused the entire
WebRTC connection to fail. ICE may continue with IPv4 and other candidates.

The confirmed upstream limitation was more important: PairDrop v1.11.2 only
uses its WebSocket fallback when WebRTC is reported unavailable. It does not
automatically switch when WebRTC exists but candidate negotiation fails. This
is tracked upstream in PairDrop issue #228.

## Previous Workaround

A complete modified copy of PairDrop's `public/scripts/network.js` was mounted
over the image version. It:

- converted error 701 into a debug message;
- watched ICE and WebRTC failure states;
- imposed a three-second connection deadline;
- introduced a custom `wsFallbackRequest` signaling message; and
- replaced both peers with PairDrop `WSPeer` objects on failure.

The workaround functioned independently of the container image because the
bind mount survived container recreation. However, it remained coupled to the
internal classes and signaling protocol of PairDrop v1.11.2.

## September 13 Image Update Evidence

The server update replaced LinuxServer image `v1.11.2-ls143` with
`v1.11.2-ls144` and recreated the PairDrop container at 15:59 IST. The PairDrop
application version remained v1.11.2. The LinuxServer rebuild updated packaging
and base components, including OpenSSL 3.5.7 to 3.5.8.

The custom bind mount remained active after that update; the running custom
script's hash still matched the repository copy and differed from the stock
v1.11.2 script. Therefore, that particular image update did not overwrite the
workaround. It demonstrated the longer-term compatibility risk rather than an
actual replacement of the file.

The Podman auto-update timer was disabled at review time. The update was
therefore initiated manually, likely through the repository update script or a
direct `podman auto-update`; the precise initiating command was not available
in the journal.

## Options Considered

### 1. No STUN/TURN Servers

PairDrop can be configured with an empty `iceServers` array. This removes the
Google STUN lookup and is an upstream-recommended diagnostic for devices on a
simple LAN.

Advantages:

- no additional service;
- no external DNS or STUN dependency;
- direct, encrypted WebRTC only; and
- no application modification.

Limitations:

- only host candidates are available;
- it cannot bridge Wi-Fi isolation, difficult VLANs, restrictive VPN/browser
  behavior, or NAT; and
- removing the visible error 701 does not guarantee that the previously failed
  peer connection will start working.

This remains a useful diagnostic mode but is not the selected reliable design.

### 2. Force PairDrop's WebSocket Relay

WebRTC can be reported as unsupported to make PairDrop use its existing
WebSocket transfer implementation.

Advantages:

- predictable connection through the application server; and
- no TURN listener or UDP relay range.

Limitations:

- forcing it requires application code or per-browser configuration;
- transferred binary chunks are base64 encoded, adding roughly 33% overhead;
- all traffic passes through PairDrop and NGINX;
- the path does not provide the same peer-to-peer transport encryption as
  WebRTC; and
- it conflicts directly with the requirement to maintain no PairDrop code.

This option was rejected.

### 3. Managed or Public TURN

A third-party TURN service would avoid operating Coturn locally.

Advantages:

- no additional local container; and
- standard WebRTC behavior.

Limitations:

- relay traffic may leave the LAN and traverse the Internet;
- performance depends on the provider and its geography;
- the provider receives connection metadata;
- credentials, quotas, and availability become external dependencies; and
- it recreates the public-relay conditions self-hosting was meant to avoid.

This option was rejected for privacy, locality, and predictable performance.

### 4. Wait for PairDrop's Future True Fallback

Upstream intends to improve fallback behavior in a future major version, but
issue #228 remains open and v1.11.2 is still the latest release.

This is not an immediate solution. A future release can be evaluated without
carrying local source changes.

### 5. Private Coturn

Coturn provides `relay` ICE candidates using the protocol WebRTC already
understands.

Advantages:

- no PairDrop source modifications;
- direct routes remain preferred;
- relay selection is automatic when direct routes fail;
- files remain WebRTC traffic and encrypted between browsers;
- binary data avoids PairDrop's base64 WebSocket overhead;
- local relay traffic stays on infrastructure controlled by the operator; and
- Coturn supplies an official, maintained ARM64 image for the Orange Pi.

Costs:

- one additional container and credential pair;
- direct TCP/UDP 3478 exposure on trusted networks;
- a mapped UDP relay range; and
- operational testing of DNS, firewall, and ICE candidate selection.

This option was selected because it is the only current choice combining
reliable automatic fallback, standard browser behavior, and zero PairDrop code
maintenance.

## Selected Architecture

```text
Browser A                         Browser B
    |                                 |
    +------ WebSocket signaling ------+
              through NGINX

    +---------- direct WebRTC --------+   preferred
    |                                 |
    +-- WebRTC -> private Coturn ------+   automatic fallback
```

Components:

- PairDrop HTTP: `pairdrop.aevion.lan` -> NGINX -> `127.0.0.1:8034`.
- TURN DNS: `turn.aevion.lan`, resolved by AdGuard Home.
- TURN listener: UDP and TCP 3478.
- TURN relay range: UDP 49160-49200.
- Authentication: generated long-term username/password.
- PairDrop setting: `RTC_CONFIG=/config/rtc_config.json`.
- PairDrop setting: `WS_FALLBACK=false`.

## HTTP-Mode Consequences

HTTP was explicitly requested and remains enabled without redirection.

WebRTC file payloads are encrypted between browser peers even when Coturn
forwards them. However, HTTP has separate limitations:

- the PairDrop page and signaling WebSocket are not protected from LAN
  observation or modification;
- service workers, PWA installation, clipboard, notifications, and other
  secure-context features may be restricted by browsers; and
- plain TURN does not add TURN-over-TLS protection around TURN control traffic.

The deployment therefore must remain private: no router port-forwarding of 80,
3478, or 49160-49200. Tailscale supplies network encryption when clients use
the Tailnet path. The existing HTTPS PairDrop virtual host remains available if
requirements change.

## Image Strategy

PairDrop uses `lscr.io/linuxserver/pairdrop:1.11.2` instead of `latest`.
LinuxServer may update this tag with base-image security rebuilds, but it will
not automatically advance to a future PairDrop application version.

Coturn uses `docker.io/coturn/coturn:4.18.0`, which similarly permits image
revisions for that Coturn release without an implicit major-version jump.

Both remain eligible for the repository's registry auto-update workflow.

## Secret Management

`apps/coturn/scripts/generate-local-config.sh` generates a random 256-bit
hexadecimal password and writes two mode-0600 ignored files:

- `apps/coturn/environments/local.env`
- `apps/pairdrop/volumes/config/rtc_config.json`

The same credential must be present in Coturn and PairDrop. The generator is
idempotent so routine deployments do not rotate the password accidentally.

## Security Controls

- Rootless Podman user service.
- Upstream Coturn process runs as `nobody`.
- Read-only root filesystem.
- All Linux capabilities dropped except `NET_BIND_SERVICE`, the single
  effective capability needed for listener port 3478.
- `no-new-privileges` enabled.
- Writable paths are size-limited tmpfs.
- Long-term credentials required.
- The admin CLI and DTLS are left at Coturn 4.18's disabled defaults; TLS is
  explicitly disabled. Multicast and loopback relay peers are denied.
- Unauthorized response rate limiting enabled.
- Per-user and total allocations limited.
- Relay range reduced from the default 49152-65535 to 49160-49200.

## Implementation and Deployment Record

The migration was deployed on September 13, 2026. Before changing either
service, the previous PairDrop definition and custom script were preserved at:

```text
/home/legion/selfhost/backups/pairdrop-coturn-migration-20260913T113500Z
```

The implementation added a separate `apps/coturn` service, generated a shared
credential pair, mounted only PairDrop's normal `/config` directory, and
removed the application-source bind mount. The generated local files are mode
0600 and Git-ignored. The PairDrop RTC file is owned as `1001:1001` inside the
rootless user namespace so the LinuxServer process can read it without making
the secret broadly readable.

Several deployment checks caught issues before PairDrop was migrated:

1. Dropping every capability prevented the `turnserver` executable from
   starting. The final container drops everything and adds only
   `NET_BIND_SERVICE`; `/proc/1/status` confirmed that `0x400` is its sole
   permitted and effective capability.
2. Podlet placed `${TURN_*}` references in Quadlet `Exec=`. systemd tried to
   expand them before Podman loaded the container environment. The setup script
   now changes them to `$${TURN_*}` after generation; systemd passes one dollar
   onward and Coturn's official entrypoint expands the container variables.
   The secret values themselves are not embedded in the Quadlet.
3. Coturn 4.18 rejects the older `--no-dtls` and `--no-loopback-peers` options
   and deprecates `--no-cli`. Those functions are disabled by default in this
   version, so the obsolete flags were removed. `-n` explicitly selects
   command-line-only configuration.
4. A running `Restart=always` Quadlet recreated PairDrop after the installer
   stopped its container directly. Both setup scripts now stop an existing
   systemd user unit before replacing its container, avoiding that race during
   future reruns.
5. An authenticated client-to-client test against 127.0.0.1 received 403,
   correctly demonstrating the loopback-peer denial. The same test through the
   LAN address passed over both UDP and TCP.

After the gates passed, PairDrop was regenerated from
`lscr.io/linuxserver/pairdrop:1.11.2`. Runtime inspection confirmed only the
`/config` mount, `RTC_CONFIG=/config/rtc_config.json`, and
`WS_FALLBACK=false`. The backend and all three HTTP host aliases returned 200.
Coturn was active and healthy, ran as `nobody`, and accepted authenticated
allocations over UDP and TCP. The obsolete remote `network.js` was then removed
after its backup was confirmed.

AdGuard Home uses source-aware `aevion.lan` rewrites: LAN clients resolve the
name to `192.168.1.105`, while named Tailnet clients receive the configured
Tailscale address. Aevion itself is deliberately not one of those client rules,
so a hostname lookup from the server can return NXDOMAIN; server-side relay
tests therefore used the LAN address. Actual browser validation should use
`turn.aevion.lan`, as supplied in the RTC configuration.

On the Mac, the active VPN replaces AdGuard Home DNS. The established local
workaround is an `/etc/hosts` mapping. PairDrop requires all four names on the
same line because loading the HTTP site does not prove that the separately
resolved TURN hostname works:

```text
192.168.1.105 pairdrop.aevion.lan pd.aevion.lan drop.aevion.lan turn.aevion.lan
```

The address must be changed to Aevion's Tailscale IP when the client is outside
the LAN. The host-file override is client-local and is not part of the server
deployment.

## Validation Gates

Deployment is complete only after all of these pass:

1. Generated files exist, are mode 0600, and are ignored by Git.
2. Coturn and PairDrop Quadlets are regenerated from their setup scripts.
3. `coturn.service` and `pairdrop.service` are active.
4. Coturn's health check passes.
5. Coturn listens only on the documented ports.
6. PairDrop mounts no application JavaScript.
7. PairDrop loads `RTC_CONFIG` and WebSocket fallback is off.
8. HTTP aliases return successful responses.
9. Two-device direct WebRTC transfer succeeds when the network allows it.
10. A controlled test selects a `relay` ICE candidate and transfers a file
    successfully when the direct route is blocked.

Items 1-8 and server-side authenticated UDP/TCP allocations passed during the
deployment. Items 9-10 require two real browser devices and remain the final
user-facing acceptance test; they cannot be proven by a server-local STUN test
alone.

## Rollback

If Coturn must be removed temporarily:

1. Stop `coturn.service`.
2. Remove `RTC_CONFIG` from PairDrop's local environment.
3. Regenerate and redeploy the PairDrop Quadlet from `podman-setup.sh`.

Do not restore the old `network.js` override. The supported degraded mode is
stock direct WebRTC with PairDrop's default STUN configuration.

## References

- [PairDrop issue #228](https://github.com/schlagmichdoch/PairDrop/issues/228)
- [PairDrop issue #180](https://github.com/schlagmichdoch/PairDrop/issues/180)
- [PairDrop self-hosting guide](https://github.com/schlagmichdoch/PairDrop/blob/master/docs/host-your-own.md)
- [Coturn Docker image](https://github.com/coturn/coturn/tree/master/docker/coturn)
- [WebRTC ICE candidate errors](https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/icecandidateerror_event)
