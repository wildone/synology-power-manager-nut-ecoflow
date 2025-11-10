# Synology DSM 7.1 Package Quickstart

> Reference: [Synology Developer Guide – Your First Package](https://help.synology.com/developer-guide/getting_started/first_package.html)

## Prerequisites
- Synology DSM 7.1 NAS or Virtual DSM instance for testing.
- Synology Toolkit (`pkgscripts-ng`) installed on a Linux environment, Docker container, or WSL.
- Matching Synology cross-compilation toolchain for your NAS architecture (see Appendix A of the developer guide).
- Git, `make`, and standard GNU build tools available inside the build environment.

## Toolkit Layout Overview
```
/toolkit/
├── build_env/
│   └── ds.${platform}-${version}/
├── pkgscripts-ng/
│   ├── EnvDeploy
│   └── PkgCreate.py
└── source/
    └── ExamplePackage/
        ├── examplePkg.c
        ├── INFO.sh
        ├── Makefile
        ├── PACKAGE_ICON.PNG
        ├── PACKAGE_ICON_256.PNG
        ├── scripts/
        │   ├── postinst
        │   ├── postuninst
        │   ├── postupgrade
        │   ├── postreplace
        │   ├── preinst
        │   ├── preuninst
        │   ├── preupgrade
        │   ├── prereplace
        │   └── start-stop-status
        └── SynoBuildConf/
            ├── depends
            ├── build
            └── install
```

## Step-by-Step Workflow
- **Download template**: Clone `https://github.com/SynologyOpenSource/ExamplePackages` and copy `ExamplePackages/ExamplePackage` into `/toolkit/source/ExamplePackage`.
- **Configure build scripts**: Edit `SynoBuildConf/depends`, `SynoBuildConf/build`, and `SynoBuildConf/install` to encode dependencies, build steps, and packaging logic.
- **Describe the package**: Update `INFO.sh` (converted to `INFO` during packaging) with metadata (`package`, `version`, `os_min_ver="7.0-40000"`, `displayname`, `description`, `arch`, `maintainer`).
- **Implement lifecycle hooks**: Adjust scripts under `scripts/` such as `preinst`, `postinst`, and `start-stop-status` for DSM service flow. DSM 7.x expects systemd-style start/stop implementation via `service-setup`.
- **Compile application**: Use cross-toolchain via the provided `Makefile` (`include /env.mak`) to build binaries inside the toolkit environment.
- **Assemble payload**: During `SynoBuildConf/install`, populate `/tmp/_package_tgz`, copy binaries and resources, and run `pkg_make_package` to produce `package.tgz`.

## Building the .spk
Run the packaging script from the toolkit directory:
```
cd /toolkit/pkgscripts-ng/
./PkgCreate.py -v 7.0 -p <platform> -c ExamplePackage
```
- Replace `<platform>` with the target (e.g., `avoton`, `apollolake`, `rtd1296`).
- Resulting `.spk` appears under `/toolkit/result_spk/${package}-${version}/`.

## Installing & Testing
- Upload the generated `.spk` to your NAS via **Package Center ▸ Manual Install**.
- After installation, start the package and confirm logs in `/var/log/messages`.
- Use `synopkg` CLI on the NAS for lifecycle management (`synopkg start`, `synopkg stop`, etc.).

## Next Steps
- Customize UI assets and wizard flows via `package.tgz/UIFILES` and `wizard/` if needed.
- Define privileges in `conf/privilege` for DSM 7.x permission model.
- Integrate additional resources (e.g., ports, web services) through `conf/resource` definitions.
- Review "Synology Toolkit" and "Synology DSM Integration" sections for advanced configuration before publishing.
