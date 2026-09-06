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
bash fc/scripts/apply_ap_patches.sh
bash fc/scripts/build_ap.sh AF-F4_nano copter
bash gnss/scripts/apply_ap_patches.sh
bash gnss/scripts/build_ap.sh AP-RTK_G5H AP_Periph
```

Linux/WSL, Python 3, the upstream Python dependencies, ARM GCC and `flock` are required. `NOVAX_AP_ROOT` selects a different prepared checkout. `NOVAX_AP_BUILD_DIR` selects an isolated build output. Builds serialize access to this shared tree. Board versions remain independent; GNSS always uses `AP_Periph`.

Read-only regression: `python3 Tools/novax/test_paths.py`. Release approval, signing, hardware qualification and publishing remain separate gates.
