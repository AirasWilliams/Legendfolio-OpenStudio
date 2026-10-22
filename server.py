from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os, webbrowser
os.chdir(Path(__file__).resolve().parent)
class Handler(SimpleHTTPRequestHandler):
    extensions_map={**SimpleHTTPRequestHandler.extensions_map,'.webmanifest':'application/manifest+json','.js':'text/javascript'}
    def end_headers(self):
        self.send_header('Cache-Control','no-cache')
        super().end_headers()
try:
    server=ThreadingHTTPServer(('127.0.0.1',8766),Handler)
except OSError:
    webbrowser.open('http://127.0.0.1:8766/index.html')
else:
    webbrowser.open('http://127.0.0.1:8766/index.html')
    server.serve_forever()
