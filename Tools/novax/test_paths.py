"""Read-only path regression; only isolated temporary fixture files are created."""
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest

ENGINE = Path(__file__).resolve().parent


class ProductPathsTest(unittest.TestCase):
    def resolve(self, root, name):
        return subprocess.run([
            "bash", "-c",
            'ENGINE_DIR="$1"; ROOT_DIR="$2"; BOARD_NAME="$3"; '
            'source "$ENGINE_DIR/paths.sh"; '
            'printf "%s\\n" "$AP_ROOT" "$BOARD_DIR" "$RELEASE_DIR"',
            "paths-test", str(ENGINE), str(root), name,
        ], text=True, capture_output=True)

    def test_fc_paths(self):
        with TemporaryDirectory(prefix="novax-fc-") as folder:
            root = Path(folder)
            definition = root / "boards/AF-Test/ardupilot/hwdef.dat"
            definition.parent.mkdir(parents=True)
            definition.touch()
            result = self.resolve(root, "AF-Test")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines()[1:], [
                str(root / "boards/AF-Test"), str(root / "releases/AF-Test/ardupilot")])

    def test_gnss_paths(self):
        with TemporaryDirectory(prefix="novax-gnss-") as folder:
            root = Path(folder)
            definition = root / "AP-RTK_Test/firmware/ardupilot/hwdef.dat"
            definition.parent.mkdir(parents=True)
            definition.touch()
            result = self.resolve(root, "AP-RTK_Test")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines()[1:], [
                str(root / "AP-RTK_Test/firmware"),
                str(root / "AP-RTK_Test/firmware/releases/ardupilot")])

    def test_missing_board_fails(self):
        with TemporaryDirectory(prefix="novax-missing-") as folder:
            result = self.resolve(folder, "AP-RTK_Missing")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("not present", result.stderr)

    def test_traversal_fails(self):
        for name in ("../fc", "", "AP-RTK_*/test", "test;echo"):
            self.assertNotEqual(self.resolve(ENGINE, name).returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
