#!/bin/bash
# Entry point for Synology toolkit container. Deploys build environment on demand.
set -euo pipefail

TOOLKIT_ROOT="${TOOLKIT_ROOT:-/toolkit}"
DSM_VERSION="${DSM_VERSION:-7.2}"
DSM_PLATFORM="${DSM_PLATFORM:-apollolake}"
DEPLOY_FLAGS=()
TARGET_ENV_DIR="${TOOLKIT_ROOT}/build_env/ds.${DSM_PLATFORM}-${DSM_VERSION}"

if [ "${SKIP_ENVDEPLOY:-false}" = "true" ]; then
    echo "[entrypoint] Skipping EnvDeploy as requested"
elif [ -d "${TARGET_ENV_DIR}" ] && [ -f "${TARGET_ENV_DIR}/PkgVersion" ]; then
    echo "[entrypoint] Build environment ${TARGET_ENV_DIR} already present; skipping EnvDeploy"
else
    echo "[entrypoint] Deploying Synology toolkit environment for DSM ${DSM_VERSION} (${DSM_PLATFORM})"
    if [ "${ENVDEPLOY_OFFLINE:-false}" = "true" ]; then
        DEPLOY_FLAGS+=("-D")
        echo "[entrypoint] Using offline tarballs from ${TOOLKIT_ROOT}/toolkit_tarballs"
    fi

    pushd "${TOOLKIT_ROOT}/pkgscripts-ng" >/dev/null
    ./EnvDeploy -v "${DSM_VERSION}" -p "${DSM_PLATFORM}" "${DEPLOY_FLAGS[@]}"
    popd >/dev/null
fi

cd "${WORKSPACE:-/workspace}"
exec "$@"
