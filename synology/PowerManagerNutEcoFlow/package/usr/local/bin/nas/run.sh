#!/bin/bash
# PowerManagerNutEcoFlow run script (EcoFlow + Synology integration)
# - Uses packaged NUT stack under x86_64-pc-linux-gnu-nut-server
# - Exposes UPS as ups@127.0.0.1:3493
# - Intended to be called by start-stop-status / synopkg

set -euo pipefail

readonly PACKAGE_NAME="PowerManagerNutEcoFlow"
readonly TARGET_ROOT="/var/packages/${PACKAGE_NAME}/target"
readonly LOG_DIR="${TARGET_ROOT}/var/log"
readonly NUT_ROOT="${TARGET_ROOT}/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server"
readonly UPS_ALIAS="ups"
readonly UPS_ENDPOINT="127.0.0.1"
readonly UPS_PORT="3493"

mkdir -p "${LOG_DIR}"
exec >>"${LOG_DIR}/run.sh.log" 2>&1

echo "===== run.sh start $(date) ====="

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err() { echo "[ERROR] $*" >&2; }

die() {
    err "$*"
    exit 1
}

require_file() {
    # $1: absolute path to the file that must exist
    local file_path="$1"
    if [ ! -e "${file_path}" ]; then
        die "Required file missing: ${file_path}"
    fi
}

stop_processes() {
    # Stop any stray NUT processes before starting fresh
    for binary in "usbhid-ups" "upsd" "upsmon"; do
        if pgrep -f "${binary}" >/dev/null 2>&1; then
            warn "Stopping existing ${binary} process"
            pkill -f "${binary}" || true
        fi
    done
}

start_driver() {
    log "Starting NUT USB driver"
    "${NUT_ROOT}/sbin/upsdrvctl" -u root start
}

start_server() {
    log "Starting NUT server"
    "${NUT_ROOT}/sbin/upsd" -u root
}

start_monitor() {
    log "Starting NUT monitor"
    "${NUT_ROOT}/sbin/upsmon"
}

verify_runtime() {
    log "Verifying driver status via upsc"
    local status
    status="$("${NUT_ROOT}/bin/upsc" "${UPS_ALIAS}@${UPS_ENDPOINT}:${UPS_PORT}" ups.status 2>/dev/null || true)"
    if [ -z "${status}" ]; then
        die "Unable to query UPS status via upsc; check cabling and configuration"
    fi
    log "UPS status: ${status}"
}

main() {
    log "Preparing runtime directories"
    mkdir -p "${TARGET_ROOT}/usr/local/bin/nas" "${LOG_DIR}"

    log "Ensuring required binaries exist"
    require_file "${NUT_ROOT}/script/setup_env.sh"
    require_file "${NUT_ROOT}/sbin/upsdrvctl"
    require_file "${NUT_ROOT}/sbin/upsd"
    require_file "${NUT_ROOT}/sbin/upsmon"
    require_file "${NUT_ROOT}/bin/upsc"

    log "Running NUT environment setup script"
    "${NUT_ROOT}/script/setup_env.sh"

    stop_processes
    start_driver
    start_server

    sleep 1
    start_monitor

    sleep 1
    verify_runtime

    log "PowerManagerNutEcoFlow service started successfully"
}

main "$@"
