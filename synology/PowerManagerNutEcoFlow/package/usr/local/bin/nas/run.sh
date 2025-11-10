#!/bin/bash

# PowerManagerNutEcoFlow run script (EcoFlow + Synology integration)
# - Uses packaged NUT under x86_64-pc-linux-gnu-nut-server
# - Exposes UPS as ups@127.0.0.1:3493
# - Intended to be called by start-stop-status / synopkg

set -euo pipefail

LOG_DIR="/var/packages/PowerManagerNutEcoFlow/target/var/log"
mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/run.sh.log" 2>&1

echo "===== run.sh start $(date) ====="

log()  { echo "[INFO] $*"; }
err()  { echo "[ERROR] $*" >&2; }
die()  { err "$@"; exit 1; }

has_proc() {
    # $1: substring to look for in process list
    ps aux | grep "$1" | grep -v grep >/dev/null 2>&1
}

stop_proc() {
    # $1: substring (binary name)
    for pid in $(ps aux | grep "$1" | grep -v grep | awk '{print $2}'); do
        kill "$pid" 2>/dev/null || true
    done
}

# ---------------------------------------------------------------------
# Absolute base paths
# ---------------------------------------------------------------------
PKG_NAS_DIR="/var/packages/PowerManagerNutEcoFlow/target/usr/local/bin/nas"
NUT_BASE="${PKG_NAS_DIR}/x86_64-pc-linux-gnu-nut-server"

[ -d "$PKG_NAS_DIR" ] || die "PKG_NAS_DIR not found: $PKG_NAS_DIR"
[ -d "$NUT_BASE" ]    || die "NUT_BASE not found: $NUT_BASE"

SETUP_ENV="${NUT_BASE}/script/setup_env.sh"
[ -f "$SETUP_ENV" ] || die "setup_env.sh missing: $SETUP_ENV"

cd "$PKG_NAS_DIR" || die "Failed to cd to $PKG_NAS_DIR"

# ---------------------------------------------------------------------
# Environment setup (udev rules + libs)
# ---------------------------------------------------------------------
log "Running setup_env.sh..."
if ! output="$(sh "$SETUP_ENV" 2>&1)"; then
    echo "$output"
    die "Environment setup failed"
fi

echo "$output" | grep -qi "Installation completed successfully" || \
    log "Environment setup completed (no standard phrase, continuing)"

log "Environment setup OK"
echo

# ---------------------------------------------------------------------
# NUT environment paths
# ---------------------------------------------------------------------
export NUT_CONFPATH="$NUT_BASE/etc"
export NUT_STATEPATH="$NUT_BASE/var/state/ups"
export NUT_UPSDRVPATH="$NUT_BASE/bin"
export NUT_UPSHOSTSDIR="$NUT_BASE/etc"
export NUT_POWERDOWNFLAG="/etc/killpower"

mkdir -p "$NUT_STATEPATH"

log "Using NUT_CONFPATH=$NUT_CONFPATH"
log "Using NUT_UPSDRVPATH=$NUT_UPSDRVPATH"
echo

# ---------------------------------------------------------------------
# Stop any existing NUT daemons
# ---------------------------------------------------------------------
log "Stopping existing NUT processes (if any)..."
stop_proc "usbhid-ups"
stop_proc "upsd"
stop_proc "upsmon"
echo

# ---------------------------------------------------------------------
# Scan for EcoFlow UPS
# ---------------------------------------------------------------------
NUT_SCANNER="$NUT_BASE/bin/nut-scanner"
[ -x "$NUT_SCANNER" ] || die "nut-scanner not found: $NUT_SCANNER"

log "Scanning for EcoFlow UPS..."
scan_output="$("$NUT_SCANNER" -U 2>&1)"
echo "$scan_output"

case "$scan_output" in
    *'vendor = "EcoFlow"'*)
        log "EcoFlow UPS detected"
        ;;
    *)
        die "EcoFlow UPS not found; check USB connection and power"
        ;;
esac
echo

# ---------------------------------------------------------------------
# Start driver (usbhid-ups) via upsdrvctl
# ---------------------------------------------------------------------
UPSDRVCTL="$NUT_BASE/sbin/upsdrvctl"
[ -x "$UPSDRVCTL" ] || die "upsdrvctl not found: $UPSDRVCTL"

log "Starting NUT driver (upsdrvctl)..."
drv_output="$("$UPSDRVCTL" -u root start ups 2>&1)"
echo "$drv_output"

# If driver clearly reports failure, abort
if echo "$drv_output" | grep -Eiq "Driver failed|exit status"; then
    die "upsdrvctl reported failure. Check USB connection and $NUT_CONFPATH/ups.conf"
fi

# Relaxed sanity check: see if usbhid-ups appears (but don't hard-fail here)
sleep 2
if has_proc "usbhid-ups"; then
    log "Driver appears to be running"
else
    err "usbhid-ups process not detected; will rely on upsd/upsc check"
fi
echo

# ---------------------------------------------------------------------
# Start upsd on 3493
# ---------------------------------------------------------------------
UPSD="$NUT_BASE/sbin/upsd"
[ -x "$UPSD" ] || die "upsd not found: $UPSD"

log "Starting upsd..."
upsd_output="$("$UPSD" -u root 2>&1)"
echo "$upsd_output"

sleep 1
if ! netstat -tlnp 2>/dev/null | grep -q "3493"; then
    die "upsd did not start on port 3493. Check $NUT_CONFPATH/upsd.conf"
fi

log "upsd started successfully on port 3493"
echo

# ---------------------------------------------------------------------
# Validate with upsc
# ---------------------------------------------------------------------
UPSC="$NUT_BASE/bin/upsc"
[ -x "$UPSC" ] || die "upsc not found: $UPSC"

log "Validating UPS status via upsc ups@127.0.0.1:3493..."
upsc_output="$("$UPSC" ups@127.0.0.1:3493 2>&1)" || die "upsc failed: $upsc_output"
echo "$upsc_output"

echo "$upsc_output" | grep -q "ups.status" || die "upsc did not return ups.status; NUT not healthy"

log "upsc OK — UPS is reachable as ups@127.0.0.1:3493"
echo

# ---------------------------------------------------------------------
# Start upsmon
# ---------------------------------------------------------------------
UPSMON="$NUT_BASE/sbin/upsmon"
[ -x "$UPSMON" ] || die "upsmon not found: $UPSMON"

log "Starting upsmon..."
upsmon_output="$("$UPSMON" 2>&1)"
echo "$upsmon_output"

sleep 1
if ! has_proc "upsmon"; then
    die "upsmon did not stay running. Check $NUT_CONFPATH/upsmon.conf"
fi

log "upsmon started successfully"
echo

log "EcoFlow UPS is running via NUT as ups@127.0.0.1:3493"
log "run.sh completed successfully."
exit 0
