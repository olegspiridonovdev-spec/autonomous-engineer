#!/bin/sh
# .autoeng/run.sh — the only script. Owns lock, checkpoint, gate verification, loop.
# Subcommands: run | loop | adopt | status | pause | stop
set -eu

AE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$AE_DIR/.." && pwd)"
LOG="$AE_DIR/execution.log"

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG" >&2; }

load_config() {
  [ -f "$AE_DIR/config.sh" ] || { log "ERROR: missing config.sh"; exit 1; }
  # shellcheck disable=SC1091
  . "$AE_DIR/config.sh"
  : "${EXECUTOR:=}"; : "${GATE_BUILD:=}"; : "${GATE_LINT:=}"; : "${GATE_TEST:=}"
  : "${CONTROL:=paused}"; : "${LOCK_STALE_MIN:=30}"; : "${CYCLE_TIMEOUT_MIN:=15}"
}

cmd_run() {
  cd "$PROJECT_ROOT"
  load_config
  if [ "$CONTROL" != "enabled" ]; then
    log "control is '$CONTROL' — not enabled, skipping run"
    return 0
  fi
  log "control enabled — starting cycle (executor not yet wired)"
  return 0
}

main() {
  cmd="${1:-run}"; [ $# -gt 0 ] && shift || true
  case "$cmd" in
    run)  cmd_run "$@" ;;
    *)    echo "usage: run.sh run|loop|adopt|status|pause|stop" >&2; exit 2 ;;
  esac
}
main "$@"
