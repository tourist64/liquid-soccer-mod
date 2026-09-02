from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "source/advanced/Scenes/TeamSelect.gd"


class TeamSelectMultiplayerSourceTests(unittest.TestCase):
    def test_publishes_team_selection_realtime(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("const MP_SYNC_INTERVAL = 0.05", source)
        self.assertIn("if mp_elapsed < MP_SYNC_INTERVAL:", source)
        self.assertIn("func _mp_publish_current_selection():", source)
        self.assertIn("_mp_publish_current_selection()", source)

    def test_separates_state_reading_application_and_ui(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("func _mp_read_state():", source)
        self.assertIn("func _mp_apply_shared_state(state):", source)
        self.assertIn("func _mp_update_selection_ui(state):", source)

    def test_shows_only_the_local_players_team_selector(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("func _mp_configure_single_team_selector():", source)
        self.assertIn("opponent_selector.visible = false", source)

    def test_both_players_enter_the_game_scene_after_confirmation(self):
        source = SOURCE.read_text(encoding="utf-8")
        start = source.index("func _start_multiplayer_game():")
        end = source.index("func _js_string", start)
        self.assertNotIn("if not mp_host:", source[start:end])

    def test_only_host_can_confirm_and_start_the_match(self):
        source = SOURCE.read_text(encoding="utf-8")
        ui_start = source.index("func _mp_update_selection_ui(state):")
        ui_end = source.index("func _setup_multiplayer():", ui_start)
        self.assertIn("$TextureRect / GoGame.disabled = not teams_received", source[ui_start:ui_end])
        self.assertIn("$TextureRect / GoGame.disabled = true", source[ui_start:ui_end])


if __name__ == "__main__":
    unittest.main()
