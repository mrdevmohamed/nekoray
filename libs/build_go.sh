#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"

: "${GOOS:?Set GOOS (linux or windows)}"
: "${GOARCH:?Set GOARCH (amd64 or arm64)}"

case "${GOOS}/${GOARCH}" in
    windows/amd64) DEST="${DEPLOYMENT}/windows64" ;;
    windows/arm64) DEST="${DEPLOYMENT}/windows-arm64" ;;
    linux/amd64)   DEST="${DEPLOYMENT}/linux64" ;;
    linux/arm64)   DEST="${DEPLOYMENT}/linux-arm64" ;;
    *)
        printf 'error: unsupported Go target: %s/%s\n' "${GOOS}" "${GOARCH}" >&2
        exit 2
        ;;
esac

rm -rf -- "${DEST}"
mkdir -p -- "${DEST}"

export CGO_ENABLED=0

#### Go: updater / launcher ####
if [[ "${GOOS}" != "darwin" ]]; then
    updater_binary="updater"
    if [[ "${GOOS}" == "windows" ]]; then
        updater_binary="updater.exe"
    fi

    (
        cd "${SRC_ROOT}/go/cmd/updater"
        go build -trimpath -ldflags="-w -s" -o "${DEST}/${updater_binary}" .
    )

    if [[ "${GOOS}" == "linux" ]]; then
        mv -- "${DEST}/updater" "${DEST}/launcher"
    fi
fi

#### Go: nekobox_core ####
core_binary="nekobox_core"
if [[ "${GOOS}" == "windows" ]]; then
    core_binary="nekobox_core.exe"
fi

(
    cd "${SRC_ROOT}/go/cmd/nekobox_core"
    go build -v -trimpath \
        -ldflags="-w -s -X github.com/matsuridayo/libneko/neko_common.Version_neko=${version_standalone}" \
        -tags="with_clash_api,with_gvisor,with_quic,with_wireguard,with_utls,with_ech" \
        -o "${DEST}/${core_binary}" .
)
