#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/_common.sh"

ensure_built
trap cleanup EXIT INT TERM
start_server

run_python "$TEST_HOST" "$TEST_PORT" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])

def connect():
    return socket.create_connection((host, port))

def send_cmd(sock, payload):
    sock.sendall(payload.encode("ascii"))
    return read_line(sock)

def read_line(sock):
    data = bytearray()
    while not data.endswith(b"\r\n"):
        chunk = sock.recv(1)
        if not chunk:
            raise RuntimeError("connection closed")
        data.extend(chunk)
    return data.decode("ascii")

def read_body(sock, size):
    data = bytearray()
    while len(data) < size + 2:
        chunk = sock.recv(size + 2 - len(data))
        if not chunk:
            raise RuntimeError("connection closed while reading body")
        data.extend(chunk)
    return data.decode("ascii")

sock = connect()
assert send_cmd(sock, "put 0 0 100 1\r\nA\r\n") == "INSERTED 1\r\n"
assert send_cmd(sock, "put 10 0 100 1\r\nB\r\n") == "INSERTED 2\r\n"
assert send_cmd(sock, "reserve\r\n") == "RESERVED 1 1\r\n"
assert read_body(sock, 1) == "A\r\n"
assert send_cmd(sock, "release 1 20 0\r\n") == "RELEASED\r\n"
sock.close()
PY

restart_server

run_python "$TEST_HOST" "$TEST_PORT" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])
sock = socket.create_connection((host, port))
sock.sendall(b"reserve\r\n")

line = bytearray()
while not line.endswith(b"\r\n"):
    line.extend(sock.recv(1))

if line.decode("ascii") != "RESERVED 2 1\r\n":
    raise SystemExit(f"expected job 2 after restart, got {line.decode('ascii')!r}")

body = sock.recv(3).decode("ascii")
if body != "B\r\n":
    raise SystemExit(f"expected body 'B\\\\r\\\\n', got {body!r}")

print("issue #597 check passed")
sock.close()
PY
