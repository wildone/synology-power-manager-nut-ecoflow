#!/bin/bash
# Runs all project test scripts in the tests directory.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="${ROOT_DIR}/tests"

status=0

for test_script in "${TEST_DIR}"/*.sh; do
  [[ "$(basename "${test_script}")" == "run-all.sh" ]] && continue
  echo "[TEST] Running $(basename "${test_script}")"
  if ! bash "${test_script}"; then
    echo "[FAIL] $(basename "${test_script}")" >&2
    status=1
  fi
done

exit "${status}"

