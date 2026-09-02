from pathlib import Path
import importlib.util
import tempfile
import unittest

from modloader import read_pck


ROOT = Path(__file__).resolve().parents[1]
BUILDER_PATH = ROOT / "tools/build_remaster.py"


class RemasterBuilderTests(unittest.TestCase):
    def test_merges_complete_base_assets_with_source_export(self):
        spec = importlib.util.spec_from_file_location("build_remaster", BUILDER_PATH)
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "index.pck"
            builder.merge_resource_packs(
                ROOT / "game3/index-mod.pck",
                ROOT / "game3/index.pck",
                output,
            )
            _, entries = read_pck(output)

        paths = {entry.path for entry in entries}
        self.assertIn("res://.import/Stadium.dae-340233f45e44b5d5f187323342b55482.scn", paths)
        self.assertIn("res://Scenes/Game.gdc", paths)


if __name__ == "__main__":
    unittest.main()
