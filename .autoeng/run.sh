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

checkpoint_create() {
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "[autoeng checkpoint] $(date -u +%Y-%m-%dT%H:%M:%SZ)" || true
    log "checkpoint: committed pending changes"
  fi
  git rev-parse HEAD > "$AE_DIR/CHECKPOINT"
  log "checkpoint: $(git rev-parse --short HEAD)"
}

checkpoint_rollback() {
  cp="$(cat "$AE_DIR/CHECKPOINT" 2>/dev/null || true)"
  [ -n "$cp" ] || { log "rollback: no checkpoint recorded"; return 1; }
  git reset --hard "$cp" >/dev/null 2>&1 || { log "rollback: git reset failed"; return 1; }
  git clean -fd >/dev/null 2>&1 || true
  log "rollback: reset to $cp (untracked cleaned)"
}

set_control() { # new_state
  sed "s/^CONTROL=.*/CONTROL=\"$1\"/" "$AE_DIR/config.sh" > "$AE_DIR/config.sh.tmp"
  mv "$AE_DIR/config.sh.tmp" "$AE_DIR/config.sh"
  log "control set to '$1'"
}

run_gates() { # returns 0 if all configured gates pass
  for pair in "build:$GATE_BUILD" "lint:$GATE_LINT" "test:$GATE_TEST"; do
    name="${pair%%:*}"; cmd="${pair#*:}"
    [ -n "$cmd" ] || { log "gate $name: skipped (unconfigured)"; continue; }
    if sh -c "$cmd" >/dev/null 2>&1; then
      log "gate $name: pass"
    else
      log "gate $name: FAIL — command: $cmd"
      return 1
    fi
  done
  return 0
}

invoke_executor() {
  [ -n "$EXECUTOR" ] || { log "ERROR: EXECUTOR is empty — set it in config.sh"; return 1; }
  log "invoking executor: $EXECUTOR"
  sh -c "$EXECUTOR"
}

cmd_run() {
  cd "$PROJECT_ROOT"
  load_config
  if [ "$CONTROL" != "enabled" ]; then
    log "control is '$CONTROL' — not enabled, skipping run"
    return 0
  fi
  lock_acquire || return 0
  checkpoint_create

  if ! invoke_executor; then
    log "executor error — rolling back"
    checkpoint_rollback || log "rollback FAILED — manual recovery may be needed"
    set_control "failed"; lock_release; return 1
  fi

  if run_gates; then
    if [ -n "$(git status --porcelain)" ]; then
      git add -A && git commit -q -m "[autoeng] cycle result $(date -u +%Y-%m-%dT%H:%M:%SZ)" || true
      log "landed cycle result"
    fi
    log "gate passed — cycle complete"
    lock_release; return 0
  else
    log "gate failed — rolling back to checkpoint"
    checkpoint_rollback || log "rollback FAILED — manual recovery may be needed"
    set_control "failed"; lock_release; return 1
  fi
}

cmd_loop() {
  while : ; do
    cd "$PROJECT_ROOT"; load_config
    if [ "$CONTROL" != "enabled" ]; then
      log "loop: control is '$CONTROL' — stopping"
      break
    fi
    cmd_run || { log "loop: cycle failed — stopping"; break; }
  done
}

set_gate() { # VAR value
  sed "s|^$1=.*|$1=\"$2\"|" "$AE_DIR/config.sh" > "$AE_DIR/config.sh.tmp"
  mv "$AE_DIR/config.sh.tmp" "$AE_DIR/config.sh"
}

cmd_adopt() {
  cd "$PROJECT_ROOT"
  if [ -f package.json ]; then
    set_gate GATE_BUILD "npm run build"; set_gate GATE_LINT "npm run lint"; set_gate GATE_TEST "npm test"
    detected="Node/npm"
  elif [ -f Cargo.toml ]; then
    set_gate GATE_BUILD "cargo build"; set_gate GATE_LINT "cargo clippy"; set_gate GATE_TEST "cargo test"
    detected="Rust/cargo"
  elif [ -f go.mod ]; then
    set_gate GATE_BUILD "go build ./..."; set_gate GATE_LINT "go vet ./..."; set_gate GATE_TEST "go test ./..."
    detected="Go"
  elif [ -f pyproject.toml ]; then
    set_gate GATE_BUILD ""; set_gate GATE_LINT "ruff check ."; set_gate GATE_TEST "pytest"
    detected="Python"
  else
    detected="unknown (gates left blank — set them in config.sh)"
  fi
  log "adopt: detected stack: $detected"

  cat > "$AE_DIR/STATE.md" <<EOF
# Project State

## Status
Adopted $(date -u +%Y-%m-%d). Stack: $detected. Gates written to config.sh.

## Next task
Scan the repository, read any existing docs/ and TODO, and choose the highest-value
next task per AGENT.md. Record it here before implementing.

## Task queue
- [ ] (to be populated by the first planning cycle)

## Blockers
(none)
EOF
  log "adopt: seeded STATE.md — set EXECUTOR and CONTROL=enabled in config.sh, then run: sh .autoeng/run.sh loop"
}

cmd_status() {
  cd "$PROJECT_ROOT"; load_config
  echo "control: $CONTROL"
  echo "executor: ${EXECUTOR:-(unset)}"
  if [ -f "$AE_DIR/LOCK" ]; then echo "lock: present"; else echo "lock: none"; fi
  echo "last worklog:"; tail -n 3 "$AE_DIR/WORKLOG.md" 2>/dev/null || echo "  (none)"
}
cmd_pause() { cd "$PROJECT_ROOT"; load_config; set_control "paused"; }
cmd_stop()  { cd "$PROJECT_ROOT"; load_config; set_control "stop_requested"; }

main() {
  cmd="${1:-run}"; [ $# -gt 0 ] && shift || true
  case "$cmd" in
    run)  cmd_run "$@" ;;
    loop) cmd_loop "$@" ;;
    status) cmd_status "$@" ;;
    pause)  cmd_pause  "$@" ;;
    stop)   cmd_stop   "$@" ;;
    adopt) cmd_adopt "$@" ;;
    *)    echo "usage: run.sh run|loop|adopt|status|pause|stop" >&2; exit 2 ;;
  esac
}
main "$@"
