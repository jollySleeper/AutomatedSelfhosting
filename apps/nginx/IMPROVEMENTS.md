# NGINX Setup — Improvement Recommendations

A prioritized backlog of improvements for the `apps/nginx` reverse proxy, based
on a full review of the current setup (July 2026). Each item lists **what**,
**why**, rough **effort**, **impact**, and **trade-offs** so you can pick what's
worth doing.

Context that shapes these recommendations:
- The server is LAN-only + Tailscale, no public internet exposure.
- nginx runs rootless (see `README.md`).
- Certs are self-signed; most access is over plain HTTP today.
- There is a recurring **config-drift** problem (server vs. repo).

Legend — Effort: 🟢 low (<1h) · 🟡 medium (a few hours) · 🔴 high (a day+).
Impact: ⭐ nice · ⭐⭐ solid · ⭐⭐⭐ significant.

---

## 1. Quick wins

### 1.1 Add a `50x.html` error page  🟢 ⭐
**What**: The retired stock config had `error_page 500 502 503 504 /50x.html`.
The current `default.conf` doesn't. Add a themed `html/50x.html` and wire
`error_page 502 503 504 /50x.html;` into the default server (and optionally
per-service), so a backend being down shows a friendly "service unavailable"
page instead of a raw nginx error.
**Why**: Better UX when a container is restarting/updating.
**Trade-off**: None meaningful.

### 1.2 Enable gzip globally  🟢 ⭐
**What**: `gzip` is only turned on inside `wger-web.conf`. Move a sensible
`gzip on;` + `gzip_types` (excluding `text/html`, which is always gzipped) into
the `http {}` block of `rootless/nginx.conf`, and drop the per-service copy.
**Why**: Smaller responses for all HTML/JSON/CSS/JS across every service; one
place to manage it.
**Trade-off**: Tiny CPU cost; negligible at this scale.

### 1.3 Apply security headers to services, not just the default server  🟢 ⭐⭐
**What**: `security-headers.conf` is only included by `default.conf` and
`home.conf`. Real services (Jellyfin, *arr, etc.) don't get them. Add a curated
header set (careful CSP — many apps need their own) either per-service or via a
lightweight `snippets/app-headers.conf`.
**Why**: Defense-in-depth for the apps people actually use.
**Trade-off**: A strict CSP breaks SPAs; use a permissive CSP or omit CSP for
apps and keep the framing/nosniff/referrer headers. Test per app.

### 1.4 Turn the deploy sequence into one script  🟢 ⭐⭐
**What**: Add a `deploy.sh` (or `mask` task) that `rsync --delete`s
`apps/nginx/configs/` to the server, runs `podman exec nginx nginx -t`, and only
then `nginx -s reload`. Abort on test failure.
**Why**: Directly attacks the drift problem (see §4) and prevents pushing a
broken config. `rsync --delete` also removes server files you deleted in the repo
(e.g. the `st.conf`/`404-page.conf` cleanup would have been automatic).
**Trade-off**: `--delete` is powerful — dry-run first (`rsync -n`).

---

## 2. TLS / certificates

### 2.1 Replace self-signed with a local CA (mkcert or step-ca)  🟡 ⭐⭐⭐
**What**: Every HTTPS vhost uses one self-signed cert, so browsers warn
constantly and HSTS/secure-cookie features are unusable. Stand up an internal CA
(`mkcert` for simplicity, or `step-ca` for a real internal PKI) and issue a
wildcard `*.aevion.lan` cert. Install the CA root on your devices once.
**Why**: No more cert warnings anywhere; unlocks HSTS, secure cookies, HTTP/2
push, and cross-origin isolation features some apps want.
**Trade-off**: Must distribute the CA root to each client device. `step-ca` is
more moving parts but supports ACME (auto-renew).

### 2.2 …or Let's Encrypt via DNS-01  🔴 ⭐⭐⭐
**What**: If you own a public domain, use a DNS-01 ACME challenge (e.g. via
`acme.sh`/Caddy/Traefik or certbot with a DNS plugin) to get real, publicly
trusted certs for internal hostnames without exposing anything.
**Why**: Publicly trusted certs, auto-renewing, zero client-side CA install.
**Trade-off**: Requires a real domain and a supported DNS provider; more setup
than a local CA. Overkill for a pure LAN if mkcert suffices.

### 2.3 Standardize HTTP→HTTPS across all services  🟡 ⭐⭐
**What**: Coverage is inconsistent — some vhosts have both an HTTP redirect and
an HTTPS block, some are HTTP-only. Once certs are trusted (2.1/2.2), give every
service the `http → 307 https` redirect + HTTPS block pattern (already in
`site-templates/https-template.conf`).
**Why**: Consistent, encrypted access everywhere.
**Trade-off**: Do this only *after* fixing certs, or you trade cert warnings for
worse UX. A few apps misbehave behind forced HTTPS — verify each.

---

## 3. Security hardening

### 3.1 Forward-auth SSO in front of sensitive apps  🔴 ⭐⭐⭐
**What**: Several exposed apps have weak or no auth (the *arr stack, qBittorrent
Web UI, AriaNg, systemd-switch — which can control your services!). Put
Authelia or Authentik in front via nginx `auth_request`, so these require a
central login.
**Why**: Biggest security upgrade available. `systemd-switch` especially is a
high-value target — anyone on the LAN/Tailscale can currently hit it.
**Trade-off**: New stateful service to run/maintain; some apps' own APIs need
bypass rules for their clients (e.g. Prowlarr↔*arr, mobile apps).

### 3.2 Enable rate limiting  🟢 ⭐⭐
**What**: `rate-limiting.conf` is written but disabled. Define the
`limit_req_zone`s in `nginx.conf` and apply a modest limit on the default server
and any auth endpoints.
**Why**: Blunts brute-force and scanner floods.
**Trade-off**: Too-aggressive limits break legitimate bursty apps; start loose
(e.g. 10r/s burst) and watch logs.

### 3.3 Persist and act on the security log  🟡 ⭐⭐
**What**: `suspicious-detection.conf` logs to `/tmp/security.log`, which is
tmpfs — wiped on every restart. Either ship it to Loki/Grafana (you already run
that stack) or bind-mount a persistent path. Optionally feed it to CrowdSec to
auto-ban repeat offenders.
**Why**: Retain evidence; enable alerting/banning.
**Trade-off**: Persistent logs use disk; CrowdSec is another service. Lower
priority given LAN/Tailscale scope.

### 3.4 Move nginx onto Podman bridge networks  🔴 ⭐⭐⭐
**What**: The stack-wide goal in `.cursor/rules/security-practices.mdc` and
`docs/HOST_LOOPBACK_SECURITY.md`: replace `--map-host-loopback,10.0.2.2` (which
exposes *every* host loopback port) with per-family bridge networks. nginx is
the key candidate since it talks to nearly everything.
**Why**: Shrinks blast radius from "compromised nginx ≈ all host services" to
"nginx ≈ only the backends it needs."
**Trade-off**: Significant re-architecture; backends must move off host loopback
too. Read the design doc first — this is a phased, stack-wide effort.

---

## 4. Maintainability & drift prevention

### 4.1 Make git the single source of truth  🟡 ⭐⭐⭐
**What**: This review found **bi-directional drift**: 5 configs existed only on
the server (`beaverhabits`, `qwiklip`, `speedtest`, `st`, `systemd-switch`), and
2 exist only in the repo (`sure`, `paisa`). Adopt a rule: never edit configs on
the server; only deploy from the repo (via §1.4's `rsync --delete`).
**Why**: Eliminates the whole class of "which copy is right?" bugs.
**Trade-off**: Discipline required; the deploy script makes it easy.

### 4.2 Resolve the `sure`/`paisa` drift  🟢 ⭐
**What**: Decide whether `sure.conf` and `paisa.conf` should be deployed (the
backends exist on ports 8056/8057) or removed from the repo. Then reconcile.
**Why**: Repo currently advertises services that aren't reachable.
**Trade-off**: None — just a decision.

### 4.3 Use the existing site templates for new services  🟢 ⭐⭐
**What**: `common.sh` already has `generate_nginx_conf_file` +
`site-templates/{http,https}-template.conf`, but most configs are hand-written
and drift in style (e.g. `dumb.conf` uses relative `include snippets/...` while
others use absolute `/etc/nginx/snippets/...`). Standardize on the template and
absolute includes.
**Why**: Consistency; fewer copy-paste mistakes.
**Trade-off**: One-time cleanup pass.

### 4.4 Pre-commit / CI config validation  🟡 ⭐⭐
**What**: Add a hook or CI job that runs `nginx -t` against the config set (mount
it into a throwaway `nginx:stable-alpine` container) on every change.
**Why**: Catches conflicting `server_name`, bad includes, and syntax errors
before they reach the server. (This review found live `conflicting server_name`
and `duplicate MIME type` warnings that CI would have flagged.)
**Trade-off**: Slight CI setup effort.

---

## 5. Observability

### 5.1 nginx metrics into Prometheus/Grafana  🟡 ⭐⭐
**What**: Enable `stub_status` on a localhost-only location and run
`nginx-prometheus-exporter`, scraped by your existing Prometheus. Build a
Grafana panel (requests/s, active connections, 4xx/5xx rate).
**Why**: Visibility into proxy health and error spikes; complements the `/health`
liveness check.
**Trade-off**: One more small exporter container.

### 5.2 Structured access logs to Loki  🟡 ⭐
**What**: Access/error logs currently go to `podman logs`. Ship them to Loki for
searchable history and dashboards.
**Why**: Debugging and traffic analysis over time.
**Trade-off**: Log volume/retention to manage.

---

## 6. Nice-to-haves

- **HTTP/3 (QUIC)**  🟡 ⭐ — `nginx:stable-alpine` builds may support it; adds
  faster connection setup for browsers. Low priority on LAN.
- **Dashboard search/filter**  🟢 ⭐ — the `home.aevion.lan` page is static; a
  tiny JS filter box helps as the service count grows. (Keep it dependency-free.)
- **Dashboard auto-generation**  🟡 ⭐⭐ — generate `index.html` from the
  `sites/*.conf` `server_name`s so the dashboard can't drift from reality.
- **Favicon + PWA manifest**  🟢 ⭐ — makes the dashboard installable/bookmarkable.

---

## Suggested order

1. **§4.1 + §1.4** — stop the drift bleeding (source of truth + deploy script).
2. **§2.1** — local CA; unblocks §2.3 and real HTTPS everywhere.
3. **§3.1** — SSO in front of `systemd-switch` and the *arr/download stack.
4. **§1.3, §3.2, §5.1** — headers, rate limiting, metrics.
5. **§3.4** — bridge networks (the big, stack-wide one) when ready.
