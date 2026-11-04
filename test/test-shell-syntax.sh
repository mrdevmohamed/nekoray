#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

while IFS= read -r -d '' script; do
    printf 'Checking shell syntax: %s\n' "${script#"$ROOT"/}"
    bash -n "$script"
done < <(find "$ROOT/libs" "$ROOT/test" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)

printf 'All shell scripts passed bash -n.\n'
