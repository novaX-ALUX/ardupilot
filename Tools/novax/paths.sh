# Shared FC/GNSS build path resolver. Source after ROOT_DIR and BOARD_NAME.
[[ "${BOARD_NAME}" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Invalid board name" >&2; exit 1; }
AP_ROOT="$(cd "${ENGINE_DIR}/../.." && pwd)"
if [[ -f "${ROOT_DIR}/boards/${BOARD_NAME}/ardupilot/hwdef.dat" ]]; then
    BOARD_DIR="${ROOT_DIR}/boards/${BOARD_NAME}"
    PRODUCT_BUILD_DIR="${ROOT_DIR}/build"
    RELEASE_DIR="${ROOT_DIR}/releases/${BOARD_NAME}/ardupilot"
elif [[ -f "${ROOT_DIR}/${BOARD_NAME}/firmware/ardupilot/hwdef.dat" ]]; then
    BOARD_DIR="${ROOT_DIR}/${BOARD_NAME}/firmware"
    PRODUCT_BUILD_DIR="${BOARD_DIR}/build"
    RELEASE_DIR="${BOARD_DIR}/releases/ardupilot"
else
    echo "Board not present in this product repository: ${BOARD_NAME}" >&2
    exit 1
fi
AP_BUILD_DIR="${NOVAX_AP_BUILD_DIR:-${AP_ROOT}/build}"
RELEASE_DIR="${NOVAX_RELEASE_DIR:-${RELEASE_DIR}}"
