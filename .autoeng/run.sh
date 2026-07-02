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

now_epoch() { date +%s; }

lock_acquire() {
  LOCK="$AE_DIR/LOCK"
  if [ -f "$LOCK" ]; then
    lock_epoch="$(grep '^epoch:' "$LOCK" 2>/dev/null | awk '{print $2}')"
    [ -n "${lock_epoch:-}" ] || lock_epoch=0
    age_min=$(( ( $(now_epoch) - lock_epoch ) / 60 ))
    if [ "$age_min" -lt "$LOCK_STALE_MIN" ]; then
      log "LOCK present (age ${age_min}m) — another run is active, exiting"
      return 1
    fi
    log "stale lock (age ${age_min}m >= ${LOCK_STALE_MIN}m) — recovering"
    rm -f "$LOCK"
  fi
  printf 'LOCKED\nepoch: %s\ntimestamp: %s\n' "$(now_epoch)" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOCK"
  return 0
}

lock_release() { rm -f "$AE_DIR/LOCK"; }

cmd_run() {
  cd "$PROJECT_ROOT"
  load_config
  if [ "$CONTROL" != "enabled" ]; then
    log "control is '$CONTROL' — not enabled, skipping run"
    return 0
  fi
  lock_acquire || return 0
  log "control enabled — starting cycle (executor not yet wired)"
  # NOTE: temporary marker so lock tests can observe execution; removed in Task 6.
  [ "${FE_MARKER:-0}" = 1 ] && : > "$AE_DIR/EXECUTOR_RAN"
  lock_release
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
