#!/bin/bash
# Ensures INFO metadata contains required keys and coherent values.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INFO_FILE="${ROOT_DIR}/synology/PowerManagerNutEcoFlow/INFO"

if [[ ! -f "${INFO_FILE}" ]]; then
  echo "[ERROR] INFO file not found at ${INFO_FILE}" >&2
  exit 1
fi

package=$(awk -F\" '/^package=/{print $2}' "${INFO_FILE}")
version=$(awk -F\" '/^version=/{print $2}' "${INFO_FILE}")
arch=$(awk -F\" '/^arch=/{print $2}' "${INFO_FILE}")
displayname=$(awk -F\" '/^displayname=/{print $2}' "${INFO_FILE}")

missing=()
[[ -z "${package}" ]] && missing+=("package")
[[ -z "${version}" ]] && missing+=("version")
[[ -z "${arch}" ]] && missing+=("arch")
[[ -z "${displayname}" ]] && missing+=("displayname")

if (( ${#missing[@]} > 0 )); then
  echo "[ERROR] INFO missing keys: ${missing[*]}" >&2
  exit 1
fi

if [[ "${package}" != "PowerManagerNutEcoFlow" ]]; then
  echo "[ERROR] INFO package expected 'PowerManagerNutEcoFlow' but found '${package}'" >&2
  exit 1
fi

if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "[ERROR] INFO version '${version}' does not follow semantic versioning (x.y.z)" >&2
  exit 1
fi

echo "[OK] INFO metadata validated (package=${package}, version=${version}, arch=${arch})"
exit 0

