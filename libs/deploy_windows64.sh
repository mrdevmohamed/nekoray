#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"

: "${DL_QT_VER:?DL_QT_VER must identify the Qt SDK version}"

DEST="${DEPLOYMENT}/windows64"
rm -rf -- "${DEST}"
mkdir -p -- "${DEST}"

#### Copy executable ####
if [[ ! -f "${BUILD}/nekobox.exe" ]]; then
    printf 'error: C++ executable is missing: %s\n' "${BUILD}/nekobox.exe" >&2
    exit 1
fi
cp -- "${BUILD}/nekobox.exe" "${DEST}/"

#### Deploy Qt and DLL runtime ####
(
    cd "${DEST}"
    windeployqt nekobox.exe --no-compiler-runtime --no-system-d3d-compiler --no-opengl-sw --verbose 2
    rm -rf -- translations
    rm -f -- libEGL.dll libGLESv2.dll Qt6Pdf.dll

    if [[ "${DL_QT_VER}" != "5.15" ]]; then
        cp -- "${SRC_ROOT}/qtsdk/Qt/bin/libcrypto-3-x64.dll" .
        cp -- "${SRC_ROOT}/qtsdk/Qt/bin/libssl-3-x64.dll" .
    fi
)

#### Copy optional debug symbols ####
shopt -s nullglob
pdb_files=("${BUILD}"/*.pdb)
if (( ${#pdb_files[@]} > 0 )); then
    cp -- "${pdb_files[@]}" "${DEPLOYMENT}/"
fi
