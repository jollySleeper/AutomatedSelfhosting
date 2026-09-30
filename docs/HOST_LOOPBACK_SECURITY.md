# Host Loopback Security Analysis

> **Status:** design doc — no action taken yet.
> **Audience:** future-you deciding how to harden the selfhost stack, plus
> any LLM you hand this to for context.
> **Last updated:** 2026-04-18
> **Scope:** strictly the host-loopback exposure issue. Supply-chain attacks,
> container hardening (seccomp/caps/readonly), and LAN/WAN firewalling are
> adjacent concerns and are called out but not solved here.
>
> ## TL;DR
>
> 18 containers currently run with `--map-host-loopback,10.0.2.2`, which
> grants them access to **every** host-loopback-bound port on the server
> (≈40 services). If any one of these 18 containers is compromised, the
> attacker can reach Postgres, Redis, Jellyfin, qBittorrent, the `*arr`
> stack, etc. — all of which trust loopback callers implicitly.
>
> The fix with the best risk/effort ratio is **Option 2 (Podman bridge
> networks, phased migration)**. Start with the `db` family (Postgres,
> Redis, and their consumers), because that's the highest-value target
> and the smallest blast radius.
>
> Do **not** adopt this as a big-bang rewrite. Adopt it one service-family
> at a time, each in its own PR, each with its own rollback. See
> [§7. Phased rollout](#7-phased-rollout) for the plan.

---

## 1. The concrete concern

As originally noted:

> We have to map the host to containers even if we need a single port as
> all of our container ports are mapped to `127.0.0.1` of our bare metal
> server. And even if a container is compromised then it has all the ports
> exposed on containers. What can we do about it?

Expanded:

1. Every service on aevion binds to `127.0.0.1:<port>` on the host (this
   is correct and deliberate — it avoids LAN exposure).
2. Containers that need to reach another service on the host open a
   "hole" by adding `--map-host-loopback,10.0.2.2` (for pasta) or
   `slirp4netns:allow_host_loopback=true` (historical).
3. Neither pasta nor slirp4netns has a knob to restrict which host
   loopback **ports** the container can reach. It's all-or-nothing:
   with `--map-host-loopback`, the container sees **every** host
   loopback-bound port at `10.0.2.2:<port>`.
4. Therefore a compromise of any such container ≈ a compromise of every
   loopback-bound service.

This is called out in [`.cursor/rules/security-practices.mdc`](../.cursor/rules/security-practices.mdc)
§ "Container Networking & Host Loopback Access" ("security limitation"
paragraph). The rule correctly notes the risk is **accepted** today
because the server is on a private LAN behind Tailscale. This document
explores **reducing** that accepted risk.

## 2. Threat model

### 2.1 What we're worried about

- **Supply-chain compromise** of one container image we pull
  (`docker.io/*`, `ghcr.io/*`, `quay.io/*`). A malicious image update, or
  a typo-squat pull, gives an attacker RCE inside that container.
- **Vulnerability in an app** running in one container (unpatched CVE in
  the container's main process — think Grafana RCE, Prometheus RCE,
  qBittorrent RCE, wger/Django RCE, etc.).
- **Misconfigured exposure** — a container accidentally bound to a LAN
  IP instead of loopback, then compromised from the LAN.

### 2.2 What we're **not** worried about here

- **Network-level attackers on the public internet** — the server is
  not directly reachable. External access is Tailscale-only.
- **LAN-side attackers** — separate concern, mitigated by (a) binding to
  127.0.0.1 on the host and (b) basic LAN hygiene. Not addressed by this
  doc.
- **Side channels / kernel vulns** — out of scope; would require VMs or
  microVMs (Firecracker, Kata) which is a much bigger project.
- **Root-on-host attackers** — already game-over regardless of container
  networking. Rely on distro hardening + `legion` being a rootless user.

### 2.3 The blast radius we want to shrink

If container X is compromised, what can the attacker reach from
**inside** container X's network namespace?

- **Today**, with `--map-host-loopback`: all of 10.0.2.2:<any port>,
  which includes Postgres, Redis, Jellyfin's API, qBittorrent's Web UI,
  the `*arr` APIs with their API keys, Prometheus, etc.
- **Goal**: only the specific services X legitimately needs to talk to.

## 3. Current state (as of 2026-04-18)

### 3.1 Containers with full host-loopback access

Post-slirp4netns→pasta migration (see
[`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](./SLIRP4NETNS_TO_PASTA_MIGRATION.md)),
these containers still have `--map-host-loopback,10.0.2.2`:

| Container | What it needs to reach | Current blast radius |
|-----------|------------------------|----------------------|
| `nginx` | All backends (reverse proxy) | **All** host loopback ports |
| `prowlarr`, `radarr`, `sonarr`, `lidarr`, `readarr` | qBittorrent @ 8061 | All host loopback ports |
| `seerr` | Jellyfin @ 8096, Radarr @ 8062, Sonarr @ 8065 | All host loopback ports |
| `jellystat` | Postgres-vector @ 5432, Jellyfin @ 8096 | All host loopback ports |
| `grafana` | Prometheus @ 9090 | All host loopback ports |
| `prometheus` | cadvisor @ 9091, podman-exporter @ 9882 | All host loopback ports |
| `goatsync`, `piped-api`, `wger-web`, `wger-celery-worker`, `wger-celery-beat` | Postgres-vector @ 5432, Redis @ 6379 | All host loopback ports |
| `immich-server`, `immich-machine-learning` (not currently running) | Postgres @ 5432, Redis @ 6379 | All host loopback ports |
| `open-webui` (not currently running) | Ollama on host | All host loopback ports |

Total: **17 running** + 3 stopped = **20 containers** with full
loopback access. Each is a potential pivot point.

### 3.2 Containers that don't have loopback access

Everything else (~30 containers — `jellyfin`, `audiobookshelf`,
`navidrome`, `qbittorrent`, all privacy frontends, `redis`,
`postgres-vector`, etc.). These **listen for** connections but don't
**initiate** them to the host. Even if compromised, they can't reach
host-bound backends. This is the smaller-attack-surface state we want
everyone to be in.

### 3.3 What the "crown jewels" are

| Service | Why it matters | Currently exposed to |
|---------|---------------|----------------------|
| `postgres-vector` @ 5432 | Shared database for goatsync, piped, wger, immich, qdrant… | All 17 loopback-mapped containers |
| `redis` @ 6379 | Shared cache + sessions | Same |
| `qbittorrent` @ 8061 | Web UI → can add torrents, change save paths | Same |
| `jellyfin` @ 8096 | API keys, user data | Same |
| `*arr` API endpoints | API keys stored in clear, can reconfigure download clients, access media libraries | Same |

Postgres and Redis are the biggest concern — they're trusted backends
with no fine-grained per-client authn (Redis has no auth at all; Postgres
only has password auth, and some apps share DBs).

## 4. Options (with actual numbers attached)

### Option 1 — Accept the status quo

> Do nothing. Document the risk. Rely on LAN + Tailscale + not running
> dodgy containers.

- **Effort:** zero.
- **Blast radius on compromise:** 17 containers × full loopback = full
  stack.
- **When to choose this:** only if the other options are net-negative
  (too much effort for a self-hosted personal stack). The current rule
  documentation accepts this trade-off, so this is the **de facto**
  position until something changes.

### Option 2 — Podman bridge networks (internal, per service family)

> Create one `podman network` per service family. Backend services
> (Postgres, Redis, cadvisor, etc.) join the relevant network. Client
> containers join the same network. Drop `--map-host-loopback` from
> clients. Stop binding backends to `127.0.0.1` on the host (they'll be
> reachable **only** from containers on that network).

Example networks:

- `db_net`: `postgres-vector`, `redis`; clients: `goatsync`, `piped-api`,
  `wger-*`, `immich-*`, `paperless-ngx`, `actual-budget`, etc.
- `monitoring_net`: `prometheus`, `cadvisor`, `podman-exporter`,
  `grafana`
- `arr_net`: `qbittorrent`, `prowlarr`, `radarr`, `sonarr`, `lidarr`,
  `readarr`, `flaresolverr`
- `media_net`: `jellyfin`, `seerr`, `jellystat`, `audiobookshelf`

Backend services get DNS-registered on each network they join (pod-dns:
`postgres-vector.dns.podman` or similar). Clients use service names
instead of `10.0.2.2:<port>`.

**How it reduces blast radius:**

If `goatsync` is compromised, it can only reach services on `db_net`
(postgres-vector, redis, and its sibling clients). Cannot reach
qBittorrent, Jellyfin, Grafana, etc.

- **Effort:** moderate. Each service family = 1 PR:
  1. `podman network create db_net`
  2. Change `podman-setup.sh` of backend service: drop host-port bind,
     add `--network db_net`.
  3. Change clients: drop `--map-host-loopback`, add `--network db_net`,
     update connection string from `10.0.2.2:5432` to `postgres-vector:5432`.
  4. Regenerate quadlets (they need `Network=db_net.network`).
  5. Verify end-to-end.
- **Downside:** config-drift surface — every consumer needs its
  connection-string env var updated. Miss one and it breaks silently.
- **Downside:** backend services are no longer accessible from the host
  (`psql -h 127.0.0.1` stops working unless you also publish to host).
  Workaround: keep a host-side port binding for admin (`-p
  127.0.0.1:5432:5432`) **in addition to** the bridge network. You get
  both: localhost access for admin, isolated network for container-to-
  container.
- **Estimate:** 4 families × ≈4 hours each = ~16 hours of work spread
  across 4 PRs. Each individually rollbackable.
- **When to choose this:** if you want real segmentation and are
  willing to commit a weekend. **Recommended.**

### Option 3 — Podman pods (shared netns within a family)

> Group services that talk to each other into a Podman pod. Pods share a
> network namespace; intra-pod communication is via `127.0.0.1:<port>`.
> Inter-pod communication goes through published ports.

Example: one pod for `wger`:
- `wger-web`, `wger-celery-worker`, `wger-celery-beat` all in the same
  pod. They already share a config (they have to see the same Postgres
  and Redis).
- The pod publishes `127.0.0.1:8051:8000` for wger-web.
- If Postgres is also in the pod, they reach it at `127.0.0.1:5432`.
  No host-loopback mapping needed.

**Pros:**

- Simple mental model (everything in a pod is trusted).
- Nice for tightly-coupled stacks (web + worker + beat).

**Cons:**

- Doesn't help cross-pod dependencies (e.g., prowlarr in one pod needs
  qBittorrent in another pod — still need loopback or bridge network).
- Podman pods force **one shared network namespace**, so port conflicts
  inside a pod are fatal.
- Postgres-vector is used by many unrelated services, so you can't easily
  group "all things that use Postgres" into one pod.
- **Recommended only for genuinely tightly-coupled services** (wger,
  immich, piped). Doesn't solve the general problem.
- **Effort:** low per pod, but narrow applicability.

### Option 4 — Unix sockets for Postgres/Redis

> Bind Postgres and Redis to unix sockets instead of (or in addition to)
> TCP. Mount the socket directory into clients. No network involvement
> at all.

**Pros:**

- No network access → no way for a compromised client to scan for other
  services.
- Fastest possible local IPC.

**Cons:**

- Not all clients support unix sockets easily (some Python/Node drivers
  do, some don't).
- Bind-mount permissions become the new access-control mechanism —
  requires `run.oci.keep_original_groups=1` + matching GIDs between
  backend and client containers. Same hassle we've had with the userns
  setup (see `TODO_FIX_USER_PERMISSIONS`).
- Connection strings change: `postgres://user:pass@/dbname?host=/run/postgresql`
  vs. `postgres://user:pass@postgres-vector:5432/dbname`. Some apps'
  config files don't support the unix-socket form.
- **When to use:** great for Postgres if the apps support it. Less
  convenient for Redis because node_redis and similar are less friendly
  to unix sockets.
- **Effort:** medium per backend (reconfigure Postgres to listen on
  socket, change all client connection strings, set up volume-mount
  permissions). Likely incompatible with some clients. Probably not
  worth it as a first-line defense when bridge networks exist.

### Option 5 — In-container nftables egress filter

> Install `nftables` inside each client container; at startup, add rules
> that block all egress **except** to the specific
> `10.0.2.2:<allowed-ports>`.

**Pros:**

- Very targeted; doesn't change any architecture.
- Can be applied per-container without touching backends.

**Cons:**

- Requires `NET_ADMIN` inside the container, or at least `CAP_NET_ADMIN`
  for the init process. That's a **security regression** — we granted
  broader capabilities just to add egress rules.
- The rules live inside the container → a compromised root inside the
  container can drop them. The attack surface model is wrong.
- Doesn't scale: 17 containers × custom nftables rulesets to maintain.
- **Verdict:** reject. Wrong abstraction layer.

### Option 6 — Host-level nftables that restricts container sources

> Set up nftables rules on the host (in `legion`'s user namespace, or
> rootful) that restrict which pasta-network source IPs can reach which
> host loopback destination ports.

**Pros:**

- No changes to containers.
- One rule-set, centrally managed.

**Cons:**

- Pasta assigns each container a private address when it starts; the
  address is deterministic per-run but not documented as an API.
  Building rules that reference those addresses is brittle — any pasta
  version bump could shift them.
- nftables in user namespaces has limitations; might need to run
  nftables rootful, which adds a system-level cron/systemd unit we'd
  have to maintain.
- Managing rules for 48+ containers is a real ops burden.
- **Verdict:** defer. Heavy operational cost; Option 2 is strictly better
  for comparable blast-radius reduction.

### Option 7 — Kubernetes (K3s) with NetworkPolicies

> Migrate the whole stack to K3s. Use Cilium/Calico NetworkPolicy
> resources to specify which pod can talk to which pod on which port.
> Declarative, enforceable, and aligns with the separate goal of
> learning K3s.

**Pros:**

- Proper industry-standard segmentation.
- Denial-by-default NetworkPolicies with explicit allows.
- Future-proof (you're learning K8s).
- Applies to every dimension: host loopback, inter-pod, inter-namespace.

**Cons:**

- Massive lift. We'd be re-platforming 48+ containers to Helm charts or
  plain manifests.
- Learning curve while also maintaining production.
- K3s on a single-node ARM64 ODROID/OrangePi has some resource overhead
  (not terrible on modern SBCs, but non-trivial).
- Also solves many other problems (secrets management, RBAC, upgrades),
  so if we're already planning to do it, it subsumes this concern.
- **When to choose this:** as the long-term plan. Don't use it to fix
  **only** the host-loopback issue — that's overkill.

### Option 8 — Harden the current setup, accept the residual risk

> Keep loopback mapping, but reduce the probability of compromise:
>
> - Pin container images to digests (not `:latest`).
> - Run images through a vulnerability scanner (trivy, grype) on a cron.
> - Run containers with `--read-only` + tmpfs for /tmp.
> - Drop all capabilities and whitelist only what each service needs.
> - Use Podman secrets instead of env-var passwords.
> - Tailscale ACLs: restrict which Tailscale nodes can reach the server.
>
> None of these address the loopback issue itself, but they reduce the
> chance of a container **getting** compromised in the first place.

- **Effort:** incremental. Can be done in parallel with Option 2.
- **Verdict:** **always do this anyway**, regardless of which other
  option you pick. This is table stakes hygiene.

## 5. Recommendation

**Go with Option 2 (Podman bridge networks), phased.** Also do
Option 8 (image pinning, capability dropping, Podman secrets) as
independent parallel work — it doesn't depend on or block Option 2.

Revisit Option 7 (K3s) once you've learned it separately, at which
point you can migrate the whole thing. Until then, bridge networks are
the incremental, reversible, testable way to shrink blast radius.

### Why not Options 3/4/5/6?

- Option 3 (pods) is fine for specific tightly-coupled groups (wger,
  immich, piped) but doesn't solve the Postgres/Redis sharing problem.
  Use it **within** Option 2 where it makes sense (e.g., put
  `wger-web` + workers in one pod, then have that pod join `db_net`).
- Option 4 (unix sockets) is promising for Postgres specifically, but
  requires per-client support. Revisit as a per-client optimization once
  Option 2 is in place.
- Option 5 (in-container nftables) is the wrong abstraction — attacker
  deletes the rules.
- Option 6 (host nftables) has too much operational overhead for its
  benefit; Option 2 is cleaner.

## 6. Blast-radius math after Option 2

Imagine we've implemented Option 2 with these networks:

- `db_net`: postgres-vector, redis, goatsync, piped-api, wger-*,
  immich-*, paperless-ngx (when deployed), actual-budget (if using
  redis/postgres)
- `monitoring_net`: prometheus, cadvisor, podman-exporter, grafana,
  (eventually loki, alertmanager)
- `arr_net`: qbittorrent, prowlarr, radarr, sonarr, lidarr, readarr,
  flaresolverr
- `media_net`: jellyfin, seerr, jellystat, audiobookshelf
- Plus: nginx stays on `--map-host-loopback` because it reverse-proxies
  to everything. (It's the "crown jumphost.")

New blast radius per compromised container:

| Compromised container | Can still reach (via its networks) | Cannot reach |
|------------------------|-----------------------------------|--------------|
| `goatsync` (in `db_net`) | postgres-vector, redis, wger-*, piped-api, etc. | jellyfin, qbittorrent, *arr APIs, prometheus |
| `grafana` (in `monitoring_net`) | prometheus, cadvisor, podman-exporter | everything else |
| `radarr` (in `arr_net`) | qbittorrent, prowlarr, etc. | postgres, redis, jellyfin |
| `nginx` (keeps loopback) | everything (same as today) | (nothing reduced — but nginx is simpler to audit/pin than 17 containers) |

So the blast radius goes from "compromise any of 17 containers = reach
anything" to "compromise a specific family = reach only that family."

Nginx remains the single point of aggregation, which is fine — it's one
well-known high-value target that's easier to lock down (pinned image,
read-only configs, minimal dependencies) than 17 general-purpose app
containers.

## 7. Phased rollout

Do **not** do all of this in one change. Do one service-family per PR,
each verified end-to-end before moving on.

### Phase 1: `db_net` (highest value, smallest clients)

**Scope:** `postgres-vector`, `redis`, `goatsync`, `piped-api`,
`wger-*`, `actual-budget` (if applicable), `paperless-ngx` (if it uses
shared pg).

**Steps:**

1. Create the network: `podman network create db_net`.
2. Update `apps/postgres-vector/podman-setup.sh`:
   - Add `--network db_net`.
   - Keep `-p 127.0.0.1:5432:5432` so host-side admin tools still work
     (optional — drop it if you use the postgres container itself for
     admin).
   - Regenerate quadlet.
3. Same for `apps/redis/podman-setup.sh`.
4. For each client service:
   - Add `--network db_net` (can coexist with `pasta:--map-host-loopback`
     temporarily during the migration).
   - Change connection string env var from `10.0.2.2:5432` →
     `postgres-vector:5432` (pasta's Podman DNS handles the name
     resolution).
   - Deploy, verify.
   - Remove `--map-host-loopback` from the client's network spec.
   - Deploy, verify again (make sure it still works with only `db_net`).
5. Document the network in
   [`.cursor/rules/security-practices.mdc`](../.cursor/rules/security-practices.mdc)
   "Container Networking" section.

**Estimate:** one Saturday.

**Rollback:** revert the PR. Each client keeps working because it still
has loopback mapping during the migration period.

### Phase 2: `monitoring_net`

Small, self-contained. `prometheus`, `cadvisor`, `podman-exporter`,
`grafana`. Prometheus scrape config uses container DNS names
(`cadvisor:9091`) instead of `10.0.2.2:9091`.

**Watch out for:** `node-exporter` runs with `--network host` so it can
see host metrics. Leave it as-is — Prometheus can still scrape it via
`10.0.2.2:9100` or just use `127.0.0.1:9100` from the host perspective
(since node-exporter IS the host network).

**Estimate:** half a Saturday.

### Phase 3: `arr_net`

`qbittorrent` + all `*arr` + `flaresolverr`. Medium complexity — the
*arr apps store qBittorrent's URL in their config file, not an env var,
so you'll need to update the config file to say `qbittorrent:8080`
instead of `http://10.0.2.2:8061`.

**Watch out for:** qBittorrent port mapping — do not drop its host-side
port bind for `-p 127.0.0.1:8061:8080` (you still want the Web UI
accessible from the LAN via nginx).

**Estimate:** one Saturday.

### Phase 4: `media_net`

`jellyfin` + `seerr` + `jellystat` + maybe `audiobookshelf`. Jellyfin's
API URL is stored in seerr and jellystat configs — update to use
`jellyfin:8096`.

**Watch out for:** Jellyfin's discovery and streaming features may
expect specific ports; test playback, not just "HTTP 200 on /health."

**Estimate:** half a Saturday.

### Phase 5: Review & cleanup

- Remove `--map-host-loopback` from every container where it's no
  longer needed.
- Update `docs/DNS_ARCHITECTURE.md` and
  `.cursor/rules/security-practices.mdc` to note that only nginx still
  uses `--map-host-loopback`.
- Consider: does nginx really need loopback to all 30 backends, or can
  we also move it to the family networks? (It can — nginx can join
  multiple networks. It becomes `nginx` in `db_net`, `monitoring_net`,
  `arr_net`, `media_net`. Then even nginx doesn't need
  `--map-host-loopback`.) This is the final-form Option 2.

## 8. What about the stuff that isn't a service family?

Some services are loners and don't fit a family. Options:

- **Create a tiny family for them:** `priviblur`, `redlib`, `dumb`,
  `quetre`, etc. don't talk to any host service — they only make
  outbound HTTPS. They can run on **plain pasta** (no loopback, no
  bridge network). Already done for most.
- **A single `misc_net` for everything else:** don't do this. Defeats
  the point (a compromise on misc_net = reach all other misc_net
  services).
- **`--network pasta` (no loopback)** is the right answer for any
  container that only makes outbound internet requests and receives
  inbound via nginx. We already migrated nitter, adguardhome, libremdb,
  libmedium, anonymousoverflow, etc. to this pattern. Keep applying it
  as new services are added.

## 9. Parallel hardening (do this regardless)

These don't solve the loopback problem but reduce compromise probability:

1. **Pin image tags to digests.** Bad update of `ghcr.io/foo/bar:latest`
   is a realistic attack path. Pin `ghcr.io/foo/bar@sha256:abc...`.
   Automate digest lookup via `io.containers.autoupdate=registry` + a
   renovate-style tool, or accept manual tracking.
2. **Run vulnerability scans on pulled images** via trivy or grype on a
   weekly cron. Prioritize the loopback-exposed containers first.
3. **Drop all capabilities, re-add what's needed.** `--cap-drop=ALL`
   + `--cap-add=` for specific services. Most apps don't need any caps.
4. **`--read-only` root filesystem + specific writable tmpfs mounts.**
   Prevents an attacker from modifying the container at runtime.
5. **Podman secrets instead of env-var passwords.** Already on the
   to-do list. Do it.
6. **`no-new-privileges` security opt.** Already default in rootless
   podman, but double-check: `podman inspect <c> --format
   '{{.HostConfig.SecurityOpt}}'` should show it.
7. **Tailscale ACLs.** Restrict which of your tailnet devices can
   access aevion, and on which ports. E.g., your laptop can reach
   everything; a friend's phone (if you add them to your tailnet) can
   only reach Jellyfin.

## 10. Decision matrix

If you have 0 hours to spend right now:
- Do Option 1 (accept, documented) and revisit later.

If you have 4 hours:
- Do Phase 1 of Option 2 (`db_net`). Biggest payoff, smallest surface.

If you have a weekend:
- Do Phases 1-3 of Option 2. Covers the "crown jewels."

If you have a week and want to learn K3s anyway:
- Skip Option 2 entirely and do Option 7. Nothing wasted — the
  NetworkPolicies you'll write in K3s supersede bridge networks.

If you're not sure when you'll have time:
- Do Option 8 (hardening) in small chunks — that's always incremental
  and never wasted.

## 11. Related docs

- [`docs/DNS_ARCHITECTURE.md`](./DNS_ARCHITECTURE.md) — how DNS works in
  this stack, including `--dns-host` and `169.254.1.1`. Important
  prerequisite reading.
- [`docs/SLIRP4NETNS_TO_PASTA_MIGRATION.md`](./SLIRP4NETNS_TO_PASTA_MIGRATION.md)
  — the April 2026 migration that got us to a clean pasta-everywhere
  baseline. This doc assumes that baseline.
- [`.cursor/rules/security-practices.mdc`](../.cursor/rules/security-practices.mdc)
  — current security policies and accepted-risk notes. Update when any
  phase of Option 2 lands.
