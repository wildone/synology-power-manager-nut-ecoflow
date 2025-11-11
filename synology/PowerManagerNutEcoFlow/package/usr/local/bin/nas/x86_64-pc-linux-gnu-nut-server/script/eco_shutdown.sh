#!/bin/bash
# EcoFlow shutdown hook invoked by upsmon on critical events.
set -euo pipefail

readonly PACKAGE_NAME="PowerManagerNutEcoFlow"
readonly UPS_ALIAS="ups"
readonly UPS_PORT="3493"
readonly LOG_DIR="/var/packages/${PACKAGE_NAME}/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/log"
readonly UPSC_BIN="/var/packages/${PACKAGE_NAME}/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/bin/upsc"

mkdir -p "${LOG_DIR}"
exec >>"${LOG_DIR}/eco_shutdown.sh.log" 2>&1

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

log() {
    echo "[$(timestamp)] $*"
}

main() {
    log "eco_shutdown.sh invoked"

    if [ ! -x "${UPSC_BIN}" ]; then
        log "upsc binary missing: ${UPSC_BIN}"
    else
        local status
        status="$("${UPSC_BIN}" "${UPS_ALIAS}@localhost:${UPS_PORT}" ups.status 2>/dev/null || true)"
        log "Current UPS status: ${status}"
    fi

    log "Requesting system shutdown via /sbin/shutdown -h now"
    /sbin/shutdown -h now || log "Failed to execute shutdown command"
}

main "$@"
