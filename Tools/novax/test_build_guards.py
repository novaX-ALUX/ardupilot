"""Failure-path regressions in isolated temporary fixtures, without hardware."""
import os
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory
import unittest

ENGINE = Path(__file__).resolve().parent


class BuildGuardsTest(unittest.TestCase):
    def test_wrong_or_missing_compiler_fails_closed(self):
        with TemporaryDirectory(prefix="novax-sdk-test-") as directory:
            root = Path(directory)
            compiler = root / "bin/arm-none-eabi-gcc"
            compiler.parent.mkdir()
            for version in (None, "13.2.1", "10.2.1"):
                if version:
                    compiler.write_text(f"#!/bin/sh\nprintf '{version}\\n'\n")
                    compiler.chmod(0o755)
                result = subprocess.run(["bash", str(ENGINE / "toolchain.sh")],
                                        env=dict(os.environ, NOVAX_AP_SDK_ROOT=str(root)),
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode == 0, version == "10.2.1", result.stderr)

    def test_empty_bootloader_helper_success_is_rejected(self):
        with TemporaryDirectory(prefix="novax-bootloader-guard-") as directory:
            root = Path(directory)
            engine = root / "ap/Tools/novax"
            engine.mkdir(parents=True)
            for name in ("build_ap.sh", "paths.sh", "sync_ap_board.sh", "toolchain.sh"):
                shutil.copyfile(ENGINE / name, engine / name)
            board = root / "fc/boards/AF-Test/ardupilot"
            board.mkdir(parents=True)
            (board / "hwdef.dat").touch()
            (root / "ap/libraries/AP_HAL_ChibiOS/hwdef/include").mkdir(parents=True)
            helper = root / "ap/Tools/scripts/build_bootloaders.py"
            helper.parent.mkdir(parents=True)
            helper.write_text('print("Failed boards: AF-Test")\n')
            compiler = root / "sdk/bin/arm-none-eabi-gcc"
            compiler.parent.mkdir(parents=True)
            compiler.write_text("#!/bin/sh\nprintf '10.2.1\\n'\n")
            compiler.chmod(0o755)
            env = dict(os.environ, NOVAX_PRODUCT_ROOT=str(root / "fc"), NOVAX_AP_SDK_ROOT=str(root / "sdk"))
            result = subprocess.run(["bash", str(engine / "build_ap.sh"), "AF-Test"],
                                    env=env, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Bootloader build produced no image", result.stderr)
            self.assertNotIn("novaX firmware string", result.stdout)

    def test_dfu_backup_registers_are_family_specific(self):
        patch = (ENGINE / "patches/0001-novax-software-dfu-board.patch").read_text()
        branch = "\n".join(line[1:] for line in patch.splitlines() if line.startswith("+") and not line.startswith("+++"))
        begin = branch.index("#if defined(STM32F4) || defined(STM32F7)")
        end = branch.index("          pd.boot_to_dfu = 0;", begin)
        for family, wanted, forbidden in (("STM32F4", "PWR->CR |= PWR_CR_DBP", "PWR->CR1"),
                                           ("STM32F7", "PWR->CR1 |= PWR_CR1_DBP", "PWR->CR |=")):
            result = subprocess.run(["gcc", "-E", "-P", "-x", "c", f"-D{family}", "-"],
                                    input=branch[begin:end], capture_output=True, text=True, check=True)
            self.assertIn(wanted, result.stdout)
            self.assertNotIn(forbidden, result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
