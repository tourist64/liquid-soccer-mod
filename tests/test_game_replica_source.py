from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "source/advanced/Scenes/Game.gd"


class GameReplicaSourceTests(unittest.TestCase):
    def test_client_builds_and_renders_the_local_game_scene(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertNotIn("Global.multiplayer_mode and not Global.multiplayer_host:\n\t\tset_process(false)", source)
        self.assertIn("func _mp_enable_replica():", source)
        self.assertIn("func _mp_apply_replica_state():", source)

    def test_host_publishes_ball_players_and_score(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("func _mp_publish_replica_state(delta):", source)
        self.assertIn('"players": players', source)
        self.assertIn('"score": [score.x, score.y]', source)

    def test_replica_stops_all_simulation_timers(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("func _mp_stop_replica_simulation(node):", source)
        self.assertIn("_mp_stop_replica_simulation(self)", source)

    def test_host_consumes_client_controls_directly(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("MP_REMOTE_KEYS_EXPRESSION", source)
        self.assertIn("func _mp_apply_remote_controls():", source)
        self.assertIn("Input.action_press(action)", source)

    def test_replica_stops_all_simulation_timers(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("func _mp_stop_replica_simulation(node):", source)
        self.assertIn("_mp_stop_replica_simulation(self)", source)

    def test_host_consumes_client_controls_without_synthetic_keyboard_events(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("MP_REMOTE_KEYS_EXPRESSION", source)
        self.assertIn("func _mp_apply_remote_controls():", source)
        self.assertIn("Input.action_press(action)", source)


if __name__ == "__main__":
    unittest.main()
