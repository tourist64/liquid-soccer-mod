#!/usr/bin/env python3
"""Local game server that also receives multiplayer debug logs."""

from argparse import ArgumentParser
import http.client
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
        if self.path.startswith("/signal/"):
            self.proxy_signal("POST")
            return
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

    def do_GET(self):
        if self.path == "/signal" or self.path.startswith("/signal/"):
            self.proxy_signal("GET")
            return
        super().do_GET()

    def end_headers(self):
        if getattr(self, "path", "").split("?", 1)[0].endswith((".html", ".js", ".pck", ".wasm")):
            self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def proxy_signal(self, method):
        client = http.client.HTTPConnection("127.0.0.1", 9000, timeout=5)
        try:
            path = self.path[len("/signal"):] or "/"
            body = None
            headers = {"Host": "127.0.0.1:9000"}
            if method == "POST":
                size = int(self.headers.get("Content-Length", "0"))
                body = self.rfile.read(size)
                headers["Content-Type"] = self.headers.get("Content-Type", "application/json")
                headers["Content-Length"] = str(len(body))
            client.request(method, path, body=body, headers=headers)
            response = client.getresponse()
            body = response.read()
            self.send_response(response.status, response.reason)
            for name, value in response.getheaders():
                if name.lower() not in {"connection", "transfer-encoding"}:
                    self.send_header(name, value)
            self.end_headers()
            self.wfile.write(body)
        except OSError:
            self.send_error(502, "PeerServer indisponível")
        finally:
            client.close()

    def log_message(self, format, *args):
        if getattr(self, "path", "") != "/__sls_log":
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
