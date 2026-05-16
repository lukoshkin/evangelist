import tempfile
import unittest
from pathlib import Path

from convert.adapters import copilot
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "init-docs"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: init-docs\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="init-docs", directory=skill_dir)],
        commands=[Command(name="git_commit", frontmatter={}, body="compose a commit\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCopilotAdapter(unittest.TestCase):
    def test_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = copilot.convert(_sources(root), home)

        self.assertEqual(conv.tool, "copilot")
        self.assertIn(home / ".copilot" / "skills" / "init-docs", conv.trees)
        skill_md = home / ".copilot" / "skills" / "git-commit" / "SKILL.md"
        self.assertIn(skill_md, conv.files)
        self.assertIn("name: git-commit", conv.files[skill_md])
        self.assertIn(home / ".copilot" / "copilot-instructions.md", conv.files)


if __name__ == "__main__":
    unittest.main()
