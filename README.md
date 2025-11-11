# Synology Power Manager NUT EcoFlow

Package + tooling to integrate EcoFlow UPS devices with Synology DSM 7.x using Network UPS Tools (NUT).

> **Community note:** if you run into problems, please open an issue—and if the package (or EcoFlow’s original build) worked for you, drop a comment so we know which setups are covered. 🙂

## Overview

- Based on Synology’s `PowerManagerNUT` sources, tailored for EcoFlow EF-UPS-DELTA series.
- Ships ready-to-build Synology package sources under `synology/PowerManagerNutEcoFlow`.
- Includes Docker-based Synology toolkit environment and GitHub Actions workflow for reproducible builds.
- Depends on [Simple Permission Manager](https://github.com/XPEnology-Community/SimplePermissionManager) to auto-approve the privileged commands required by the NUT service.\[ [source](https://github.com/XPEnology-Community/SimplePermissionManager) ]

## Requirements

### End users (installing from a release)

1. **DSM 7.1+** NAS (or Virtual DSM) with the EcoFlow UPS connected via USB.
2. **Simple Permission Manager** package installed and activated so privileged NUT commands are auto-approved. [Simple Permission Manager](https://github.com/XPEnology-Community/SimplePermissionManager)
3. Download the latest `PowerManagerNutEcoFlow-<version>.spk` from this repository’s Releases page and install it via Package Center → Manual Install.

> Need additional background? Synology’s official UPS/NUT documentation and the EcoFlow guide in **`docs/EcoFlow User Manual.pdf`** remain excellent references, but they are not prerequisites for running the packaged release.

### Developers (building or customizing the package)

- Everything listed for end users, plus:
  - Docker (for the bundled toolkit container) or a Linux host with Synology’s `pkgscripts-ng`.
  - Optional: follow the step-by-step walkthrough in `docs/PowerManagerNUT + EcoFlow EF-UPS-DELTA 3 Plus.md` if you want to reproduce the manual testing flow before packaging.

## Manual Integration Reference

Already have the legacy EcoFlow package on your NAS? You can keep using it and just apply the latest adjustments from our docs:

1. Follow the step-by-step guide in `docs/PowerManagerNUT + EcoFlow EF-UPS-DELTA 3 Plus.md`. It documents every manual change needed to bring the stock `PowerManagerNUT` package up to EcoFlow compatibility.
2. Use `synology/README.md` as a quick diff guide—it explains how each runtime script was adapted for DSM service behaviour.

This project simply bundles those manual steps into a clean package. If you prefer to stay on the manual path, the documentation remains fully usable on its own. You can always return later and install the pre-built `.spk` once you’re ready for a streamlined update or CI/CD integration.

## Installation Quickstart

1. Install and activate Simple Permission Manager on DSM.
2. Manual install the latest release `.spk` (Packages → Manual Install) and start the service from Package Center.

Optional for developers:

- Build from source:
  ```bash
  ./scripts/build-package.sh   # runs Docker toolchain, outputs dist/PowerManagerNutEcoFlow-<platform>-<version>.spk
  ```
- SSH into DSM and tail `/var/packages/PowerManagerNutEcoFlow/target/var/log/run.sh.log` if you need deeper troubleshooting.

## Development & Testing

- `docker/` contains the Synology toolkit container definition; `docker compose up` launches an environment with `pkgscripts-ng`.
- `tests/` includes lightweight shell checks (`run-all.sh`) for INFO metadata and runtime script expectations.
- GitHub Actions workflow (`.github/workflows/build-package.yml`) builds and archives the `.spk` on every push/tag.

Contributions welcome—please document any script changes in `synology/README.md` to keep the manual and packaged behaviours in sync.

## Bonus: Legacy Synology Packages

If Synology has deprecated a package that you still need (for example, certain UPS/driver utilities referenced in the EcoFlow manuals), archived builds remain available at the [Synology package archive](https://archive.synology.com/download/Package).