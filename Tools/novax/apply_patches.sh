#!/usr/bin/env bash
# Explicit, idempotent preparation. Conflicts fail closed; no reset or checkout.
set -euo pipefail
ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_ROOT="$(cd "${ENGINE_DIR}/../.." && pwd)"
exec 9>"${AP_ROOT}/.novax-build.lock"
flock -n 9 || { echo 'Shared source is busy' >&2; exit 1; }
for patch in "${ENGINE_DIR}"/patches/*.patch; do
    if git -C "${AP_ROOT}" apply --reverse --check "${patch}" >/dev/null 2>&1; then
        echo "already applied: $(basename "${patch}")"
    elif [[ "${1:-}" == --check ]]; then
        echo "Required patch not applied: ${patch}" >&2
        exit 1
    elif git -C "${AP_ROOT}" apply --check "${patch}"; then
        git -C "${AP_ROOT}" apply "${patch}"
    else
        echo "Patch conflict; preserve existing work and resolve explicitly: ${patch}" >&2
        exit 1
    fi
done
