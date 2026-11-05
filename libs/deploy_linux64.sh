#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"

DEST="${DEPLOYMENT}/linux64"
rm -rf -- "${DEST}"
mkdir -p -- "${DEST}"

#### Copy binary ####
if [[ ! -f "${BUILD}/nekobox" ]]; then
    printf 'error: C++ executable is missing: %s\n' "${BUILD}/nekobox" >&2
    exit 1
fi
cp -- "${BUILD}/nekobox" "${DEST}/"

#### Download and unpack the pinned Qt runtime bundle ####
WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "${WORK_DIR}"' EXIT

RUNTIME_ARCHIVE="${WORK_DIR}/qt-runtime.zip"
curl --fail --location --silent --show-error \
    --retry 3 --retry-all-errors \
    --output "${RUNTIME_ARCHIVE}" \
    "https://github.com/MatsuriDayo/nekoray_qt_runtime/releases/download/20220503/20230202-5.12.8-ubuntu20.04-linux64.zip"

unzip -q "${RUNTIME_ARCHIVE}" -d "${WORK_DIR}"
if [[ ! -d "${WORK_DIR}/usr" ]]; then
    printf 'error: Qt runtime archive did not contain the expected usr/ directory\n' >&2
    exit 1
fi
mv -- "${WORK_DIR}/usr" "${DEST}/usr"
