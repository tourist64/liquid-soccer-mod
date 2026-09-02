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
        self.assertIn("player.AI.astate", source)
        self.assertIn('"referee":', source)

    def test_replica_freezes_only_authoritative_physics(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertNotIn("_mp_stop_replica_simulation(self)", source)
        self.assertIn("set_process(true)", source[source.index("func _mp_enable_replica():"):source.index("func _mp_apply_remote_controls():")])
        self.assertIn("player._mp_apply_visual_state", source)
        self.assertIn("func _mp_apply_replica_presentation():", source)

    def test_replica_receives_visual_state_with_authoritative_snapshot(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("_mp_apply_referee_state", source)

    def test_replica_does_not_reset_camera_on_every_snapshot(self):
        source = SOURCE.read_text(encoding="utf-8")
        presentation = source[source.index("func _mp_apply_replica_presentation():"):source.index("func _noop():")]
        self.assertIn("mp_last_presented_state", source)
        self.assertIn("if mp_last_presented_state == state:", presentation)

    def test_replica_applies_state_on_render_process(self):
        source = SOURCE.read_text(encoding="utf-8")
        process = source[source.index("func _process(delta):"):source.index("func _physics_process(delta):")]
        self.assertIn("if mp_replica:", process)
        self.assertIn("_mp_apply_replica_state()", process)

    def test_player_keeps_movement_animation_synced_after_physics(self):
        player_source = SOURCE.parent.joinpath("Player.gd").read_text(encoding="utf-8")
        self.assertIn("func _update_movement_animation():", player_source)
        physics = player_source[player_source.index("func _physics_process(delta):"):player_source.index("func _mp_apply_visual_state(animation):")]
        self.assertIn("_update_movement_animation()", physics)
        self.assertIn("myATree.active = true", player_source)

    def test_host_consumes_client_controls_without_synthetic_keyboard_events(self):
        source = SOURCE.read_text(encoding="utf-8")
        self.assertIn("MP_REMOTE_KEYS_EXPRESSION", source)
        self.assertIn("func _mp_apply_remote_controls():", source)
        self.assertIn("Input.action_press(action)", source)


if __name__ == "__main__":
    unittest.main()
