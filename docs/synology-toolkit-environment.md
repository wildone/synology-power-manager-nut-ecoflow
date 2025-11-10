# Synology Toolkit Environment Setup

> Reference: [Synology Developer Guide – Prepare Environment](https://help.synology.com/developer-guide/getting_started/prepare_environment.html)

## 1. Install Toolkit Scripts
- Install Git and create the toolkit base directory (`/toolkit`).
- Clone `pkgscripts-ng` to `/toolkit/pkgscripts-ng`:
```
apt-get install git
mkdir -p /toolkit
cd /toolkit
git clone https://github.com/SynologyOpenSource/pkgscripts-ng
```
- Ensure required Python runtimes and helper utilities are available:
```
apt-get install cifs-utils \
    python \
    python-pip \
    python3 \
    python3-pip
```

### Toolkit Layout After Installation
```
/toolkit
├── pkgscripts-ng/
│   ├── include/
│   ├── EnvDeploy
│   └── PkgCreate.py
└── build_env/
```

## 2. Deploy Chroot Build Environments
- Use `EnvDeploy` to provision cross-compilation environments per architecture and DSM version.
- Example for DSM 7.2 `avoton` targets:
```
cd /toolkit/pkgscripts-ng/
git checkout DSM7.2
./EnvDeploy -v 7.2 -p avoton
```
- Alternatively download tarballs (`base_env`, `ds.<platform>-<version>.{dev,env}.txz`) into `/toolkit/toolkit_tarballs` and run `EnvDeploy -D` to reuse local archives.

### Resulting Directory Structure
```
/toolkit
├── pkgscripts-ng/
└── build_env/
    ├── ds.avoton-7.2/
    └── ds.avoton-6.2/
        └── usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/
```
- The deployed `build_env` contains cross GCC toolchains and sysroot directories with DSM headers/libraries.

## 3. Discover Supported Platforms
- List available platforms for a DSM version:
```
./EnvDeploy -v 7.2 --list
```
- Inspect detailed info for a specific platform:
```
./EnvDeploy -v 7.2 --info avoton
```
- Toolchains are grouped by platform families (e.g., `braswell` covers multiple x86_64 models). Consult the platform mapping table in Appendix A of the developer guide.

## 4. Maintain Build Environments
- **Update**: rerun `EnvDeploy` with the same version/platform to refresh packages.
```
./EnvDeploy -v 7.2 -p avoton
```
- **Remove**: unmount `proc` and delete the folder when you need to reclaim space.
```
umount /toolkit/build_env/ds.avoton-7.2/proc
rm -rf /toolkit/build_env/ds.avoton-7.2
```

## 5. Next Steps for Dockerization
- Containerize the toolkit by installing `pkgscripts-ng` and running `EnvDeploy` inside a Docker image.
- Mount `/toolkit` or a project directory to persist build outputs.
- Provide `docker-compose.yml` services that expose target architecture configuration, environment variables, and volume bindings.

### Project Docker Assets
- `docker/Dockerfile`: Builds a Debian-based image with toolkit prerequisites and clones `pkgscripts-ng`.
- `docker/entrypoint.sh`: Automatically runs `EnvDeploy` for the requested DSM version and platform (override with environment variables).
- `docker/docker-compose.yml`: Launches a reusable container (`synology-toolchain`) with persistent toolkit data (`toolkit-data` volume) and binds the local `synology/` package sources to `/workspace/synology`.

#### Usage
```
cd docker
docker compose up --build -d
docker compose exec synology-toolchain bash
```
- Inside the container, package sources live at `/workspace/synology` and toolkit scripts at `/toolkit/pkgscripts-ng`.
- Set `DSM_PLATFORM`, `DSM_VERSION`, or `ENVDEPLOY_OFFLINE=true` (reuse cached tarballs) in the compose file or via `docker compose run -e` flags as needed.
