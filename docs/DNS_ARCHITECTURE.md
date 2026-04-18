# DNS Architecture — SelfHost on `aevion`

> **Audience:** Future-you and any contributor debugging DNS issues in this repo.
> **Last updated:** 2026-04-18
>
> This document describes how DNS resolution works across the entire SelfHost
> stack — host, Tailscale, containers, and AdGuardHome — and explains the
> non-obvious design decisions. Read this before touching anything DNS-related.

---

## TL;DR

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  LAN clients & Tailscale peers   ──►  AdGuardHome (aevion, port 53)          │
│                                                                              │
│  Pasta containers on aevion      ──►  169.254.1.1  (pasta intercepts)        │
│                                        ↳ forwarded to 192.168.1.105 (AGH)    │
│                                                                              │
│  qBittorrent (exception)         ──►  1.1.1.1 / 9.9.9.9 (public, unfiltered) │
│  AdGuardHome itself              ──►  1.1.1.1 (bootstrap only)               │
└──────────────────────────────────────────────────────────────────────────────┘
```

- AGH is the single DNS authority for the LAN and the tailnet.
- Pasta containers reach AGH via **pasta's DNS-forward intercept** (port 53 only,
  no broader loopback exposure).
- qBittorrent is the only container that bypasses AGH entirely (reason:
  blocklist false-positives on tracker domains).
- Slirp4netns has been fully phased out — every container (except
  `node-exporter`, which uses `--network host`) is now on pasta. See
  [`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](./SLIRP4NETNS_TO_PASTA_MIGRATION.md)
  for historical context.

---

## 1. The moving parts

### 1.1 AdGuardHome (AGH)

- **Container:** `adguardhome` (plain pasta).
- **Listens on:** `0.0.0.0:53` (TCP/UDP) on the host via `-p 53:53/tcp -p 53:53/udp`.
- **Reachable at:** `127.0.0.1:53`, `192.168.1.105:53`, `100.64.10.1:53` (all
  map to the same listener on the host).
- **Dashboard:** `127.0.0.1:8000` (via `agh.aevion.lan` reverse proxy).
- **Config file:** `apps/adguardhome/configs/AdGuardHome.yaml` (mounted into
  the container at `/opt/adguardhome/conf`).

### 1.2 Tailscale on the host

- `tailscale set --accept-dns=true` — installed in aevion's
  `/etc/resolv.conf` as `nameserver 100.100.100.100`.
- Tailscale's tailnet-wide DNS policy forwards queries to a single
  resolver: **`100.64.10.1`**.
- `100.64.10.1` is aevion's own Tailscale IP (confirm: `tailscale ip` on aevion).
- Net effect: whenever a process on aevion uses the **system resolver**,
  it goes through `tailscaled` → looped back to `100.64.10.1:53` → AGH.
- **Containers deliberately bypass this path** for performance reasons
  (see §3).

### 1.3 Host network (Ubuntu 24.04 on Orange Pi 5 Plus)

- Managed by **NetworkManager**.
- Interface `enP4p65s0`: `ipv4.method=manual`,
  `ipv4.addresses=192.168.1.105/24`, `ipv4.gateway=192.168.1.1`.
- Static IP is configured **on the server** (not DHCP reservation on the
  router). Survives OpenWRT router reboots — see
  [`docs/STATIC_IP_SETUP.md`](./STATIC_IP_SETUP.md).
- NM's `ipv4.dns=192.168.1.105` is set but effectively overridden at runtime
  by Tailscale's `accept-dns=true`.

### 1.4 Container networking — the key mental model

Podman 5.x defaults to rootless **pasta**, and as of April 2026 every
container on aevion uses pasta (except `node-exporter`, which runs with
`--network host` so it can scrape host-level metrics). The slirp4netns →
pasta migration is complete — see
[`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](./SLIRP4NETNS_TO_PASTA_MIGRATION.md).

**Two critical pasta facts that govern the DNS design:**

#### Fact 1 — pasta copies the host's IP addresses into the container's namespace

Inside a pasta container:

```
$ ip addr show
  lo: 127.0.0.1/8
  enP4p65s0: 192.168.1.105/24        ← same IP as the host!
$ ip route get 192.168.1.105
  local 192.168.1.105 dev lo         ← classed as LOCAL
```

**Surprising consequence:** sending a packet from inside the container to
`192.168.1.105:53` does **not** reach the host's AGH. The packet is
considered local by the container's kernel, gets delivered to the
container's own `lo`, and nothing on the container's `lo` is listening on
port 53. The query times out. (This was the root cause of the broken
Prowlarr/Radarr DNS we chased in April 2026.)

**Implication:** the container's DNS target must be an address that is
**not** in the namespace's local routing table. We use `169.254.1.1` for
this — see §2.1.

#### Fact 2 — pasta does NOT copy the host's `127.0.0.1` into the container

Each container has its **own** private loopback (with nothing useful
listening). The host is visible as `169.254.1.2` (pasta's default
`--map-guest-addr`), but **only for services bound to the host's
LAN-routable addresses** (`0.0.0.0` or `192.168.1.105`). Services bound to
`127.0.0.1` on the host are **not** reachable via `169.254.1.2`; see
[§2.1.2](#212-so-why-do-we-need---map-host-loopback-at-all) for the
"why". To reach services bound to the host's `127.0.0.1`, containers
need one of:

| Mechanism | What it gives you | Cost |
|-----------|-------------------|------|
| `--dns-forward ADDR` | DNS-only intercept at `ADDR` (Podman uses `169.254.1.1` by default) | **None** — port 53 only |
| `--map-host-loopback ADDR` | Full host-loopback bridge at `ADDR` (e.g. `10.0.2.2`) | Exposes **all** host loopback ports to the container |

Our DNS architecture uses only `--dns-forward`, not `--map-host-loopback`.
That preserves the security boundary: a container that only needs DNS does
**not** gain access to PostgreSQL, qBittorrent's web UI, etc., on host
loopback.

See [`.cursor/rules/security-practices.mdc`](../.cursor/rules/security-practices.mdc)
and [`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md) for the
broader host-loopback discussion.

---

## 2. The current design

### 2.1 Why `169.254.1.1`? (and where it comes from)

`169.254.1.1` is an **IPv4 link-local** address — part of the `169.254.0.0/16`
block defined by [RFC 3927](https://datatracker.ietf.org/doc/html/rfc3927).
Link-local addresses are reserved for "this network segment only" use; they
are never routed, never assigned by DHCP to real hosts, and never advertised
by any sane network. Binding a special meaning to one inside a container
namespace is therefore guaranteed not to collide with anything on the
user's actual LAN.

(This is the same range AWS uses for its EC2 instance-metadata service at
`169.254.169.254`, for the same reason.)

**Podman explicitly chose this address.** Every pasta container on aevion
is launched by Podman with these hard-coded defaults (visible via
`ps -o args -C pasta`):

```
--dns-forward 169.254.1.1       # in-namespace DNS sink
--map-guest-addr 169.254.1.2    # how the host reaches back into the namespace
--no-map-gw                     # do NOT translate the gateway IP to host loopback
```

From `containers/common/libnetwork/pasta/pasta_linux.go`:

> "given this is a 'link local' ip it should be very unlikely that
> it causes conflicts."

So `169.254.1.1` is Podman's contract with us: any pasta container can assume
that packets to `169.254.1.1:53` will be caught and forwarded somewhere
useful. We build on top of that contract.

### 2.1.1 The three magic addresses, side-by-side

Pasta does not have a single "gateway" the way slirp4netns does. It has three
distinct virtual addresses, each with a different purpose. Confusing them is
the single most common source of "why won't my container reach X?" tickets.

| Address | What it is | What it does | Pasta flag | Set by |
|---------|-----------|--------------|------------|--------|
| **`169.254.1.1`** | Link-local (RFC 3927) | In-namespace **DNS sink**. Pasta intercepts UDP/TCP port 53 to this address and forwards the query upstream. | `--dns-forward` | Podman default, unconditional |
| **`169.254.1.2`** | Link-local (RFC 3927) | The **host itself** as seen from inside the namespace. Packets from the host to the container appear sourced from this IP; packets the container sends to this IP reach the host's **non-loopback** listeners. | `--map-guest-addr` | Podman default, unconditional |
| **`10.0.2.2`** | RFC 1918 private | The host's **loopback** (`127.0.0.1`) bridged into the namespace. Only present when explicitly requested. | `--map-host-loopback` | **Per-container, explicit** |

All three are **configurable** — Podman just picks these defaults.

### 2.1.2 So why do we need `--map-host-loopback` at all?

Given that `--map-guest-addr 169.254.1.2` already exposes "the host" to the
container, a reasonable question is: *can a container just use `169.254.1.2`
to reach host services, and avoid `--map-host-loopback` entirely?*

**Answer:** only for host services bound to the **LAN interface** (e.g.
`0.0.0.0:PORT` or `192.168.1.105:PORT`). Services bound to `127.0.0.1:PORT`
are **not** reachable via `169.254.1.2`.

Why: `--map-guest-addr` and `--map-host-loopback` are two different
translations inside pasta. `--map-guest-addr` only translates packets whose
**destination on the host** is one of the host's normally-routable
addresses. `127.0.0.1` is a special kernel-handled address that a forwarding
userspace process cannot "reach" — that's what `--map-host-loopback` is
specifically built for. In the pasta source, the two handlers are in
separate code paths and the `--map-host-loopback` flag is the *only* way to
tell pasta "also translate the host's 127.0.0.1 into the namespace".

In our setup, **every backend service** (`127.0.0.1:8050` for qBittorrent,
`127.0.0.1:5432` for Postgres, `127.0.0.1:8041` for Jellyfin, etc.) is
**deliberately bound to loopback** to keep it off the LAN. So in practice
`169.254.1.2` is of limited use to our containers — they all need
`--map-host-loopback` to reach anything meaningful on the host.

If we ever bind a host service to `0.0.0.0` (or its LAN IP), containers can
reach it via `169.254.1.2:PORT` without any extra flags. We don't currently
do that, because binding to `0.0.0.0` also makes the service visible on the
LAN, which is the opposite of what we want.

### 2.1.3 Where does `10.0.2.2` come from?

`10.0.2.2` is **not** a pasta default or a pasta-assigned address. It was
slirp4netns's built-in gateway IP (inherited from QEMU's
[SLiRP](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29)
user-mode network stack, which used `10.0.2.0/24` by convention for over two
decades). Containers on slirp4netns reached the host via `10.0.2.2` by
default.

When we migrated from slirp4netns to pasta, we needed a value to pass to
`--map-host-loopback`. We picked `10.0.2.2` **for migration continuity**:

- Existing app configs (`POSTGRES_HOST=10.0.2.2`,
  `BG_HELPER_URL=http://10.0.2.2:8024`, etc.) stayed unchanged.
- Scripts and docs that referenced `10.0.2.2` stayed meaningful.
- No behavioral difference — any other IP would work equivalently.

There is nothing special about `10.0.2.2` to pasta. We could have picked
any address that is not otherwise used in the namespace (`192.0.2.1`,
`169.254.1.3`, `203.0.113.5`, etc.). The important thing is that the same
address is used consistently across the stack.

### 2.2 What `--dns-forward` actually does

Pasta runs in userspace, in the container's network namespace. It transparently
watches for UDP/TCP packets destined for the address given by `--dns-forward`.
When it sees one:

1. It forwards the DNS query to the address given by `--dns-host` (default:
   the first `nameserver` line from the host's `/etc/resolv.conf`).
2. It writes the answer back into the namespace so the container sees it as
   coming from `169.254.1.1:53`.

**Critical property:** `--dns-forward` is a **port-53-only** intercept. It
does **not** grant the container any other access to the host or to host
loopback. This is fundamentally different from `--map-host-loopback`,
which is an *all-port* loopback bridge.

### 2.3 Why we override `--dns-host`

By default, pasta forwards DNS queries to the first nameserver in the host's
`/etc/resolv.conf`. On aevion, that's `100.100.100.100` (Tailscale MagicDNS).
Without an override, every container's DNS path is:

```
container → pasta@169.254.1.1 → host's resolver (100.100.100.100)
          → tailscaled → MagicDNS → AGH at 100.64.10.1 (self-loop)
          → AGH container → answer back through the chain
```

That self-loop adds ~1–1.5 s of cold-query latency and makes container DNS
depend on `tailscaled` being healthy.

We short-circuit it in `podman/containers.conf`:

```toml
[network]
pasta_options = ["--dns-host", "192.168.1.105"]

[containers]
dns_servers = ["169.254.1.1"]
```

**A note on terminology.** This is sometimes described as "hijacking the
host's DNS resolver". That framing isn't quite right — `--dns-host`
doesn't touch the host's resolv.conf, DNS stack, or systemd-resolved at
all. What it does is tell **pasta's in-namespace DNS intercept** to use a
specific upstream (`192.168.1.105`) instead of parsing the host's
`/etc/resolv.conf` to find one. The host's DNS behavior is unchanged;
only the *container-side* forwarding target is redirected. The host's
own `ssh`, `tailscale`, `curl`, etc. continue to use Tailscale MagicDNS
as before.

The `[network] pasta_options` array is passed verbatim to pasta after
Podman's own defaults. `--dns-host 192.168.1.105` tells pasta: "forward DNS
queries straight to AGH on aevion's LAN IP". The end-to-end path becomes:

```
container → pasta@169.254.1.1 → AGH@192.168.1.105 → answer
```

No Tailscale hop, no self-loop, ~10 ms cold-query latency. The host's own
`/etc/resolv.conf` is untouched — Tailscale MagicDNS keeps working for the
host itself (`ssh aevion`, `tailscale status`, etc.).

### 2.4 Why we use `169.254.1.1` (and not `192.168.1.105`, `127.0.0.1`, or `10.0.2.2`)

A prior iteration of this file set `dns_servers = ["192.168.1.105"]`. That
**did not work** for pasta containers — see §1.4 Fact 1. The packet never
escaped the container's namespace.

| Candidate DNS target | Why we don't use it |
|----------------------|---------------------|
| `127.0.0.1` | Container's own lo — nothing listens on 53. |
| `192.168.1.105` | Copied into namespace as local (Fact 1) — packet stuck in container lo. |
| `10.0.2.2` | Requires `--map-host-loopback,10.0.2.2` on every container, which exposes **all** host loopback ports to every container — broad security regression. See [`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md). |
| `192.168.1.1` (router) | Works for default pasta via the router's DNS forwarder, but adds a router round-trip, doesn't work for pasta containers with explicit `--map-host-loopback`, and breaks if the router's DNS forwarder is down. |
| **`169.254.1.1`** | ✅ Pasta's built-in DNS-forward address. No routing-table conflict. No additional port exposure. Works for default pasta AND for pasta with explicit `--map-host-loopback,10.0.2.2`. |

### 2.5 Per-container overrides (and the Podman `--dns` append quirk)

> **Important gotcha — discovered the hard way.** Podman 5.4.1's `--dns`
> flag **appends** values to `containers.conf` `dns_servers` instead of
> overriding them, even though the Podman manpage says "override". This
> means a plain `--dns 1.1.1.1` on a container still leaves `169.254.1.1`
> in `/etc/resolv.conf`. To actually bypass `containers.conf`, you must
> also set the env var `CONTAINERS_CONF=/dev/null` so Podman skips
> loading the file for that specific container. See §2.6.

Two containers deliberately bypass AGH, and both apply the full two-part fix:

#### qBittorrent — `apps/qbittorrent/podman-setup.sh`

```bash
CONTAINERS_CONF=/dev/null podman run \
  ...
  --dns 1.1.1.1 \
  --dns 9.9.9.9 \
  ...

action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "inject-quadlet-env" "$NAME" "Environment=CONTAINERS_CONF=/dev/null"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"
```

**Why:** AGH's StevenBlack Extra list and SafeBrowsing feed classify many
legitimate torrent tracker domains as malware/porn. qBittorrent is a
specialized outbound workload that does not need DNS-level ad/malware
filtering. Sending its DNS straight to unfiltered public resolvers avoids
false positives and also skips the AGH hop entirely (AGH is not useful for
tracker announces).

- `1.1.1.1` — Cloudflare, unfiltered.
- `9.9.9.9` — Quad9 Secure (blocks only confirmed malware, does **not**
  touch torrent trackers, porn, gambling). Provides redundancy without
  re-introducing the blocklist problem.

**Additional risk driver:** qBittorrent is the LinuxServer image
(Alpine-based, musl libc). Musl's resolver queries ALL nameservers in
parallel — whichever responds first wins. If AGH's sinkhole
(`94.140.14.33` or `0.0.0.0`) for a blocked tracker beats the real answer
from `1.1.1.1`, qBittorrent silently uses the wrong IP. The
`CONTAINERS_CONF=/dev/null` workaround is what makes the bypass deterministic.

#### AdGuardHome — `apps/adguardhome/podman-setup.sh`

Same two-part pattern:

```bash
CONTAINERS_CONF=/dev/null podman run \
  ...
  --dns 1.1.1.1 \
  ...

action_based_on_query "inject-quadlet-env" "$NAME" "Environment=CONTAINERS_CONF=/dev/null"
```

**Why:** without a bypass, AGH's `/etc/resolv.conf` would contain
`169.254.1.1` (and pasta would forward to AGH itself) — a chicken-and-egg
self-reference during startup. AGH resolves its upstreams via its internal
`bootstrap_dns` list, not via `/etc/resolv.conf`, so in practice the
self-reference is mostly cosmetic. But cleaning it up avoids flaky behavior
during image update checks, CGO-driven lookups, and startup windows where
AGH is not yet answering queries.

### 2.6 The `CONTAINERS_CONF=/dev/null` bypass pattern

Because Podman 5.4.1 appends `--dns` to `containers.conf` `dns_servers`
instead of overriding it, a container that must NOT see the default
`169.254.1.1` in its resolv.conf needs two coordinated pieces:

**Piece 1 — initial install: run podman with the env var**

```bash
CONTAINERS_CONF=/dev/null podman run \
 ...
 --dns 1.1.1.1 \
 ...
```

This makes the first-install container correct immediately.

**Piece 2 — ongoing systemd restarts: inject the env var into the quadlet**

`podlet generate` captures `podman run` args into the `[Container]` section
but does NOT capture env vars used to invoke podman itself. So we inject
`Environment=CONTAINERS_CONF=/dev/null` under the `[Service]` section of
the generated quadlet via a helper action:

```bash
action_based_on_query "generate-con-quadlet" "$NAME"
action_based_on_query "inject-quadlet-env" "$NAME" "Environment=CONTAINERS_CONF=/dev/null"
action_based_on_query "install-con-quadlet" "$NAME" "$NAME"
```

The helper (`inject_env_into_quadlet` in `scripts/podman/container.sh`) is
idempotent — re-running `podman-setup.sh` will not duplicate the line. It
uses `awk` for portability across macOS (dev) and Linux (aevion).

**Verification** after a bypass container is deployed:

```bash
podman exec <container> cat /etc/resolv.conf
# Must show ONLY the --dns servers, no 169.254.1.1.
```

If `169.254.1.1` appears, one of the pieces is missing — usually the
`Environment=` line in the quadlet, meaning the container was restarted
via systemd without re-running `podman-setup.sh`.

### 2.7 Dual-quadlet convention (`<service>.container-manual`)

For services that carry the CONTAINERS_CONF bypass (and any others with
non-trivial Quadlet directives), the repo keeps **two** files side-by-side:

| File | Who owns it | What it's for |
|------|-------------|---------------|
| `apps/<svc>/<svc>.container` | `podlet` (regenerated) | The live file — symlinked into `~/.config/containers/systemd/`. |
| `apps/<svc>/<svc>.container-manual` | Human | Clean, commented reference. Never installed. |

This is formalized in the rule
[`.cursor/rules/dual-quadlet-pattern.mdc`](../.cursor/rules/dual-quadlet-pattern.mdc)
(with the DNS-specific piece in
[`.cursor/rules/podman-dns-bypass.mdc`](../.cursor/rules/podman-dns-bypass.mdc)).

### 2.8 IPv6 policy

- Router-level: IPv6 disabled on the LAN. LAN clients get IPv4 only.
- AGH: `aaaa_disabled: true` in `AdGuardHome.yaml`. AGH returns empty AAAA
  responses to all clients, so applications don't bother trying IPv6 and
  then time out. Matches the "pure IPv4 architecture" intent.
- See [`docs/IPV6_SETUP.md`](./IPV6_SETUP.md) for a future-enablement plan.

### 2.9 Tailscale DNS policy (unchanged)

- `accept-dns=true` on aevion remains — this is what enables Tailscale
  peers (phones, laptops on the tailnet) to receive DNS from AGH even when
  not on the LAN.
- Tailnet-wide DNS policy still points at `100.64.10.1` (aevion).
- This is important for mobile usage (AGH filtering follows you via
  Tailscale) and must not be removed.
- **Only aevion-hosted containers skip Tailscale** via `pasta_options` —
  every other tailnet device still goes through it normally.

---

## 3. Request flow examples

### 3.1 A generic pasta container (e.g., Sonarr) resolves `themoviedb.org`

```
sonarr (pasta, --map-host-loopback,10.0.2.2)
  → /etc/resolv.conf: nameserver 169.254.1.1        (from containers.conf)
  → kernel: 169.254.1.1 is NOT in routing table as local → egress via default
  → pasta sees UDP/53 to 169.254.1.1 → intercepts (dns-forward)
  → pasta forwards to 192.168.1.105:53              (from containers.conf pasta_options)
  → AGH@192.168.1.105: apply filters, cache check, forward to upstream
  → response back through pasta to sonarr
```

### 3.2 A default-pasta container (e.g., Redlib) resolves `reddit.com`

Identical to §3.1 — the `--dns-forward 169.254.1.1` default is present on
all pasta containers regardless of whether they have an explicit
`--map-host-loopback` flag. The only difference is that Redlib cannot
reach host loopback at `10.0.2.2` (which is fine; it doesn't need to).

### 3.3 qBittorrent resolves `tracker.bittor.pw`

```
qbittorrent (Alpine / musl)
  → /etc/resolv.conf:
      nameserver 1.1.1.1                     ← only these, because the
      nameserver 9.9.9.9                       quadlet has both DNS= entries
                                               AND Environment=CONTAINERS_CONF=/dev/null
  → musl fires queries in parallel to both resolvers
  → pasta: these are external, egress via enP4p65s0
  → First response wins (Cloudflare or Quad9, both unfiltered for this domain)
  → qBittorrent can contact the tracker
```

Without the full bypass, `169.254.1.1` (→ AGH) would also be listed — and
AGH would return `94.140.14.33` (SafeBrowsing sinkhole) for this domain,
which musl might pick as the winner of the parallel race. That is the
exact failure mode that motivated the `CONTAINERS_CONF=/dev/null` workaround
in §2.6.

### 3.4 A Tailscale peer (e.g., phone at coffee shop) resolves `jellyfin.aevion.lan`

```
phone (on tailnet)
  → Tailscale DNS override: 100.100.100.100
  → tailscaled on phone: tailnet policy says "use 100.64.10.1"
  → UDP/53 to 100.64.10.1 (aevion)
  → AGH rewrite rule for *.aevion.lan matches
  → returns 100.64.10.1
  → phone connects to jellyfin via Tailscale MagicDNS path
```

This flow is **unchanged** by the container-DNS architecture.

---

## 4. Operational notes

### 4.1 Rollout

Containers pick up `containers.conf` defaults **only on recreation**, not on
plain `systemctl restart`. After editing `containers.conf` and deploying to
`~/.config/containers/containers.conf`:

- `bash podman-setup.sh` (which stops/removes/recreates) applies the new
  defaults immediately.
- `systemctl --user restart <name>` recreates the container in Podman
  5.x (quadlet) — so it also applies the new defaults. Verified on
  Podman 5.4.1 / aevion: restart swaps in a new pasta process with the
  new `--dns-host 192.168.1.105` arg.

Verify with:

```bash
ps -eo args -C pasta | grep --color=auto '\--dns-host'
# Each running container's pasta should show: --dns-host 192.168.1.105
```

### 4.2 Verifying DNS path inside a container

```bash
# Where is this container pointing?
podman exec <container> cat /etc/resolv.conf
# Expect: "nameserver 169.254.1.1"

# Does the intercept actually work?
podman exec <container> nslookup google.com 169.254.1.1

# Confirm pasta is forwarding to AGH (not Tailscale)
ps -o args -C pasta | grep -A0 "$(podman inspect <container> -f '{{.State.Pid}}')" \
  | grep --color=auto '\--dns-host'
```

### 4.3 When to add `--dns` to a new service

Most services should **not** override DNS. Keep them on the default
(`169.254.1.1` → AGH) so they benefit from ad/telemetry blocking and appear
in AGH query logs.

Override only when the service:

- Has strong evidence of false positives from AGH blocklists (like
  qBittorrent's trackers).
- Needs a resolver that AGH cannot provide (e.g., a private DNS over VPN).
- Is AGH itself, or another DNS service that would self-loop.

When adding `--dns`, always apply the full bypass pattern from §2.6 and
link this document in the setup-script comment.

### 4.4 Known config drift

As of 2026-04-18, the live `AdGuardHome.yaml` on aevion has more upstream
DNS servers (ControlD, Cloudflare, Mullvad, Quad9, AdGuard unfiltered) than
the version in this repo (Quad9 only). This is because AGH's web UI
rewrites the file when settings change via dashboard. A future PR should
fetch the live config and sync it to this repo to prevent a fresh install
from silently reverting manual upstream choices.

---

## 5. Why we rejected some alternatives

### 5.1 "Point containers at `127.0.0.1:53`"

Rejected. Pasta gives each container its own private loopback, separate
from the host's. Nothing is listening on the container's `127.0.0.1:53`.
Would require `--network 'pasta:--map-host-loopback,127.0.0.1'` on every
container, which is exactly the `10.0.2.2` case (§5.2) in disguise.

### 5.2 "Option A" — universal `--map-host-loopback,10.0.2.2`

Rejected — opposed by the `TODOs.md` security concern.

Would require adding `--map-host-loopback,10.0.2.2` to every container,
which exposes **all** host loopback ports (PostgreSQL on 5432,
qBittorrent's WebUI on 8061, Jellyfin on 8041, etc.) to every container —
not just the DNS port.

The current `169.254.1.1` / `--dns-host` design achieves the same DNS
speed without that broader exposure. See
[`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md) for a
complete treatment of the host-loopback question.

### 5.3 "Point containers at `192.168.1.105`" (the previous iteration of this file)

Rejected — **this is what we tried and had to revert**.

On the surface, `192.168.1.105` looks attractive: it's aevion's LAN IP,
AGH listens on it, and `ip route get 192.168.1.105` inside a pasta
container says "dev lo". But that `lo` is the **container's own loopback**,
not the host's. Pasta copies host IPs into the namespace (§1.4 Fact 1),
so packets to `192.168.1.105` from inside pasta containers never reach
AGH — they die in the container's own lo.

The symptom was ~30 containers with silently broken DNS in the weeks
following the April 2026 `containers.conf` change. The loud failure was
Prowlarr's "Could not resolve host: 1337x.to" because it actively refreshes
tracker indexers. Most other containers were caching or quiet.

Slirp4netns containers (which NAT instead of copy) continued to work
through `192.168.1.105`, which disguised the scope of the regression.

### 5.4 "Run qBittorrent on a dedicated Podman bridge network"

Deferred (not rejected).

Would preserve AGH visibility into qBittorrent's DNS queries, but requires
rearchitecting qBittorrent's networking (bridge instead of pasta), which
also changes how `6881/tcp+udp` peer connectivity is set up. The
`--dns 1.1.1.1` bypass is a one-line change and achieves the functional
goal. Revisit only if we add more containers with similar
"legitimate traffic blocked by AGH" needs.

### 5.5 "Disable `accept-dns` on Tailscale for the host"

Rejected. Would break tailnet MagicDNS for the host itself and risks
interfering with how other tailnet devices receive DNS. The
`pasta_options --dns-host` override surgically fixes the container path
without touching Tailscale's tailnet behavior.

---

## 6. Historical notes

- **2026-04-17:** First attempt — `dns_servers = ["192.168.1.105"]` in
  `containers.conf`. Worked for slirp4netns (NAT path), silently broken
  for all pasta containers (namespace-local routing).
- **2026-04-18:** Diagnosed via live packet tracing. Corrected to
  `dns_servers = ["169.254.1.1"]` + `pasta_options = ["--dns-host", "192.168.1.105"]`.
  Verified working on priviblur (default pasta) and prowlarr
  (pasta+`--map-host-loopback`).
- **2026-04-18 (later):** Completed slirp4netns → pasta migration for all
  remaining containers (nitter, goatsync, grafana, prometheus, piped-api,
  wger stack, jellystat). The entire stack is now pasta-only. See
  [`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](./SLIRP4NETNS_TO_PASTA_MIGRATION.md).

---

## 7. Future improvements

### 7.1 AGH config sync

Fetch the live `AdGuardHome.yaml` from aevion, commit to repo, reconcile
with manual dashboard edits.

### 7.2 Observability — per-container AGH clients

Now that the whole stack is on pasta + `169.254.1.1`, AGH sees queries
from a single source (pasta's dns-forward address as seen by AGH's listener
on `192.168.1.105`). To restore per-container visibility, we'd either:

1. Define AGH "persistent clients" by query-pattern heuristics, or
2. Put AGH on a podman bridge network where each container gets a
   distinct source IP.

Option 2 is more invasive and tied to the broader host-loopback question
in [`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md).

### 7.3 Rollback plan

If Fix 2 causes issues, revert by removing the `[network]` block and
`dns_servers` line from `~/.config/containers/containers.conf` on aevion
and restarting affected containers. They will fall back to the host's
resolv.conf (Tailscale MagicDNS) and DNS will work again — slow but
functional.

---

## 8. Quick reference

| Where | Setting | Value |
|-------|---------|-------|
| `podman/containers.conf` | `[network] pasta_options` | `["--dns-host", "192.168.1.105"]` |
| `podman/containers.conf` | `[containers] dns_servers` | `["169.254.1.1"]` |
| Pasta (Podman default) | `--dns-forward` | `169.254.1.1` (in-namespace DNS sink) |
| Pasta (Podman default) | `--map-guest-addr` | `169.254.1.2` (host visible to container, LAN-bound services only) |
| Pasta (Podman default) | `--no-map-gw` | set (gateway is NOT mapped to host loopback) |
| Pasta (per container, opt-in) | `--map-host-loopback` | `10.0.2.2` (host's `127.0.0.1` bridged into namespace — full loopback exposure) |
| `apps/qbittorrent/podman-setup.sh` | `--dns` | `1.1.1.1 9.9.9.9` |
| `apps/qbittorrent/podman-setup.sh` | env prefix on `podman run` | `CONTAINERS_CONF=/dev/null` |
| `apps/qbittorrent/qbittorrent.container` (quadlet) | `[Service] Environment=` | `CONTAINERS_CONF=/dev/null` |
| `apps/qbittorrent/qbittorrent.container-manual` | status | hand-written reference, not installed |
| `apps/adguardhome/podman-setup.sh` | `--dns` | `1.1.1.1` |
| `apps/adguardhome/podman-setup.sh` | env prefix on `podman run` | `CONTAINERS_CONF=/dev/null` |
| `apps/adguardhome/adguardhome.container` (quadlet) | `[Service] Environment=` | `CONTAINERS_CONF=/dev/null` |
| `apps/adguardhome/adguardhome.container-manual` | status | hand-written reference, not installed |
| `apps/adguardhome/configs/AdGuardHome.yaml` | `dns.aaaa_disabled` | `true` |
| `scripts/podman/container.sh` | helper | `inject_env_into_quadlet()` |
| `scripts/common.sh` | action | `"inject-quadlet-env"` |
| `.cursor/rules/podman-dns-bypass.mdc` | convention | `CONTAINERS_CONF=/dev/null` bypass pattern |
| `.cursor/rules/dual-quadlet-pattern.mdc` | convention | `<svc>.container-manual` reference-file convention |
| Server file system | `~/.config/containers/containers.conf` | synced from `podman/containers.conf` |
| Router | IPv6 on LAN | disabled (see `docs/IPV6_SETUP.md` for future enablement) |
| Host | Static IP | `192.168.1.105` (NetworkManager, manual — see `docs/STATIC_IP_SETUP.md`) |
| Host | `tailscale set --accept-dns` | `true` (unchanged) |
| Tailscale | Tailnet DNS resolver | `100.64.10.1` (aevion) |
| Podman version tested | | `5.4.1` on aevion |
