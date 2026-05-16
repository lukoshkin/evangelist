import tempfile
import unittest
from pathlib import Path

from convert.sources import discover


class TestDiscover(unittest.TestCase):
    def _build(self, root: Path) -> None:
        claude = root / "claude"
        (claude / "skills" / "demo").mkdir(parents=True)
        (claude / "skills" / "demo" / "SKILL.md").write_text(
            "---\nname: demo\ndescription: a demo\n---\nbody\n"
        )
        (claude / "commands").mkdir()
        (claude / "commands" / "do_it.md").write_text(
            "---\ndescription: does it\n---\nthe command body\n"
        )
        (claude / "commands" / "bare.md").write_text("just a body line\n")
        (claude / "scripts").mkdir()
        (claude / "CLAUDE.md").write_text("global instructions\n")

    def test_discovers_all_artifact_kinds(self):
        with tempfile.TemporaryDirectory() as tmp:
            claude = Path(tmp) / "claude"
            self._build(Path(tmp))
            src = discover(claude)

        self.assertEqual([s.name for s in src.skills], ["demo"])
        self.assertEqual(sorted(c.name for c in src.commands), ["bare", "do_it"])
        do_it = next(c for c in src.commands if c.name == "do_it")
        self.assertEqual(do_it.frontmatter["description"], "does it")
        self.assertEqual(do_it.body, "the command body\n")
        bare = next(c for c in src.commands if c.name == "bare")
        self.assertEqual(bare.frontmatter, {})
        self.assertEqual(bare.body, "just a body line\n")
        self.assertIsNotNone(src.instructions)
        self.assertIsNotNone(src.scripts_dir)


if __name__ == "__main__":
    unittest.main()
