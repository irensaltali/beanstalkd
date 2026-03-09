#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BEANSTALKD_BIN=${BEANSTALKD_BIN:-"$ROOT_DIR/beanstalkd"}
TEST_PORT=${TEST_PORT:-11300}
TEST_HOST=${TEST_HOST:-127.0.0.1}
TEST_WAL_DIR=${TEST_WAL_DIR:-$(mktemp -d /tmp/beanstalkd-test.XXXXXX)}

cleanup() {
    if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

ensure_built() {
    if [ ! -x "$BEANSTALKD_BIN" ]; then
        echo "beanstalkd binary not found at $BEANSTALKD_BIN; run make first" >&2
        exit 1
    fi
}

reset_wal_dir() {
    rm -rf "$TEST_WAL_DIR"
    mkdir -p "$TEST_WAL_DIR"
}

start_server() {
    reset_wal_dir
    "$BEANSTALKD_BIN" -l "$TEST_HOST" -p "$TEST_PORT" -b "$TEST_WAL_DIR" "$@" &
    SERVER_PID=$!
    sleep 1
}

restart_server() {
    if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID"
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    "$BEANSTALKD_BIN" -l "$TEST_HOST" -p "$TEST_PORT" -b "$TEST_WAL_DIR" "$@" &
    SERVER_PID=$!
    sleep 1
}

run_python() {
    python3 - "$@"
}
