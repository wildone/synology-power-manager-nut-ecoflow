# Synology Power Manager NUT EcoFlow

Package + tooling to integrate EcoFlow UPS devices with Synology DSM 7.x using Network UPS Tools (NUT).

## Overview

- Based on Synology’s `PowerManagerNUT` sources, tailored for EcoFlow EF-UPS-DELTA series.
- Ships ready-to-build Synology package sources under `synology/PowerManagerNutEcoFlow`.
- Includes Docker-based Synology toolkit environment and GitHub Actions workflow for reproducible builds.
- Depends on [Simple Permission Manager](https://github.com/XPEnology-Community/SimplePermissionManager) to auto-approve the privileged commands required by the NUT service.\[ [source](https://github.com/XPEnology-Community/SimplePermissionManager) ]

## Requirements

- DSM 7.1+ NAS or Virtual DSM for testing.
- Docker (for local builds) or a Linux host with Synology’s `pkgscripts-ng`.
- EcoFlow UPS connected via USB.
- **Packages to install on DSM**:
  1. Official Synology “UPS Server / Network UPS Tools” (as per Synology’s package documentation).
  2. Official EcoFlow firmware/tools referenced in `docs/EcoFlow User Manual.pdf`.
  3. `Simple Permission Manager` (activate it after installation to grant the package the necessary privileges).\[ [source](https://github.com/XPEnology-Community/SimplePermissionManager) ]

> For detailed EcoFlow setup steps, consult both the official Synology package docs and **`docs/EcoFlow User Manual.pdf`** in this repository.

## Installation Quickstart

1. Install Synology’s UPS/NUT package and EcoFlow utilities per the official manuals (see above).
2. Install and activate Simple Permission Manager.
3. Build this package:
   ```bash
   ./scripts/build-package.sh   # runs Docker toolchain, outputs dist/PowerManagerNutEcoFlow-<platform>-<version>.spk
   ```
4. Upload the generated `.spk` to DSM Package Center → Manual Install.
5. Start `Power Manager NUT EcoFlow` from Package Center; the service log is under `/var/packages/PowerManagerNutEcoFlow/target/var/log/run.sh.log`.

## Manual Integration Reference

If you prefer to follow the original manual steps for EcoFlow integration or need to troubleshoot, review:

- `docs/PowerManagerNUT + EcoFlow EF-UPS-DELTA 3 Plus.md` – the original echoed command list with manual testing procedures.
- `synology/README.md` – explains how each runtime script in this package diverges from the manual doc and why.

Both resources can be used side-by-side: the manual doc for deep dives, the packaged scripts for production deployment.

## Development & Testing

- `docker/` contains the Synology toolkit container definition; `docker compose up` launches an environment with `pkgscripts-ng`.
- `tests/` includes lightweight shell checks (`run-all.sh`) for INFO metadata and runtime script expectations.
- GitHub Actions workflow (`.github/workflows/build-package.yml`) builds and archives the `.spk` on every push/tag.

Contributions welcome—please document any script changes in `synology/README.md` to keep the manual and packaged behaviours in sync.