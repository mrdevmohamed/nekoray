#!/usr/bin/env bash

_NKR_ENV_DEPLOY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_ROOT="$(cd -- "${_NKR_ENV_DEPLOY_DIR}/.." && pwd -P)"
_VERSION_FILE="${SRC_ROOT}/nekoray_version.txt"

if [[ ! -r "${_VERSION_FILE}" ]]; then
    printf 'error: version file is missing: %s\n' "${_VERSION_FILE}" >&2
    return 1 2>/dev/null || exit 1
fi

_version="$(< "${_VERSION_FILE}")"
if [[ -z "${_version//[[:space:]]/}" ]]; then
    printf 'error: version file is empty: %s\n' "${_VERSION_FILE}" >&2
    return 1 2>/dev/null || exit 1
fi

DEPLOYMENT="${SRC_ROOT}/deployment"
BUILD="${SRC_ROOT}/build"
version_standalone="nekoray-${_version}"

export SRC_ROOT DEPLOYMENT BUILD version_standalone

unset _NKR_ENV_DEPLOY_DIR _VERSION_FILE _version
