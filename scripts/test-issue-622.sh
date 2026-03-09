#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/_common.sh"

ensure_built
trap cleanup EXIT INT TERM
run_phase() {
    run_python "$TEST_HOST" "$TEST_PORT" "$1" <<'PY'
import socket
import sys

host, port, loops = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])

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
            raise RuntimeError("connection closed")
        data.extend(chunk)
    return data.decode("ascii")

def cmd(sock, payload):
    sock.sendall(payload.encode("ascii"))
    return read_line(sock)

sock = connect()
for _ in range(loops):
    assert cmd(sock, "reserve\r\n") == "RESERVED 1 1\r\n"
    assert read_body(sock, 1) == "A\r\n"
    assert cmd(sock, "release 1 0 1\r\n") == "RELEASED\r\n"
    assert cmd(sock, "kick-job 1\r\n") == "KICKED\r\n"

sock.close()
PY
}

measure_total() {
    run_python "$TEST_WAL_DIR" <<'PY'
import glob
import os
import sys

wal_dir = sys.argv[1]
total = sum(os.path.getsize(path) for path in glob.glob(os.path.join(wal_dir, "binlog.*")))
print(total)
PY
}

start_server -s 512

run_python "$TEST_HOST" "$TEST_PORT" <<'PY'
import socket
import sys

host, port = sys.argv[1], int(sys.argv[2])
sock = socket.create_connection((host, port))
sock.sendall(b"put 0 0 100 1\r\nA\r\n")

line = bytearray()
while not line.endswith(b"\r\n"):
    line.extend(sock.recv(1))

if line.decode("ascii") != "INSERTED 1\r\n":
    raise SystemExit(f"expected INSERTED 1, got {line.decode('ascii')!r}")

sock.close()
PY

run_phase 100

kill "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""
EARLY_TOTAL=$(measure_total)

restart_server -s 512
run_phase 300

kill "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""
LATE_TOTAL=$(measure_total)

run_python "$EARLY_TOTAL" "$LATE_TOTAL" <<'PY'
import sys

early = int(sys.argv[1])
late = int(sys.argv[2])
limit = early + 1024

if late > limit:
    raise SystemExit(f"expected WAL to stay bounded after warm-up: early={early}, late={late}, limit={limit}")

print(f"issue #622 check passed (early={early}, late={late})")
PY
