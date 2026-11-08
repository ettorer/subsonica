#!/usr/bin/env python3
"""Serve the Subsonica web build and forward /rest to local Navidrome.

Copy the contents of build/web into one folder, copy this file there, and run:

    python3 serve_web.py
"""

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

_HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class Handler(SimpleHTTPRequestHandler):
    upstream = "http://127.0.0.1:4533"

    def do_GET(self):
        if _is_api(self.path):
            self._proxy()
            return
        super().do_GET()

    def do_HEAD(self):
        if _is_api(self.path):
            self._proxy()
            return
        super().do_HEAD()

    def do_POST(self):
        if _is_api(self.path):
            self._proxy()
            return
        self.send_error(404)

    def _proxy(self):
        length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(length) if length else None
        headers = {}
        for name in ("Content-Type", "Range", "Accept", "Accept-Language"):
            value = self.headers.get(name)
            if value:
                headers[name] = value
        request = Request(
            self.upstream + self.path,
            data=body,
            headers=headers,
            method=self.command,
        )
        try:
            response = urlopen(request)
        except HTTPError as error:
            response = error
        except URLError:
            self.send_error(502, "Navidrome is not reachable on port 4533")
            return
        try:
            self.send_response(response.status)
            for key, value in response.headers.items():
                if key.lower() in _HOP:
                    continue
                self.send_header(key, value)
            self.end_headers()
            if self.command == "HEAD":
                return
            while True:
                chunk = response.read(64 * 1024)
                if not chunk:
                    break
                self.wfile.write(chunk)
        finally:
            response.close()


def _is_api(path):
    return path.split("?", 1)[0].startswith("/rest/")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--directory", default=".")
    parser.add_argument("--navidrome", default="http://127.0.0.1:4533")
    args = parser.parse_args()
    Handler.upstream = args.navidrome.rstrip("/")

    def handler(*positional, **named):
        return Handler(*positional, directory=args.directory, **named)

    server = ThreadingHTTPServer(("0.0.0.0", args.port), handler)
    print(
        f"Subsonica http://0.0.0.0:{args.port}/  /rest -> {Handler.upstream}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
