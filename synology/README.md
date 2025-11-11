## Synology Package Script Notes

This package adapts the upstream `PowerManagerNUT` sources and the EcoFlow integration instructions to behave like a native DSM 7 service. The sections below capture what changed in each critical script and why those differences exist.

---

### `package/usr/local/bin/nas/run.sh`

**What it does now**

- Exposes a non-interactive start sequence (`stop_processes → start_driver → start_server → start_monitor → verify_runtime`).
- Logs everything to `/var/packages/PowerManagerNutEcoFlow/target/var/log/run.sh.log`.
- Validates required binaries/config before starting.
- Verifies the UPS is reachable (`upsc ups@127.0.0.1:3493`) and aborts on failure.

**Why it differs from the EcoFlow notes**

- The doc shows a manual checklist (with `sudo`, bilingual messages, numbered steps). DSM service hooks run as root already, must not prompt for input, and should fail fast on errors.
- Replaced `sudo`/interactive output with deterministic logging, since DSM’s `start-stop-status` wrapper only inspects the exit code and the log file.
- Added guard rails (file existence checks, process cleanup) to avoid stale state when Synology restarts the service automatically.

**Practical reminders**

- Any manual debug session should still follow the doc, but run it outside DSM (e.g. the tests folder or a helper script) so the package start hook stays clean.
- If you change port/UPS alias, update `verify_runtime` to match.

---

### `package/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/script/eco_shutdown.sh`

**What it does now**

- Logs invocation and current `ups.status` to `/var/packages/.../eco_shutdown.sh.log`.
- Calls `/sbin/shutdown -h now` and logs failures.

**Why it differs from the EcoFlow notes**

- The doc’s variant manages libvirt VMs (`virsh list`, graceful shutdown loops, `poweroff_nas`). That’s appropriate for a workstation, but most DSM systems running this package won’t host KVM.
- `upsmon` passes control here during a forced shutdown; DSM just needs the system to go down quickly, without depending on `virsh` or additional tooling.

**Practical reminders**

- If you do host VMs on DSM and need the original flow, wrap it in a separate helper script and call it from here—but keep the DSM-friendly logging and error handling.

---

### `scripts/start-stop-status`

**What it does now**

- Delegates `start` to `run.sh`, `stop` to a simple `pkill` sequence, and reports status by checking for running NUT processes.
- Adds log entries for DSM’s lifecycle timestamps.

**Why it differs from the EcoFlow notes**

- The notes assume manual control; Synology requires packages to expose `start`, `stop`, `status` hooks via this script so `synopkg` works.

---

### Lifecycle Hooks (`scripts/preinst`, `postinst`, `preuninst`, `postuninst`, `preupgrade`, `postupgrade`)

**What they do now**

- Create runtime directories (`target/usr/local/bin/nas`, `target/var/log`) before unpacking the payload.
- Fix executable bits on `run.sh` and `eco_shutdown.sh`.
- Stop the service cleanly during uninstall/upgrade.
- Back up and restore user-edited configs (`ups.conf`, `upsd.conf`, `upsd.users`, `upsmon.conf`) across upgrades.

**Why they differ**

- The doc walks through manual deployment steps. DSM packages must manage their own directories, permissions, and upgrade paths.

---

### `SynoBuildConf/build` and `SynoBuildConf/install`

**What they do now**

- `build`: ensures service scripts and CGI helpers are executable before packaging.
- `install`: uses Synology’s `pkg_util.sh` helpers to create `package.tgz` and assemble the final payload (INFO, icons, scripts, config, wizard files).

**Why they differ**

- Upstream notes expect you to copy files manually onto the NAS. To automate builds (local Docker toolkit, GitHub Actions), we need deterministic scripts compatible with `PkgCreate.py`.

---

### Helpful Tips

- When you tweak `run.sh` or `eco_shutdown.sh`, update this README so the rationale doesn’t get lost.
- The helper script `scripts/build-package.sh` wraps the Docker-based toolkit workflow and drops the resulting `.spk` into `dist/`.
- Quick regression checks live in `tests/` (`run-all.sh`, `check-info.sh`, `check-runtime.sh`).

