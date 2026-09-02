from pathlib import Path
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "game3/multiplayer-bridge.js"


class MultiplayerBridgeSourceTests(unittest.TestCase):
    def test_host_releases_remote_controls_when_channel_closes(self):
        source = SOURCE.read_text(encoding="utf-8")
        reset_start = source.index("function resetRemoteControls")
        reset_end = source.index("function bindDataChannel", reset_start)
        close_start = source.index("channel.onclose = () => {")
        close_end = source.index("};", close_start) + 2
        reset_body = source[reset_start:reset_end]
        close_body = source[close_start:close_end]
        self.assertIn("if (!isHost) return", reset_body)
        self.assertIn("remoteKeyQueue.push(protocol.controlMessage(code, false))", reset_body)
        self.assertIn("resetRemoteControls(isHost)", close_body)


if __name__ == "__main__":
    unittest.main()
