# Shared novaX ArduPilot build tools

One independent ArduPilot checkout is shared by sibling `fc/` and `gnss/` repositories. `Tools/novax/` is the only build/sync/package implementation; product repositories contain thin entry points.

```text
workspace/
├─ fc/                  # novaX-ALUX/fc
├─ gnss/                # novaX-ALUX/gnss (private)
└─ _shared/ardupilot/    # novaX-ALUX/ardupilot, novax-workspace branch
```

The branch starts from upstream commit `92b0cd788ec29406f26c6f9c31d5ceedbd1cc538`. Existing local bootloader/GPS/signing changes are preserved uncommitted; their presence is not a reproducible release. No firmware assets are published by setup or tests.

For a **new, empty destination only**, clone the branch, then checkout the exact commit in the product's `ardupilot-source.json` before initializing recursive submodules. Never reset/pull over a dirty existing checkout.

```bash
git clone --branch novax-workspace https://github.com/novaX-ALUX/ardupilot.git _shared/ardupilot
# In a fresh checkout, select the product lock-file commit before this step:
git -C _shared/ardupilot submodule update --init --recursive
bash _shared/ardupilot/Tools/novax/install_toolchain.sh
bash fc/scripts/apply_ap_patches.sh
bash fc/scripts/build_ap.sh AF-F4_nano copter
bash gnss/scripts/apply_ap_patches.sh
bash gnss/scripts/build_ap.sh AP-RTK_G5H AP_Periph
```

Linux/WSL, Python 3, the upstream Python dependencies, **ARM GCC 10.2.1 (10-2020-q4-major)** and `flock` are required. This matches [upstream compiler setup](https://ardupilot.org/dev/docs/building-setup-linux.html) and the pinned `Tools/environment_install/install-prereqs-ubuntu.sh`. The installer uses the upstream HTTPS mirror and checks SHA-256; its user cache does not change the system compiler. `NOVAX_AP_SDK_ROOT` selects an existing 10.2.1 SDK. Other GCC versions fail closed instead of silently changing the build environment. This compiler is independent of Betaflight's pinned SDK.

`NOVAX_AP_ROOT` selects a different prepared checkout. `NOVAX_AP_BUILD_DIR` selects an isolated build output. Builds serialize access to this shared tree. Board versions remain independent; GNSS always uses `AP_Periph`.

Read-only regression: `python3 Tools/novax/test_paths.py` and `python3 Tools/novax/test_build_guards.py`. The latter checks family-specific F4/F7 DFU backup registers and rejects a bootloader helper that reports success without producing an image. Recursive submodules (including `CrashDebug/CrashCatcher`) are required by H7/F7 builds. Release approval, signing, hardware qualification and publishing remain separate gates.
