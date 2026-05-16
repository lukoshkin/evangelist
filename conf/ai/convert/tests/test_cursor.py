import tempfile
import unittest
from pathlib import Path

from convert.adapters import cursor
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "changelog"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: changelog\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="changelog", directory=skill_dir)],
        commands=[Command(name="code_checks",
                          frontmatter={"description": "lint"}, body="run ruff\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCursorAdapter(unittest.TestCase):
    def test_commands_are_native_skills_are_copied(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = cursor.convert(_sources(root), home)

        self.assertEqual(conv.tool, "cursor")
        self.assertIn(home / ".cursor" / "skills" / "changelog", conv.trees)
        cmd_file = home / ".cursor" / "commands" / "code_checks.md"
        self.assertIn(cmd_file, conv.files)
        self.assertEqual(conv.files[cmd_file], "run ruff\n")
        self.assertNotIn(home / ".cursor" / "AGENTS.md", conv.files)
        self.assertTrue(conv.notes)


if __name__ == "__main__":
    unittest.main()
