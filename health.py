import os
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "10000"))

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"OK\n")

    def log_message(self, format, *args):
        pass

server = HTTPServer(("0.0.0.0", PORT), HealthHandler)
print(f"Health server listening on 0.0.0.0:{PORT}", flush=True)
server.serve_forever()
