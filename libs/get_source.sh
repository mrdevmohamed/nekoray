#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env_deploy.sh"
source "${SCRIPT_DIR}/get_source_env.sh"

WORKSPACE_ROOT="$(cd -- "${SRC_ROOT}/.." && pwd -P)"

checkout_pinned_source() {
    local name="$1"
    local repository="$2"
    local revision="$3"
    local destination="${WORKSPACE_ROOT}/${name}"
    local created="false"
    local origin
    local actual_revision

    if [[ ! "${revision}" =~ ^[0-9a-fA-F]{40}$ ]]; then
        printf 'error: %s revision is not a full Git commit ID: %s\n' "${name}" "${revision}" >&2
        return 1
    fi

    if [[ ! -e "${destination}/.git" ]]; then
        if [[ -e "${destination}" ]]; then
            printf 'error: refusing to use non-Git dependency path: %s\n' "${destination}" >&2
            return 1
        fi
        git clone --no-checkout "${repository}" "${destination}"
        created="true"
    fi

    if ! git -C "${destination}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf 'error: dependency path is not a Git worktree: %s\n' "${destination}" >&2
        return 1
    fi

    origin="$(git -C "${destination}" remote get-url origin)"
    if [[ "${origin}" != "${repository}" ]]; then
        printf 'error: %s has unexpected origin %s (expected %s)\n' "${name}" "${origin}" "${repository}" >&2
        return 1
    fi

    if [[ "${created}" != "true" ]] && [[ -n "$(git -C "${destination}" status --porcelain)" ]]; then
        printf 'error: %s has local changes; refusing to overwrite them\n' "${destination}" >&2
        return 1
    fi

    git -C "${destination}" fetch --no-tags origin "${revision}"
    git -C "${destination}" checkout --detach "${revision}"

    actual_revision="$(git -C "${destination}" rev-parse HEAD)"
    if [[ "${actual_revision}" != "${revision}" ]]; then
        printf 'error: %s checkout mismatch: expected %s, got %s\n' "${name}" "${revision}" "${actual_revision}" >&2
        return 1
    fi

    printf 'Pinned %s at %s\n' "${name}" "${actual_revision}"
}

: "${COMMIT_SING_BOX:?COMMIT_SING_BOX is not set}"
: "${COMMIT_SING_QUIC:?COMMIT_SING_QUIC is not set}"
: "${COMMIT_LIBNEKO:?COMMIT_LIBNEKO is not set}"

checkout_pinned_source "sing-box" "${SING_BOX_REPO}" "${COMMIT_SING_BOX}"
checkout_pinned_source "sing-quic" "${SING_QUIC_REPO}" "${COMMIT_SING_QUIC}"
checkout_pinned_source "libneko" "${LIBNEKO_REPO}" "${COMMIT_LIBNEKO}"
