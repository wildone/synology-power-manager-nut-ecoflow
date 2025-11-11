#!/bin/bash
# Wrapper to build the PowerManagerNutEcoFlow Synology package inside the toolkit container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
PACKAGE_NAME="PowerManagerNutEcoFlow"
INFO_FILE="${PROJECT_ROOT}/synology/${PACKAGE_NAME}/INFO"
DIST_DIR="${PROJECT_ROOT}/dist"

if [[ ! -f "${INFO_FILE}" ]]; then
  echo "[ERROR] INFO file not found at ${INFO_FILE}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker command not available; install Docker before running this script." >&2
  exit 1
fi

VERSION="$(awk -F\" '/^version=/{print $2}' "${INFO_FILE}")"
if [[ -z "${VERSION}" ]]; then
  echo "[ERROR] Unable to determine package version from ${INFO_FILE}" >&2
  exit 1
fi

DSM_PLATFORM="${DSM_PLATFORM:-apollolake}"
DSM_VERSION="${DSM_VERSION:-7.2}"

mkdir -p "${DIST_DIR}"

pushd "${PROJECT_ROOT}/docker" >/dev/null
trap 'popd >/dev/null' EXIT

# Ensure the toolkit container is running.
docker compose up -d synology-toolchain >/dev/null

PACKAGE_FILE="${PACKAGE_NAME}-${DSM_PLATFORM}-${VERSION}.spk"

docker compose exec synology-toolchain bash -lc "
set -euo pipefail
PACKAGE_NAME='${PACKAGE_NAME}'
DSM_PLATFORM='${DSM_PLATFORM}'
DSM_VERSION='${DSM_VERSION}'
VERSION='${VERSION}'
SOURCE_DIR=\"/workspace/synology/\${PACKAGE_NAME}\"
TOOLKIT_SOURCE_DIR=\"/toolkit/source/\${PACKAGE_NAME}\"
BUILD_ENV_DIR=\"/toolkit/build_env/ds.\${DSM_PLATFORM}-\${DSM_VERSION}\"
SPK_OUTPUT_DIR=\"\${BUILD_ENV_DIR}/tmp/_spk_output\"

rm -rf \"\${TOOLKIT_SOURCE_DIR}\"
mkdir -p \"\${TOOLKIT_SOURCE_DIR}\"
cp -a \"\${SOURCE_DIR}/.\" \"\${TOOLKIT_SOURCE_DIR}/\"

rm -rf \"\${BUILD_ENV_DIR}/source/\${PACKAGE_NAME}\"
rm -rf \"\${SPK_OUTPUT_DIR}\"
mkdir -p \"\${SPK_OUTPUT_DIR}\"

cd /toolkit/pkgscripts-ng
./PkgCreate.py -v \"\${DSM_VERSION}\" -p \"\${DSM_PLATFORM}\" -c \"\${PACKAGE_NAME}\"

chroot \"\${BUILD_ENV_DIR}\" /pkgscripts-ng/include/pkg_util.sh make_spk /tmp/_install /tmp/_spk_output

cp \"\${SPK_OUTPUT_DIR}/\${PACKAGE_NAME}-\${DSM_PLATFORM}-\${VERSION}.spk\" /workspace/dist/
"

echo "[OK] Package available at ${DIST_DIR}/${PACKAGE_FILE}"

