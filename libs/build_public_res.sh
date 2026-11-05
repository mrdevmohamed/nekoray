#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"

DEST="${DEPLOYMENT}/public_res"
rm -rf -- "${DEST}"
mkdir -p -- "${DEST}"

download_file() {
    local filename="$1"
    local url="$2"
    curl --fail --location --silent --show-error \
        --retry 3 --retry-all-errors \
        --output "${DEST}/${filename}" "${url}"
}

#### Download geodata ####
download_file "geoip.dat" "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
download_file "geosite.dat" "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
download_file "geoip.db" "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
download_file "geosite.db" "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db"

#### Copy public resources ####
if [[ ! -d "${SRC_ROOT}/res/public" ]]; then
    printf 'error: public resource directory is missing: %s\n' "${SRC_ROOT}/res/public" >&2
    exit 1
fi
cp -a -- "${SRC_ROOT}/res/public/." "${DEST}/"
