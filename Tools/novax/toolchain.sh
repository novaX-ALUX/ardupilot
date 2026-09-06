# Sourced by the canonical builder. Never fall back silently to system GCC.
AP_SDK="${NOVAX_AP_SDK_ROOT:-${XDG_CACHE_HOME:-$HOME/.cache}/novax/toolchains/gcc-arm-none-eabi-10-2020-q4-major}"
if [[ ! -x "$AP_SDK/bin/arm-none-eabi-gcc" ]]; then
    echo 'Install the upstream-pinned compiler: bash Tools/novax/install_toolchain.sh' >&2
    echo 'Or set NOVAX_AP_SDK_ROOT to an existing GCC 10.2.1 toolchain.' >&2
    exit 1
fi
[[ "$("$AP_SDK/bin/arm-none-eabi-gcc" -dumpfullversion)" == 10.2.1 ]] || {
    echo 'ArduPilot requires the upstream GCC 10.2.1 toolchain' >&2; exit 1;
}
export PATH="$AP_SDK/bin:$PATH"
