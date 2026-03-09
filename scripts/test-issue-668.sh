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

def cmd(sock, payload):
    sock.sendall(payload.encode("ascii"))
    return read_line(sock)

sock = connect()
assert cmd(sock, "put 0 0 100 1\r\nA\r\n") == "INSERTED 1\r\n"
assert cmd(sock, "reserve\r\n") == "RESERVED 1 1\r\n"
assert read_body(sock, 1) == "A\r\n"
assert cmd(sock, "bury 1 0\r\n") == "BURIED\r\n"
assert cmd(sock, "put 0 0 100 1\r\nB\r\n") == "INSERTED 2\r\n"
assert cmd(sock, "reserve\r\n") == "RESERVED 2 1\r\n"
assert read_body(sock, 1) == "B\r\n"
assert cmd(sock, "bury 2 0\r\n") == "BURIED\r\n"
sock.close()
PY

restart_server

run_python "$TEST_HOST" "$TEST_PORT" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])

def connect():
    return socket.create_connection((host, port))

def read_line(sock):
    data = bytearray()
    while not data.endswith(b"\r\n"):
        chunk = sock.recv(1)
        if not chunk:
            raise RuntimeError("connection closed")
        data.extend(chunk)
    return data.decode("ascii")

def read_exact(sock, size):
    data = bytearray()
    while len(data) < size:
        chunk = sock.recv(size - len(data))
        if not chunk:
            raise RuntimeError("connection closed")
        data.extend(chunk)
    return data

def cmd(sock, payload):
    sock.sendall(payload.encode("ascii"))
    return read_line(sock)

sock = connect()
for job_id in ("1", "2"):
    header = cmd(sock, f"stats-job {job_id}\r\n")
    if not header.startswith("OK "):
        raise SystemExit(f"expected OK for stats-job {job_id}, got {header!r}")
    size = int(header.split()[1])
    body = read_exact(sock, size + 2).decode("ascii")
    if "\nburies: 1\n" not in body:
        raise SystemExit(f"expected buries: 1 for job {job_id}, got {body!r}")

header = cmd(sock, "peek-buried\r\n")
if header != "FOUND 1 1\r\n":
    raise SystemExit(f"expected first buried job to be 1, got {header!r}")
if read_exact(sock, 3).decode("ascii") != "A\r\n":
    raise SystemExit("expected buried job 1 body to be A")

if cmd(sock, "kick 1\r\n") != "KICKED 1\r\n":
    raise SystemExit("expected kick 1 to succeed")

header = cmd(sock, "peek-buried\r\n")
if header != "FOUND 2 1\r\n":
    raise SystemExit(f"expected second buried job to be 2, got {header!r}")
if read_exact(sock, 3).decode("ascii") != "B\r\n":
    raise SystemExit("expected buried job 2 body to be B")

print("issue #668 check passed")
sock.close()
PY
