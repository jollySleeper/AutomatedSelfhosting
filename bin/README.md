# Binaries

## Podlet

`scripts/podman/container.sh` runs `bin/podlet` to generate quadlet files. The
binaries are not committed (see `.gitignore`); place them here on the server.

- `bin/podlet` is a symlink to `podlet_v0.2.4_arm64`, the version in use on aevion
  (`podlet --version` → `podlet 0.2.4`).
  - SHA-256: `a467f23f9a05146013aaaa84c6067fe455565ff94a5aaee4f11d061861f2ce79`
- `podlet_v0.3.0_arm64_musl` is also kept but not linked. This build is not on
  Podlet's release page, so it was downloaded from
  [cargo-quickinstall](https://github.com/cargo-bins/cargo-quickinstall/releases/tag/podlet-0.3.0).
  - SHA-256: `28a93dfdb4073d43335b238d20e20d93e5c8b0c07a5a4cf8f5c6c5b000eb6d03`
