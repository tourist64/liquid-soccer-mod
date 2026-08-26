#!/usr/bin/env python3
"""Local game server that also receives multiplayer debug logs."""

from argparse import ArgumentParser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock


ROOT = Path(__file__).resolve().parents[1] / "game3"
LOG_FILE = ROOT / "multiplayer.log"
LOG_LOCK = Lock()


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def setup(self):
        super().setup()
        self.connection.settimeout(5)

    def do_POST(self):
        if self.path != "/__sls_log":
            self.send_error(404)
            return
        size = int(self.headers.get("Content-Length", "0"))
        message = self.rfile.read(size).decode("utf-8", "replace")
        with LOG_LOCK, LOG_FILE.open("a", encoding="utf-8") as log_file:
            log_file.write(message)
        self.send_response(204)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, format, *args):
        if self.path != "/__sls_log":
            super().log_message(format, *args)


def main():
    parser = ArgumentParser(description="Serve game3 and save multiplayer logs")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    LOG_FILE.touch(exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Game: http://127.0.0.1:{args.port}/index-mod.html")
    print(f"Logs: {LOG_FILE}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
