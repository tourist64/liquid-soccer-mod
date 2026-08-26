import unittest
from pathlib import Path

import modloader


ROOT = Path(__file__).resolve().parents[1]


class ModloaderTests(unittest.TestCase):
    def test_multiplayer_manifest_is_valid(self):
        manifest = modloader.load_manifest(ROOT / "mods" / "multiplayer")
        self.assertEqual(manifest["id"], "multiplayer")
        resources = modloader.mod_resources(manifest)
        self.assertIn("res://Scenes/Game.gdc", resources)
        self.assertIn("res://Scenes/Global.gdc", resources)

    def test_multiplayer_and_menu_mod_conflict_on_menu_scene(self):
        multiplayer_dir = ROOT / "mods" / "multiplayer"
        menu_dir = ROOT / "mods" / "super-mod-soccer"
        multiplayer = (multiplayer_dir, modloader.load_manifest(multiplayer_dir))
        menu = (menu_dir, modloader.load_manifest(menu_dir))
        conflicts = modloader.collect_conflicts([multiplayer, menu])
        self.assertIn("res://Scenes/Menu.tscn", conflicts)


if __name__ == "__main__":
    unittest.main()
