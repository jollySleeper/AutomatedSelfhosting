# Slirp4netns → Pasta Migration

> **Audience:** The single person (hi, future-you) migrating the remaining
> slirp4netns containers to pasta on aevion.
> **Last updated:** 2026-04-18
> **Status: ✅ COMPLETE** — all 48 running containers are now on pasta
> (except `node-exporter`, which intentionally runs with `--network host` so
> it can read host-level metrics).
>
> This document explains **why** we migrated, **which** containers were in
> scope, and **how** each migration was done. Kept for historical context
> and as a runbook if we ever need to migrate the opposite way or migrate
> a new slirp4netns container.
> Read [`docs/DNS_ARCHITECTURE.md`](./DNS_ARCHITECTURE.md) first if you haven't
> already — it explains the DNS-path constraints this migration satisfies.

---

## 1. Why migrate at all?

### 1.1 DNS (the proximate trigger)

The current DNS architecture (Fix 2, April 2026) sets:

```toml
[network]
pasta_options = ["--dns-host", "192.168.1.105"]

[containers]
dns_servers = ["169.254.1.1"]
```

`169.254.1.1` is **pasta's** in-namespace DNS intercept address. Slirp4netns
has no equivalent intercept — DNS queries to `169.254.1.1` from a
slirp4netns container just time out. So as long as a container uses
slirp4netns, its DNS path either:

- **Accidentally works** (old resolv.conf from before the
  `containers.conf` change — `nameserver 192.168.1.105`, NATed through the
  host's stack to AGH). This is where most current slirp4netns containers
  are today.
- **Breaks on next recreate** (new resolv.conf → `nameserver 169.254.1.1`
  → slirp4netns has no intercept → timeout).

Migrating to pasta eliminates that latent bug: pasta containers on aevion
all get the same, well-defined DNS path.

### 1.2 Performance (the older motivation)

Pasta is ~8× faster than slirp4netns for TCP throughput on this hardware
(measured during the nginx proxy tuning work). For services that move
significant traffic (video streaming, large file syncs, etc.) this matters.

### 1.3 Consistency

Having one networking driver across the stack reduces the number of
"container quirks" we need to remember. Every setup script looks the same,
every `podman inspect` looks the same, and the security-practices rule has
only one case to document.

---

## 2. What we are migrating

### 2.1 Containers on slirp4netns today (migrate these)

Verified via `podman inspect <c> --format '{{.HostConfig.NetworkMode}}'`
on 2026-04-18 before the migration.

| Container | Host-loopback need | Post-migration mode | Status |
|-----------|--------------------|---------------------|--------|
| `nitter` | **None** — image is `nitter-self-contained`, bundled redis | `pasta` (no loopback) | ✅ migrated |
| `goatsync` | Postgres-vector + Redis on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated |
| `grafana` | Scrapes Prometheus on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated |
| `prometheus` | Scrapes cadvisor, node-exporter, podman-exporter on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated — all 4 targets UP |
| `piped-api` | Postgres on host, bg-helper on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated |
| `wger-web` | Postgres-vector + Redis on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated (also: removed stale `User=1001`/`Group=1001`, fixed image drift `quay.io`→`docker.io`, corrected port 8000→8051) |
| `wger-celery-worker` | Postgres-vector + Redis on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated |
| `wger-celery-beat` | Postgres-vector + Redis on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated (also: removed stale `User=1001`/`Group=1001`, fixed image drift) |
| `jellystat` | Postgres on host | `pasta:--map-host-loopback,10.0.2.2` | ✅ migrated — live container was stale slirp4netns; script was already pasta. Recreate sufficed. |

Setup scripts whose live containers aren't running right now but still
carry slirp4netns and should be updated at the source:

| `podman-setup.sh` file | Notes |
|------------------------|-------|
| `apps/immich/podman-setup.sh` | Both `immich-server` and `immich-machine-learning` — container is not running today but the script will respawn on slirp4netns. |
| `apps/open-webui/podman-setup.sh` | Was running, not running today — update anyway so next install uses pasta. |
| `apps/piped/podman-setup.sh` (the shell fallback path) | The active quadlet is `.container`, but the legacy shell path in the script still has slirp4netns. Clean up while we're here. |

### 2.2 AdGuardHome (already on pasta — no migration needed)

`apps/adguardhome/podman-setup.sh` explicitly sets `--network pasta` (see
the big comment block at lines 20-45). The **committed quadlet file**
`apps/adguardhome/adguardhome.container` is **stale** (it still says
`Network=slirp4netns:port_handler=slirp4netns`) because it was not
regenerated after the setup script switched to pasta. The live container
on aevion uses pasta.

**Action:** next time we run `apps/adguardhome/podman-setup.sh`, the
quadlet will be regenerated from the current `podman run` invocation and
committed correctly. For now, no functional change needed; just fix the
stale file at the end of this migration.

Note: AGH preserves real LAN client IPs on inbound port 53 queries because
pasta's default behavior already passes real source IPs (unlike
slirp4netns's default `port_handler=rootlesskit`, which NATs). No special
pasta flag required.

### 2.3 Containers we are deliberately leaving on slirp4netns

| Container | Why we don't migrate |
|-----------|----------------------|
| `tailscale` | Currently failing to start (exit 125) and runs as part of a pod (`adguard-tailscale`). Needs `NET_ADMIN` + `/dev/net/tun` + userns quirks. The pod definition is the right place to fix network mode if/when tailscale is revived. Out of scope for DNS fix. |

### 2.4 Not migrating: `wger-db`, `wger-cache`

These are defined in `apps/wger/podman-setup.sh` but the active deployment
uses the shared `postgres-vector` and `redis` instances instead. They don't
need a network-mode change because they aren't running. Update their
stale `.container` quadlets for consistency anyway (one-line fixes) so a
future `wger-db` / `wger-cache` deployment is consistent.

### 2.5 Stale quadlet files to refresh (no live change)

These containers' live state is already pasta, but their committed
`.container` quadlets still say `slirp4netns`. They will be overwritten
next time their `podman-setup.sh` runs. List so we don't miss them:

- `apps/adguardhome/adguardhome.container`
- `apps/libremdb/libremdb.container`
- `apps/libmedium/libmedium.container`
- `apps/anonymousoverflow/anonymousoverflow.container`

### 2.6 Already on pasta (no work)

Everything else. Notable examples: `jellyfin`, `audiobookshelf`,
`navidrome`, `redlib`, `libmedium`, `priviblur`, `qbittorrent`, the `*arr`
stack, `seerr`, `nginx`, `cadvisor`, `postgres-vector`, `redis`,
`flaresolverr`, `actual-budget`, `paperless-ngx`, `speedtest-tracker`,
`syncthing`, etc.

---

## 3. The migration pattern (what to change)

Every slirp4netns container we're migrating today uses the same form:

```bash
--network slirp4netns:allow_host_loopback=true
```

Replace with the equivalent pasta form:

```bash
--network 'pasta:--map-host-loopback,10.0.2.2'
```

### 3.1 Why this exact replacement preserves behavior

| Property | `slirp4netns:allow_host_loopback=true` | `pasta:--map-host-loopback,10.0.2.2` |
|----------|----------------------------------------|--------------------------------------|
| How the container reaches host loopback | Via gateway `10.0.2.2` (slirp4netns NATs to host's `127.0.0.1`) | Via `10.0.2.2` (pasta maps this specific address to host loopback) |
| Address the service code connects to | `10.0.2.2:<port>` | `10.0.2.2:<port>` — same |
| DNS intercept at `169.254.1.1` | **No** — must use other DNS paths | **Yes** — pasta's `--dns-forward` |
| Throughput | ~0.5 MB/s observed | ~4–6 MB/s observed |
| Host loopback port exposure | All ports | All ports (same trade-off — see [`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md)) |

Since the service code already hard-codes `10.0.2.2` as the host address
(see comments in `apps/wger/podman-setup.sh` lines 122-125 and
`apps/goatsync/podman-setup.sh`), **no service-level config changes are
required**. It's a pure network-mode change.

### 3.2 What each migration involves

Per container:

1. Edit `apps/<svc>/podman-setup.sh` — replace the `--network` line.
2. Edit `apps/<svc>/<svc>.container` (the quadlet) if one exists — replace
   the `Network=` line. (podlet will regenerate this on re-run, but
   keep the committed copy in sync so reviewers see the intent.)
3. On aevion: `cd ~/selfhost/apps/<svc> && bash podman-setup.sh run`
4. Verify:
   - `podman inspect <svc> --format '{{.HostConfig.NetworkMode}}'` →
     `pasta`
   - DNS from inside: `podman exec <svc> getent hosts google.com` returns
     a result quickly (< 100 ms)
   - Service's own health check still passes (endpoint returns 200,
     UI loads, etc.)
   - Service can still reach its host-side dependency (e.g., can still
     talk to postgres on `10.0.2.2:5432`).

### 3.3 Rollback (per container)

If the pasta migration breaks a specific service:

1. Revert the `podman-setup.sh` and `<svc>.container` changes for that
   service only.
2. Re-run `podman-setup.sh` — slirp4netns is reinstated for that service.
3. **Accept** that the service will revert to the old DNS path
   (`nameserver 192.168.1.105`, working via NAT). That's fine — it's the
   state that service was in before this migration.
4. File an issue with what broke so we can revisit with better context.

---

## 4. Per-container runbook

Do these in order. After each one, verify before moving on. **Do not batch.**

### 4.1 `nitter`

**Expected risk:** minimal. Stateless, one container, just needs Redis.

```bash
# On dev machine
cd /path/to/SelfHost
# Edit apps/nitter/podman-setup.sh: slirp4netns:allow_host_loopback=true
#  → pasta:--map-host-loopback,10.0.2.2
# Edit apps/nitter/nitter.container: Network=slirp4netns:allow_host_loopback=true
#  → Network=pasta:--map-host-loopback,10.0.2.2
# Commit.

# On aevion
cd ~/selfhost/apps/nitter
git pull && bash podman-setup.sh run
```

**Verify:**

```bash
podman inspect nitter --format '{{.HostConfig.NetworkMode}}'       # pasta
podman exec nitter getent hosts google.com                          # resolves quickly
curl -sSI http://127.0.0.1:8043/ | head -3                          # 200 or redirect
# Load a Twitter profile via Nitter in a browser to sanity-check Redis path.
```

### 4.2 `goatsync`

**Expected risk:** low. Postgres + Redis dependency.

Same pattern as `nitter`. After migration, verify by triggering a sync and
watching `podman logs goatsync` for `connect` failures.

### 4.3 `grafana`

**Expected risk:** low. Scrapes Prometheus on host. Has existing dashboards.

Same pattern. After migration, open the Grafana UI, confirm dashboards
still show data from Prometheus.

### 4.4 `prometheus`

**Expected risk:** low. Scrapes cadvisor/node-exporter/podman-exporter on
host loopback.

Same pattern. After migration, visit `http://127.0.0.1:8003/targets` and
confirm all targets are `UP`.

### 4.5 `piped-api`

**Expected risk:** low-medium. Part of piped stack (api + proxy +
frontend + bg-helper). Only `piped-api` is on slirp4netns.

Same pattern. After migration, load the piped UI and play a video to
sanity-check api ↔ proxy path.

### 4.6 `wger-web`, `wger-celery-worker`, `wger-celery-beat`

**Expected risk:** medium. Three containers, share one codebase.

All three use `slirp4netns:allow_host_loopback=true`. Change all three in
`apps/wger/podman-setup.sh` in the same commit. Also update:

- `apps/wger/wger-web.container`
- `apps/wger/wger-celery-worker.container`
- `apps/wger/wger-celery-beat.container`
- `apps/wger/wger-db.container` (not running, but keep it consistent)
- `apps/wger/wger-cache.container` (same)

Re-run `apps/wger/podman-setup.sh` on aevion.

Verify the web UI loads, that logging into the admin works, and that a
workout log saves (exercises celery + db path).

### 4.7 `jellystat`

**Special case — the script already uses pasta.** The live container is
stale from before the script was fixed. Just force a recreate:

```bash
cd ~/selfhost/apps/jellystat
bash podman-setup.sh run
```

After the recreate, confirm `podman inspect jellystat --format '{{.HostConfig.NetworkMode}}'`
returns `pasta`. This one is effectively "free" — no new edits required.

### 4.8 `immich-server`, `immich-machine-learning`

**Expected risk:** unknown — service is not running on aevion today.

Update `apps/immich/podman-setup.sh` preemptively so the next install is
pasta. Do **not** deploy unless you're actively bringing Immich back up
(in which case that's a bigger project and this migration is a minor
part of it).

### 4.9 `open-webui`

**Expected risk:** low. Not running today. Update
`apps/open-webui/podman-setup.sh` and `apps/open-webui/open-webui.container`
preemptively.

---

## 5. Post-migration cleanup

Once every migrated service is verified on pasta:

- Update [`docs/DNS_ARCHITECTURE.md`](./DNS_ARCHITECTURE.md) §7.1 —
  delete or thin out the "slirp4netns containers to migrate" list.
- Update [`.cursor/rules/security-practices.mdc`](../.cursor/rules/security-practices.mdc) §
  "Container Networking & Host Loopback Access" — drop the slirp4netns
  row from the "current approach" table, keep it only as a historical
  note (AGH still uses it).
- Delete the "Slirp4netns (legacy)" blocks from each migrated
  `podman-setup.sh` if they're still there as commented-out alternatives.
- Consider removing any unused slirp4netns-related machinery from
  `scripts/common.sh` (none as of 2026-04-18, but check).

---

## 6. FAQ

### Why not just set `Network=pasta` (default) everywhere and drop the loopback flag entirely?

Because these services genuinely need to reach the host's `127.0.0.1:*` —
Postgres, Redis, Prometheus scrape targets, etc. Default pasta does
**not** give that access (Podman passes `--no-map-gw` to disable pasta's
built-in gateway-loopback mapping). `--map-host-loopback,10.0.2.2` restores
that access at a well-known address.

Eventually we might replace host-loopback with Podman bridge networks (each
service-pair on its own isolated bridge, no host loopback involvement at
all). That's a much bigger change — see
[`docs/HOST_LOOPBACK_SECURITY.md`](./HOST_LOOPBACK_SECURITY.md).

### Does the migration break anything for clients (browsers, Tailscale peers)?

No. `-p 127.0.0.1:<port>:<port>` port forwarding is identical between
slirp4netns and pasta. Clients never notice the change. Only the
container-internal view changes.

### What about port_handler=slirp4netns (real client IPs)?

Pasta supports preserving real client IPs too (it's the default, actually —
slirp4netns only breaks it in `port_handler=rootlesskit` mode). No
special flag needed.

### The migration left the `-static` container (or similar) on default pasta — is that fine?

Yes. Containers that do **not** need host loopback should stay on default
pasta — it's the most isolated and doesn't carry the "all host loopback
ports exposed" trade-off. `wger-static` just serves static files; no
host-side dependency.
