#!/usr/bin/env bash
set -euo pipefail

ENGINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${NOVAX_PRODUCT_ROOT:?Set NOVAX_PRODUCT_ROOT to the FC or GNSS repository}"
BOARD_NAME="${1:-AF-F4_nano}"

source "${ENGINE_DIR}/paths.sh"
BOARD_CONFIG_DIR="${BOARD_DIR}/ardupilot"
BOARD_INCLUDE_LINK="${BOARD_DIR}/include"
AP_HWDEF_ROOT="${AP_ROOT}/libraries/AP_HAL_ChibiOS/hwdef"
AP_INCLUDE_DIR="${AP_HWDEF_ROOT}/include"
TARGET_LINK="${AP_HWDEF_ROOT}/${BOARD_NAME}"

if [[ ! -d "${BOARD_CONFIG_DIR}" ]]; then
    echo "Board config directory not found: ${BOARD_CONFIG_DIR}" >&2
    exit 1
fi

mkdir -p "${AP_HWDEF_ROOT}"

# Create or update a symlink using a relative target path for portability.
ensure_link() {
    local link_path="$1"
    local target_abs="$2"
    local link_dir
    link_dir="$(dirname "${link_path}")"
    local rel_target
    rel_target="$(realpath --relative-to="${link_dir}" "${target_abs}")"

    if [[ -L "${link_path}" ]]; then
        if [[ "$(readlink "${link_path}")" == "${rel_target}" ]]; then
            return 0
        fi
        rm "${link_path}"
    elif [[ -e "${link_path}" ]]; then
        echo "Refusing to overwrite non-symlink path: ${link_path}" >&2
        return 1
    fi
    ln -s "${rel_target}" "${link_path}"
}

ensure_link "${BOARD_INCLUDE_LINK}" "${AP_INCLUDE_DIR}"
ensure_link "${TARGET_LINK}" "${BOARD_CONFIG_DIR}"
echo "Synced ${BOARD_NAME} to ${TARGET_LINK}"
