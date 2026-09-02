from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "source/advanced/Scenes/Team.gd"


class TeamSourceTests(unittest.TestCase):
    def test_setup_formation_resets_both_formation_buffers(self):
        source = SOURCE.read_text(encoding="utf-8")
        start = source.index("func setupFormation():")
        body = source[start:source.index("func setPlayerParams", start)]
        self.assertIn("formation.clear()", body)
        self.assertIn("cformation.clear()", body)


if __name__ == "__main__":
    unittest.main()
