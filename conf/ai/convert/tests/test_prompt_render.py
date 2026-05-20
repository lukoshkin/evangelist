import tempfile
import unittest
from pathlib import Path

from convert import prompt_render


class TestPromptRender(unittest.TestCase):
    def test_renders_tool_specific_guidance(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ai_dir = root / "ai"
            template = ai_dir / "convert" / "prompts" / "delegate.md.tmpl"
            extra = ai_dir / "convert" / "prompts" / "extras" / "copilot-delegate.md"
            template.parent.mkdir(parents=True)
            extra.parent.mkdir(parents=True)
            template.write_text("hello @TOOL@\n@TOOL_EXTRA_GUIDANCE@")
            extra.write_text("copilot-only\n")

            rendered = prompt_render.render_prompt(
                template_path=template,
                ai_dir=ai_dir,
                tool="copilot",
                phase="delegate",
                replacements={"TOOL": "copilot"},
            )

        self.assertEqual(rendered, "hello copilot\ncopilot-only\n")

    def test_omits_missing_tool_specific_guidance(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ai_dir = root / "ai"
            template = ai_dir / "convert" / "prompts" / "finalize.md.tmpl"
            template.parent.mkdir(parents=True)
            template.write_text("hello @TOOL@\n@TOOL_EXTRA_GUIDANCE@")

            rendered = prompt_render.render_prompt(
                template_path=template,
                ai_dir=ai_dir,
                tool="cursor",
                phase="finalize",
                replacements={"TOOL": "cursor"},
            )

        self.assertEqual(rendered, "hello cursor\n")

    def test_rejects_unresolved_placeholders(self):
        with self.assertRaisesRegex(ValueError, "UNRESOLVED"):
            prompt_render.render_template("hello @UNRESOLVED@", {})


if __name__ == "__main__":
    unittest.main()
