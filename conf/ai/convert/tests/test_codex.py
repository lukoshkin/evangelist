import tempfile
import unittest
from pathlib import Path

from convert.adapters import codex
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "demo"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: demo\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="demo", directory=skill_dir)],
        commands=[Command(name="ensure_code_quality",
                          frontmatter={"description": "QA pass"}, body="do qa\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCodexAdapter(unittest.TestCase):
    def test_skill_command_and_instructions_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = codex.convert(_sources(root), home)

        self.assertEqual(conv.tool, "codex")
        self.assertIn(home / ".agents" / "skills" / "demo", conv.trees)
        skill_md = home / ".agents" / "skills" / "ensure-code-quality" / "SKILL.md"
        self.assertIn(skill_md, conv.files)
        self.assertIn("name: ensure-code-quality", conv.files[skill_md])
        self.assertIn("description: QA pass", conv.files[skill_md])
        self.assertIn("do qa", conv.files[skill_md])
        self.assertIn(home / ".codex" / "AGENTS.md", conv.files)
        self.assertTrue(conv.notes)


if __name__ == "__main__":
    unittest.main()
