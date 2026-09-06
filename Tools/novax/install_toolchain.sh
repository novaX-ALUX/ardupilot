#!/usr/bin/env bash
# Same x86_64 Linux compiler as upstream install-prereqs-ubuntu.sh, without sudo.
set -euo pipefail
[[ "$(uname -sm)" == 'Linux x86_64' ]] || { echo 'Use upstream platform setup for this OS/architecture' >&2; exit 1; }
cache="${XDG_CACHE_HOME:-$HOME/.cache}/novax/toolchains"
name=gcc-arm-none-eabi-10-2020-q4-major
mkdir -p "$cache"
exec 8>"$cache/.install.lock"
flock -n 8 || { echo 'Toolchain installation is already running' >&2; exit 1; }
if [[ -e "$cache/$name" ]]; then
    [[ -x "$cache/$name/bin/arm-none-eabi-gcc" ]] || { echo 'Incomplete existing SDK; preserve and inspect it' >&2; exit 1; }
else
    archive=$(mktemp "$cache/ap-sdk-XXXXXX.tar.bz2")
    curl --fail --location --proto '=https' --tlsv1.2 \
        "https://firmware.ardupilot.org/Tools/STM32-tools/$name-x86_64-linux.tar.bz2" \
        --output "$archive"
    [[ "$(stat -c %s "$archive")" == 156882554 ]] || { echo 'Unexpected official archive size' >&2; exit 1; }
    # SHA-256 of the fixed archive served by the upstream HTTPS toolchain mirror.
    printf '21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618  %s\n' "$archive" | sha256sum --check -
    tar xjf "$archive" -C "$cache"
fi
[[ "$("$cache/$name/bin/arm-none-eabi-gcc" -dumpfullversion)" == 10.2.1 ]] || exit 1
echo "ArduPilot compiler ready: $cache/$name"
