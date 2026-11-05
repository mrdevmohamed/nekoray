#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"
: "${DL_QT_VER:?DL_QT_VER must be 5.15 or 6.7}"

QT_ROOT="${SRC_ROOT}/qtsdk"
mkdir -p -- "${QT_ROOT}"

case "${DL_QT_VER}" in
    5.15)
        ARCHIVE="Qt5.15.7-Windows-x86_64-VS2019-16.11.20-20221103.7z"
        URL="https://github.com/MatsuriDayo/nekoray_qt_runtime/releases/download/20220503/${ARCHIVE}"
        ;;
    6.7)
        ARCHIVE="Qt6.7.2-Windows-x86_64-VS2022-17.10.3-20240621.7z"
        URL="https://github.com/MatsuriDayo/nekoray_qt_runtime/releases/download/20220503/${ARCHIVE}"
        ;;
    *)
        printf 'error: unsupported Qt SDK version: %s\n' "${DL_QT_VER}" >&2
        exit 2
        ;;
esac

curl --fail --location --silent --show-error \
    --retry 3 --retry-all-errors \
    --output "${QT_ROOT}/${ARCHIVE}" "${URL}"
(
    cd "${QT_ROOT}"
    7z x -y "${ARCHIVE}"
    rm -- "${ARCHIVE}"

    shopt -s nullglob
    qt_dirs=(Qt*)
    if (( ${#qt_dirs[@]} == 1 )) && [[ -d "${qt_dirs[0]}" ]] && [[ "${qt_dirs[0]}" != "Qt" ]]; then
        mv -- "${qt_dirs[0]}" Qt
    fi
)
