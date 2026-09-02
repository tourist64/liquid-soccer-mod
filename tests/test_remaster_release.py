from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class RemasterReleaseTests(unittest.TestCase):
    def test_index_uses_the_native_remaster_pack(self):
        html = (ROOT / "game3/index.html").read_text(encoding="utf-8")
        match = re.search(r'"fileSizes":\{"index\.pck":(\d+)', html)
        self.assertIsNotNone(match)
        self.assertEqual(int(match.group(1)), (ROOT / "game3/index.pck").stat().st_size)
        self.assertIn('"executable":"index"', html)
        self.assertNotIn("index-mod.pck", html)

    def test_pages_builds_the_pack_from_the_canonical_source(self):
        workflow = (ROOT / ".github/workflows/pages.yml").read_text(encoding="utf-8")
        self.assertIn("source/advanced", workflow)
        self.assertIn("--export-pack", workflow)
        self.assertIn("tools/build_remaster.py", workflow)
        self.assertIn("game3/index-mod.pck", workflow)
        self.assertIn("game3/index.pck", workflow)


if __name__ == "__main__":
    unittest.main()
