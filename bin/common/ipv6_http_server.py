#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Serve current directory over HTTP on IPv6.

Usage:
  python3 ipv6_http_server.py
  python3 ipv6_http_server.py --port 8004 --bind ::

Example:
  curl -g 'http://[::1]:8004/'
"""

import argparse
import socket
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class IPv6HTTPServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6


def main() -> None:
    parser = argparse.ArgumentParser(description="Simple IPv6 HTTP server for current directory")
    parser.add_argument("--port", type=int, default=8004, help="Listen port (default: 8004)")
    parser.add_argument("--bind", type=str, default="::", help="Bind address (default: ::)")
    args = parser.parse_args()

    httpd = IPv6HTTPServer((args.bind, args.port), SimpleHTTPRequestHandler)
    print(f"Serving HTTP on [{args.bind}]:{args.port} (IPv6) from current directory", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()

