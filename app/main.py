"""Tiny web service used to practise trunk-based development.

Endpoints:
  GET /         -> greeting (changes when the "new_greeting" feature flag is on)
  GET /health   -> {"status": "ok"}  (used by Docker, Kubernetes and CI smoke tests)
  GET /version  -> the app version and the git commit it was built from
"""
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

VERSION = "1.0.0"
FLAGS_FILE = Path(os.environ.get("FLAGS_FILE", Path(__file__).parent.parent / "config" / "flags.json"))


def load_flags():
    """Read feature flags from config/flags.json.

    An environment variable wins over the file, e.g. FLAG_NEW_GREETING=true.
    This lets you switch a feature on in one environment (dev) and keep it off in prod.
    """
    try:
        flags = json.loads(FLAGS_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        flags = {}
    for name in list(flags):
        env_value = os.environ.get(f"FLAG_{name.upper()}")
        if env_value is not None:
            flags[name] = env_value.lower() == "true"
    return flags


def greeting(flags):
    if flags.get("new_greeting"):
        return "Welcome to Luul Solutions platform!"
    return "Hello from Luul Solutions"


def route(path):
    """Return (status_code, body_dict) for a request path."""
    if path == "/health":
        return 200, {"status": "ok"}
    if path == "/version":
        return 200, {"app": "luul-trunk-lab", "version": VERSION, "commit": os.environ.get("GIT_SHA", "local")}
    if path == "/":
        return 200, {"message": greeting(load_flags())}
    return 404, {"error": "path not found"}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, body = route(self.path)
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    port = int(os.environ.get("PORT", "8080"))
    print(f"luul-trunk-lab v{VERSION} listening on :{port}")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
