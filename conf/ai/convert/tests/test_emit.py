import tempfile
import unittest
from pathlib import Path

from convert.emit import Conversion, emit, read_manifest


class TestEmit(unittest.TestCase):
    def test_writes_files_and_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            conv = Conversion(tool="codex", tool_root=root / "cfg")
            conv.files[root / "out" / "a.md"] = "alpha"
            emit(conv, dry_run=False)

            self.assertEqual((root / "out" / "a.md").read_text(), "alpha")
            self.assertEqual(read_manifest(root / "cfg"), [root / "out" / "a.md"])

    def test_prunes_files_dropped_since_last_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first = Conversion(tool="codex", tool_root=root / "cfg")
            first.files[root / "out" / "old.md"] = "x"
            emit(first, dry_run=False)

            second = Conversion(tool="codex", tool_root=root / "cfg")
            second.files[root / "out" / "new.md"] = "y"
            emit(second, dry_run=False)

            self.assertFalse((root / "out" / "old.md").exists())
            self.assertTrue((root / "out" / "new.md").exists())

    def test_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            conv = Conversion(tool="codex", tool_root=root / "cfg")
            conv.files[root / "out" / "a.md"] = "alpha"
            emit(conv, dry_run=True)

            self.assertFalse((root / "out" / "a.md").exists())


if __name__ == "__main__":
    unittest.main()
