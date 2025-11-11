#!/bin/bash
# Verifies runtime scripts contain critical commands for NUT lifecycle.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RUN_SCRIPT="${ROOT_DIR}/synology/PowerManagerNutEcoFlow/package/usr/local/bin/nas/run.sh"
SHUTDOWN_SCRIPT="${ROOT_DIR}/synology/PowerManagerNutEcoFlow/package/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/script/eco_shutdown.sh"

if [[ ! -f "${RUN_SCRIPT}" ]]; then
  echo "[ERROR] run.sh missing at ${RUN_SCRIPT}" >&2
  exit 1
fi

required_patterns=(
  "upsdrvctl"
  "upsd"
  "upsmon"
  "PowerManagerNutEcoFlow service started successfully"
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -q "${pattern}" "${RUN_SCRIPT}"; then
    echo "[ERROR] run.sh is missing expected token '${pattern}'" >&2
    exit 1
  fi
done

if [[ ! -f "${SHUTDOWN_SCRIPT}" ]]; then
  echo "[ERROR] eco_shutdown.sh missing at ${SHUTDOWN_SCRIPT}" >&2
  exit 1
fi

if ! grep -q "PowerManagerNutEcoFlow" "${SHUTDOWN_SCRIPT}"; then
  echo "[ERROR] eco_shutdown.sh does not reference package log directory" >&2
  exit 1
fi

echo "[OK] Runtime scripts validated"
exit 0

