# SelfHost Documentation

Infrastructure-level design docs, runbooks, and guides for the `aevion`
self-hosted stack. App-specific documentation lives alongside each service
under `apps/<service>/README.md`; this folder is reserved for **cross-cutting
concerns** that span multiple services or describe the host/network itself,
plus general reference material and working notes.

## Network & host fundamentals

| Doc | Topic | Read when |
|-----|-------|-----------|
| [`DNS_ARCHITECTURE.md`](./DNS_ARCHITECTURE.md) | End-to-end DNS flow: AdGuardHome, Tailscale, pasta, `containers.conf`, per-container `--dns` bypass, AAAA policy, Podman 5.x `--dns` append quirk + the `CONTAINERS_CONF=/dev/null` workaround. | Any time you add a service that cares about DNS, debug a resolution issue, or touch AGH/`podman/containers.conf`. |

## Operations & tooling

| Doc | Topic |
|-----|-------|
| [`MEDIA_SERVER_GUIDE.md`](./MEDIA_SERVER_GUIDE.md) | End-to-end setup notes for the *arr stack and related media automation. Referenced by `.cursor/rules/contribution-guidelines.mdc`. |

## Planning & templates

| Doc | Topic |
|-----|-------|
| [`README_TEMPLATE.md`](./README_TEMPLATE.md) | Template for new `apps/<service>/README.md` files. Copy + fill in when adding a service. |

## Related references

- [`../.cursor/rules/`](../.cursor/rules/) — cursor rules that enforce project conventions. In particular:
  - [`podman-dns-bypass.mdc`](../.cursor/rules/podman-dns-bypass.mdc) — the `CONTAINERS_CONF=/dev/null` bypass pattern.
  - [`dual-quadlet-pattern.mdc`](../.cursor/rules/dual-quadlet-pattern.mdc) — the auto-generated `<svc>.container` + hand-written `<svc>.container-manual` dual-file convention.
- [`../podman/containers.conf`](../podman/containers.conf) — global Podman defaults, deployed to `~/.config/containers/containers.conf` on aevion.

## Conventions for new docs in this folder

- **Cross-cutting only.** If it's about one service, it belongs in `apps/<service>/README.md`.
- **Start with a TL;DR** (a diagram or a table is ideal).
- **Explain the why**, not just the what. Docs in this folder are recovery aids for future-you; assume all context is lost.
- **Link from the relevant README / rule / config file.** A doc no one can find is worse than no doc.
- **Date it at the top** and bump the date whenever the content meaningfully changes.
