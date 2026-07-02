# Autonomous Engineer — Portable Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 32-file OpenClaw-bound `agent/` framework with a lightweight, dependency-free `.autoeng/` folder (3 markdown + 1 sh config + 1 sh script) that drops into any repo and drives any coding agent through safe autonomous development cycles.

**Architecture:** Two layers. The **spec** (`AGENT.md`, `STATE.md`, `WORKLOG.md`) is markdown any agent reads. The **executor** is a single command string in `config.sh`. `run.sh` owns the trust boundary — it acquires a lock, creates a git checkpoint, checks the control flag, invokes the executor, then **re-runs the quality gates itself** and rolls back on failure. Greenfield vs. existing projects differ only by the seed content in `STATE.md`, not by code.

**Tech Stack:** POSIX `sh` (`#!/bin/sh`, portable `local` as supported by dash/ash/bash), Git, and plain-shell tests (no bats, no runtime dependencies). `shellcheck` is used in the final task as a dev-only linter.

---

## Design reference

Spec: [docs/superpowers/specs/2026-07-02-autonomous-engineer-portable-redesign-design.md](../specs/2026-07-02-autonomous-engineer-portable-redesign-design.md)

## Target file structure

```
autonomous-engineer/                 # this source repo (the template lives at root, ready to copy)
├── .autoeng/                        # THE folder users copy into their project
│   ├── AGENT.md                     # immutable rules + workflow + quality bar (agent reads each cycle)
│   ├── STATE.md                     # working memory: status, next task, queue, blockers
│   ├── WORKLOG.md                   # append-only journal (decisions tagged [decision])
│   ├── config.sh                    # sourced: EXECUTOR, GATE_*, CONTROL, timeouts
│   ├── .gitignore                   # ignores this folder's own runtime artifacts (LOCK/CHECKPOINT/log)
│   └── run.sh                       # the only script: run|loop|adopt|status|pause|stop
├── install.sh                       # minimal: copy .autoeng/ into a target project
├── tests/
│   ├── run_tests.sh                 # runs every test_*.sh, prints summary, non-zero on failure
│   ├── helpers.sh                   # assert_* helpers + setup_repo fixture
│   ├── fake-executor.sh             # stand-in $EXECUTOR for tests (behavior via env)
│   ├── test_control_flag.sh
│   ├── test_lock.sh
│   ├── test_checkpoint.sh
│   ├── test_gate_rollback.sh
│   ├── test_run_happy.sh
│   ├── test_loop.sh
│   ├── test_status.sh
│   └── test_adopt.sh
├── README.md                        # rewritten: 3-command quickstart
├── MIGRATION.md                     # for existing agent/ users
├── LICENSE
└── .gitignore
```

**Convention used by every test:** gates are shell commands, so tests make them controllable without a real toolchain. `GATE_BUILD="test -f BUILD_OK"` passes only when a `BUILD_OK` file exists in the repo. The fake executor creates/removes `BUILD_OK` to simulate a passing/failing build. This keeps the whole suite dependency-free.

---

## Task 1: Test harness scaffolding

**Files:**
- Create: `tests/helpers.sh`
- Create: `tests/fake-executor.sh`
- Create: `tests/run_tests.sh`

- [ ] **Step 1: Write the assertion + fixture helpers**

Create `tests/helpers.sh`:

```sh
# tests/helpers.sh — sourced by every test_*.sh
# Provides: assert_eq, assert_file_exists, assert_file_absent, assert_contains,
# assert_status, setup_repo, teardown_repo. Tracks pass/fail via $TESTS_FAILED.

: "${TESTS_FAILED:=0}"
# The runner exports REPO_ROOT (computed before it cd's). Honor it; only fall back
# to $0-based resolution when a test is run standalone from inside tests/.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

_fail() { printf '  FAIL: %s\n' "$1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
_ok()   { printf '  ok:   %s\n' "$1"; }

assert_eq() { # expected actual message
  if [ "$1" = "$2" ]; then _ok "$3"; else _fail "$3 (expected '$1', got '$2')"; fi
}
assert_file_exists() { # path message
  if [ -f "$1" ]; then _ok "$2"; else _fail "$2 (missing file '$1')"; fi
}
assert_file_absent() { # path message
  if [ ! -f "$1" ]; then _ok "$2"; else _fail "$2 (unexpected file '$1')"; fi
}
assert_contains() { # file substring message
  if grep -qF "$2" "$1" 2>/dev/null; then _ok "$3"; else _fail "$3 ('$2' not in '$1')"; fi
}

# Create an isolated git repo with .autoeng/ copied in and a test-friendly config.
# Sets $SANDBOX to the repo path and cd's into it.
setup_repo() {
  [ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"   # clean prior sandbox on repeated calls
  SANDBOX="$(mktemp -d)"
  cp -r "$REPO_ROOT/.autoeng" "$SANDBOX/.autoeng"
  cd "$SANDBOX" || exit 1
  git init -q
  git config user.email test@test.local
  git config user.name test
  echo "seed" > seed.txt
  git add -A && git commit -qm "seed"
  # Overwrite config for tests: executor = fake, gate = BUILD_OK sentinel.
  # Single-quote the path so a space in REPO_ROOT survives later `sh -c "$EXECUTOR"`.
  cat > .autoeng/config.sh <<EOF
EXECUTOR="sh '$REPO_ROOT/tests/fake-executor.sh'"
GATE_BUILD="test -f BUILD_OK"
GATE_LINT=""
GATE_TEST=""
CONTROL="enabled"
LOCK_STALE_MIN=30
CYCLE_TIMEOUT_MIN=15
EOF
  # Start with a passing build.
  touch BUILD_OK
  git add -A && git commit -qm "config"
}

teardown_repo() { cd "$REPO_ROOT" || exit 1; [ -n "$SANDBOX" ] && rm -rf "$SANDBOX"; }
```

- [ ] **Step 2: Write the fake executor**

Create `tests/fake-executor.sh`. Behavior is driven by env vars a test exports before calling `run.sh`:

```sh
# tests/fake-executor.sh — stand-in for a real coding agent.
# Runs inside the sandbox repo (cwd) exactly like a real $EXECUTOR would.
# Env knobs (all optional):
#   FE_MARKER=1     -> write .autoeng/EXECUTOR_RAN so tests can prove it was invoked
#   FE_EDIT=1       -> make a change and commit it (simulates real work)
#   FE_BREAK=1      -> remove BUILD_OK so the gate re-run fails
#   FE_COMPLETE_AT=N-> on the Nth invocation, set CONTROL=project_completed (for loop tests)

COUNT_FILE=".autoeng/FE_COUNT"
n=0; [ -f "$COUNT_FILE" ] && n=$(cat "$COUNT_FILE"); n=$((n + 1)); echo "$n" > "$COUNT_FILE"

[ "${FE_MARKER:-0}" = 1 ] && : > .autoeng/EXECUTOR_RAN
[ "${FE_BREAK:-0}" = 1 ] && rm -f BUILD_OK

if [ "${FE_EDIT:-0}" = 1 ]; then
  echo "work $n" >> work.txt
  git add -A && git commit -qm "[agent] work $n"
fi

if [ -n "${FE_COMPLETE_AT:-}" ] && [ "$n" -ge "$FE_COMPLETE_AT" ]; then
  sed -i.bak 's/^CONTROL=.*/CONTROL="project_completed"/' .autoeng/config.sh && rm -f .autoeng/config.sh.bak
fi
exit 0
```

- [ ] **Step 3: Write the test runner**

Create `tests/run_tests.sh`:

```sh
#!/bin/sh
# Runs every tests/test_*.sh, aggregates pass/fail, exits non-zero on any failure.
# Compute REPO_ROOT BEFORE cd (while $0 still resolves against the original cwd),
# then export it so sourced tests/helpers.sh don't have to rely on $0.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"; export REPO_ROOT
cd "$REPO_ROOT/tests" || exit 1
total_failed=0
for t in test_*.sh; do
  [ -f "$t" ] || continue
  printf '\n=== %s ===\n' "$t"
  TESTS_FAILED=0
  # shellcheck disable=SC1090
  ( . ./"$t" ); rc=$?
  total_failed=$((total_failed + rc))
done
printf '\n=========================\n'
if [ "$total_failed" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "FAILURES: $total_failed"; fi
[ "$total_failed" -eq 0 ]
```

Each `test_*.sh` will end with `exit "$TESTS_FAILED"` so the runner captures its failure count via `rc`.

- [ ] **Step 4: Make scripts executable and verify the runner works with zero tests**

Run:
```bash
chmod +x tests/run_tests.sh tests/fake-executor.sh
sh tests/run_tests.sh
```
Expected: prints `ALL TESTS PASSED` (no `test_*.sh` yet), exit 0.

- [ ] **Step 5: Commit**

```bash
git add tests/
git commit -m "test: add plain-shell test harness (helpers, fake executor, runner)"
```

---

## Task 2: `config.sh` template and gitignore

**Files:**
- Create: `.autoeng/config.sh`
- Create: `.autoeng/.gitignore`
- Modify: `.gitignore`

- [ ] **Step 1: Write the config template**

Create `.autoeng/config.sh`:

```sh
# .autoeng/config.sh — the only file you must edit. Sourced by run.sh.

# --- Executor: the command that runs ONE cycle -------------------------------
# It is invoked from the project root, reads .autoeng/AGENT.md, performs exactly
# one engineering objective, then exits. Any coding agent works — this string is
# the only adapter. Examples:
#   aider     EXECUTOR="aider --model deepseek/deepseek-chat --yes --message-file .autoeng/AGENT.md"
#   claude    EXECUTOR="claude -p 'Follow .autoeng/AGENT.md and execute one autonomous cycle.'"
#   openclaw  EXECUTOR="openclaw run --message 'Follow .autoeng/AGENT.md, one cycle.'"
EXECUTOR=""

# --- Quality gates: blank = skipped (and logged). Auto-filled by `run.sh adopt`.
GATE_BUILD=""
GATE_LINT=""
GATE_TEST=""

# --- Control: enabled | paused | stop_requested | project_completed | failed
CONTROL="paused"

# --- Tuning ------------------------------------------------------------------
LOCK_STALE_MIN=30      # a LOCK older than this (minutes) is treated as crashed and recovered
CYCLE_TIMEOUT_MIN=15   # advisory per-cycle wall-clock budget (documented in AGENT.md)
```

Note: default `CONTROL="paused"` so a freshly-copied framework never runs until the user opts in.

- [ ] **Step 2: Create `.autoeng/.gitignore` (portable artifact ignoring)**

This is load-bearing, not cosmetic: `run.sh` writes `LOCK`, `CHECKPOINT`, and `execution.log` inside `.autoeng/`. Without ignoring them, `checkpoint_create` (Task 5) would see an untracked-file "dirty" tree and commit them — breaking the clean-tree checkpoint assertion and polluting every host repo. Shipping the ignore *inside* the framework folder makes it work in any project regardless of the host's root `.gitignore`.

Create `.autoeng/.gitignore`:

```
# Runtime artifacts created by run.sh — never commit these.
LOCK
CHECKPOINT
execution.log
# Test-only artifacts (present only in test sandboxes).
FE_COUNT
EXECUTOR_RAN
```

- [ ] **Step 3: Update the root `.gitignore`**

Remove the two now-obsolete `agent/` lines. Edit `.gitignore` — change:
```
# Auto-generated runtime files
agent/CHECKPOINT
agent/LOCK
```
to:
```
# Framework runtime artifacts are ignored by .autoeng/.gitignore.
```
(Leave the existing OS/editor entries below it untouched.)

- [ ] **Step 4: Commit**

```bash
git add .autoeng/config.sh .autoeng/.gitignore .gitignore
git commit -m "feat: add config.sh template and ignore framework runtime artifacts"
```

---

## Task 3: `run.sh` skeleton + control-flag gate

**Files:**
- Create: `.autoeng/run.sh`
- Create: `tests/test_control_flag.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_control_flag.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

# CONTROL=paused must skip the executor entirely.
sed -i.bak 's/^CONTROL=.*/CONTROL="paused"/' .autoeng/config.sh && rm -f .autoeng/config.sh.bak
FE_MARKER=1 sh .autoeng/run.sh run > out.log 2>&1
assert_status_paused=$?
assert_eq "0" "$assert_status_paused" "run exits 0 when paused"
assert_file_absent ".autoeng/EXECUTOR_RAN" "executor not invoked when paused"
assert_contains "out.log" "not enabled" "logs why it skipped"

teardown_repo
exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — `.autoeng/run.sh` does not exist yet.

- [ ] **Step 3: Write the run.sh skeleton with control handling**

Create `.autoeng/run.sh`:

```sh
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
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `chmod +x .autoeng/run.sh && sh tests/run_tests.sh`
Expected: `test_control_flag.sh` passes (run exits 0 when paused, executor not invoked, log explains skip).

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_control_flag.sh
git commit -m "feat: run.sh skeleton with control-flag gate"
```

---

## Task 4: LOCK with stale-lock recovery

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_lock.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_lock.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh

# Case A: a fresh LOCK blocks the run. Must write a fresh `epoch:` field —
# lock_acquire keys staleness off epoch, so a timestamp-only lock parses as
# epoch 0 and would be wrongly treated as stale.
setup_repo
printf 'LOCKED\nepoch: %s\n' "$(date +%s)" > .autoeng/LOCK
FE_MARKER=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_absent ".autoeng/EXECUTOR_RAN" "fresh lock blocks executor"
assert_contains "out.log" "another run" "logs that a run is active"
teardown_repo

# Case B: a stale LOCK (old epoch) is recovered and the run proceeds.
setup_repo
printf 'LOCKED\nepoch: 100\n' > .autoeng/LOCK   # epoch 100 = 1970, always stale
FE_MARKER=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_exists ".autoeng/EXECUTOR_RAN" "stale lock recovered, executor ran"
assert_contains "out.log" "stale lock" "logs stale-lock recovery"
teardown_repo

exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — no lock logic yet; executor never runs so Case B's `EXECUTOR_RAN` is missing.

- [ ] **Step 3: Add lock functions and wire them into cmd_run**

In `.autoeng/run.sh`, add these functions after `load_config`:

```sh
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
```

Then update `cmd_run` — replace the `log "control enabled ..."` line with:

```sh
  lock_acquire || return 0
  log "control enabled — starting cycle (executor not yet wired)"
  # NOTE: temporary marker so lock tests can observe execution; removed in Task 6.
  [ "${FE_MARKER:-0}" = 1 ] && : > "$AE_DIR/EXECUTOR_RAN"
  lock_release
  return 0
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_lock.sh` passes both cases; `test_control_flag.sh` still passes.

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_lock.sh
git commit -m "feat: LOCK acquisition with stale-lock recovery"
```

---

## Task 5: Git checkpoint before the cycle

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_checkpoint.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_checkpoint.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

head_before="$(git rev-parse HEAD)"
sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_exists ".autoeng/CHECKPOINT" "checkpoint file written"
recorded="$(cat .autoeng/CHECKPOINT)"
assert_eq "$head_before" "$recorded" "checkpoint records HEAD when tree is clean"

# Dirty tree: checkpoint commits pending work so rollback can restore it.
setup_repo
echo "dirty" >> seed.txt
sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_exists ".autoeng/CHECKPOINT" "checkpoint file written (dirty)"
test -z "$(git status --porcelain)" && _ok "tree clean after checkpoint commit" \
  || _fail "tree still dirty after checkpoint"
teardown_repo

exit "$TESTS_FAILED"
```

(`setup_repo` removes any prior sandbox as its first line, so the second call cleans up the first; the final `teardown_repo` removes the second.)

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — no `.autoeng/CHECKPOINT` produced.

- [ ] **Step 3: Add the checkpoint function and wire it in**

In `.autoeng/run.sh`, add after `lock_release`:

```sh
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
  git reset --hard "$cp" >/dev/null 2>&1
  log "rollback: reset to $cp"
}
```

Wire into `cmd_run` — insert `checkpoint_create` immediately after `lock_acquire || return 0`:

```sh
  lock_acquire || return 0
  checkpoint_create
  log "control enabled — starting cycle (executor not yet wired)"
  [ "${FE_MARKER:-0}" = 1 ] && : > "$AE_DIR/EXECUTOR_RAN"
  lock_release
  return 0
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_checkpoint.sh` passes; earlier tests still pass.

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_checkpoint.sh
git commit -m "feat: pre-cycle git checkpoint with rollback helper"
```

---

## Task 6: Gate verification and rollback-on-failure

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_gate_rollback.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_gate_rollback.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

# Executor makes a change, commits it, then breaks the build (removes BUILD_OK).
checkpoint_head="$(git rev-parse HEAD)"
FE_EDIT=1 FE_BREAK=1 sh .autoeng/run.sh run > out.log 2>&1 || true

assert_contains "out.log" "gate failed" "logs the gate failure"
assert_file_absent "work.txt" "executor's change was rolled back"
assert_eq "$checkpoint_head" "$(git rev-parse HEAD)" "HEAD reset to checkpoint"
assert_contains ".autoeng/config.sh" 'CONTROL="failed"' "control set to failed"
assert_file_absent ".autoeng/LOCK" "lock released after failure"

teardown_repo
exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — gates are not run yet; nothing rolls back.

- [ ] **Step 3: Add gate-running, control-setter, and executor invocation**

In `.autoeng/run.sh`, add after `checkpoint_rollback`:

```sh
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
```

Now replace the body of `cmd_run` (everything after `checkpoint_create`) with the real cycle:

```sh
  checkpoint_create

  if ! invoke_executor; then
    log "executor error — rolling back"
    checkpoint_rollback; set_control "failed"; lock_release; return 1
  fi

  if run_gates; then
    log "gate passed — cycle complete"
    lock_release; return 0
  else
    log "gate failed — rolling back to checkpoint"
    checkpoint_rollback; set_control "failed"; lock_release; return 1
  fi
```

Remove the temporary `EXECUTOR_RAN` marker line and the "not yet wired" log. (Lock/checkpoint tests still pass because they no longer depend on the marker — verify in Step 4.)

Because the marker is gone, update `tests/test_lock.sh` Case B to assert on the log instead of the marker: change `assert_file_exists ".autoeng/EXECUTOR_RAN" "stale lock recovered, executor ran"` to:
```sh
assert_contains "out.log" "invoking executor" "stale lock recovered, executor ran"
```
and in Case A change `assert_file_absent ".autoeng/EXECUTOR_RAN" ...` to:
```sh
assert_contains "out.log" "another run" "fresh lock blocks executor"
```
(Case A already asserts that; keep a single assertion.) Set both fake-executor calls in `test_lock.sh` to use `FE_MARKER=1` still — harmless.

- [ ] **Step 4: Run the tests to confirm they pass**

Run: `sh tests/run_tests.sh`
Expected: `test_gate_rollback.sh` passes; `test_lock.sh`, `test_checkpoint.sh`, `test_control_flag.sh` still pass.

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_gate_rollback.sh tests/test_lock.sh
git commit -m "feat: gate verification with rollback-and-fail on gate failure"
```

---

## Task 7: Happy-path `run` (executor succeeds, gates pass)

**Files:**
- Create: `tests/test_run_happy.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_run_happy.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

commits_before="$(git rev-list --count HEAD)"
FE_EDIT=1 sh .autoeng/run.sh run > out.log 2>&1
rc=$?
assert_eq "0" "$rc" "run exits 0 on success"
assert_file_exists "work.txt" "executor's committed change is preserved"
assert_contains "out.log" "gate build: pass" "build gate passed"
assert_contains "out.log" "cycle complete" "cycle reported complete"
assert_contains ".autoeng/config.sh" 'CONTROL="enabled"' "control stays enabled on success"
assert_file_absent ".autoeng/LOCK" "lock released after success"
[ "$(git rev-list --count HEAD)" -gt "$commits_before" ] && _ok "new commit landed" \
  || _fail "no new commit"

teardown_repo
exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it**

Run: `sh tests/run_tests.sh`
Expected: PASS — the cycle wiring from Task 6 already supports this; this test locks in the happy path.

If it fails, fix `cmd_run` until it passes (do not modify the test to force a pass).

- [ ] **Step 3: Commit**

```bash
git add tests/test_run_happy.sh
git commit -m "test: lock in happy-path run (change preserved, gates pass, lock released)"
```

---

## Task 8: `loop` subcommand

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_loop.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_loop.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

# Executor sets CONTROL=project_completed on its 2nd invocation → loop stops after 2.
FE_EDIT=1 FE_COMPLETE_AT=2 sh .autoeng/run.sh loop > out.log 2>&1 || true
assert_eq "2" "$(cat .autoeng/FE_COUNT)" "loop ran exactly 2 cycles then stopped"
assert_contains "out.log" "loop: control is 'project_completed'" "loop exits on completion"

teardown_repo
exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — `loop` is not a recognized subcommand (usage error, exit 2).

- [ ] **Step 3: Add cmd_loop and register it**

In `.autoeng/run.sh`, add:

```sh
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
```

Add `loop) cmd_loop "$@" ;;` to the `case` in `main`, before the `*)` default.

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_loop.sh` passes (exactly 2 cycles, stops on `project_completed`).

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_loop.sh
git commit -m "feat: loop subcommand — repeats cycles until control leaves enabled"
```

---

## Task 9: `status`, `pause`, `stop` subcommands

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_status.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_status.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

sh .autoeng/run.sh status > out.log 2>&1
assert_contains "out.log" "control: enabled" "status prints control state"

sh .autoeng/run.sh pause > /dev/null 2>&1
assert_contains ".autoeng/config.sh" 'CONTROL="paused"' "pause sets control=paused"

sh .autoeng/run.sh stop > /dev/null 2>&1
assert_contains ".autoeng/config.sh" 'CONTROL="stop_requested"' "stop sets control=stop_requested"

teardown_repo
exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — `status`/`pause`/`stop` are unrecognized subcommands.

- [ ] **Step 3: Add the three subcommands**

In `.autoeng/run.sh`, add:

```sh
cmd_status() {
  cd "$PROJECT_ROOT"; load_config
  echo "control: $CONTROL"
  echo "executor: ${EXECUTOR:-(unset)}"
  if [ -f "$AE_DIR/LOCK" ]; then echo "lock: present"; else echo "lock: none"; fi
  echo "last worklog:"; tail -n 3 "$AE_DIR/WORKLOG.md" 2>/dev/null || echo "  (none)"
}
cmd_pause() { cd "$PROJECT_ROOT"; load_config; set_control "paused"; }
cmd_stop()  { cd "$PROJECT_ROOT"; load_config; set_control "stop_requested"; }
```

Register in `main`'s `case`:
```sh
    status) cmd_status "$@" ;;
    pause)  cmd_pause  "$@" ;;
    stop)   cmd_stop   "$@" ;;
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_status.sh` passes.

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_status.sh
git commit -m "feat: status, pause, stop subcommands"
```

---

## Task 10: `adopt` — stack detection + STATE seed

**Files:**
- Modify: `.autoeng/run.sh`
- Create: `tests/test_adopt.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_adopt.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh

# Node project → npm gates.
setup_repo
echo '{"name":"x","scripts":{"build":"echo b","lint":"echo l","test":"echo t"}}' > package.json
git add -A && git commit -qm "add package.json"
sh .autoeng/run.sh adopt > out.log 2>&1
assert_contains ".autoeng/config.sh" 'GATE_BUILD="npm run build"' "npm build gate detected"
assert_contains ".autoeng/config.sh" 'GATE_TEST="npm test"' "npm test gate detected"
assert_contains ".autoeng/STATE.md" "Adopted" "STATE.md seeded on adopt"
teardown_repo

# Go project → go gates.
setup_repo
echo "module x" > go.mod
git add -A && git commit -qm "add go.mod"
sh .autoeng/run.sh adopt > out.log 2>&1
assert_contains ".autoeng/config.sh" 'GATE_BUILD="go build ./..."' "go build gate detected"
teardown_repo

exit "$TESTS_FAILED"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — `adopt` unrecognized.

- [ ] **Step 3: Add cmd_adopt**

In `.autoeng/run.sh`, add:

```sh
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
```

Register in `main`'s `case`: `adopt) cmd_adopt "$@" ;;`.

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_adopt.sh` passes both stacks.

- [ ] **Step 5: Commit**

```bash
git add .autoeng/run.sh tests/test_adopt.sh
git commit -m "feat: adopt subcommand — stack detection and STATE.md seed"
```

---

## Task 11: Author `AGENT.md` (content migration)

**Files:**
- Create: `.autoeng/AGENT.md`
- Read (source, to merge then delete later): `agent/SYSTEM.md`, `agent/AUTONOMOUS_ENGINEER.md`, `agent/PLANNING_ENGINE.md`, `agent/DIFF_PLANNING.md`, `agent/EXECUTION_CYCLE.md`, `agent/EXECUTION_RULES.md`, `agent/TASK_SIZE_POLICY.md`, `agent/QUALITY_GATE.md`, `agent/SELF_REVIEW.md`, `agent/REVIEW_CHECKLIST.md`, `agent/FAILURE_RECOVERY.md`, `agent/GIT_SAFETY.md`, `agent/AUTONOMOUS_CONTROL.md`, `agent/TERMINATION_POLICY.md`, `agent/SUCCESS_CRITERIA.md`, `agent/EXECUTION_TIMEOUT.md`, `agent/FINAL_SHUTDOWN.md`

This task is content authoring, not code — no test. Write `.autoeng/AGENT.md` with the exact section list below. For each section, port the concrete rules from the named source files (they are in the repo; read them and condense — preserve every rule, drop repetition and cross-references to now-deleted files). Keep it tight: the whole doc should read as one authored manual, not concatenated files.

- [ ] **Step 1: Write AGENT.md with these sections**

Required structure (use these headings verbatim):

```markdown
# Autonomous Engineer — Operating Manual

> The agent reads this file every cycle. Section 1 is immutable — never edit it.

## 1. Immutable Core Rules   [source: SYSTEM.md]
- Safety and correctness over speed; never break working state; never bypass or
  weaken tests; never violate docs/ARCHITECTURE.md; never edit Section 1 of this
  file; never ignore failures; preserve traceability; stability over new scope.
- The run harness (run.sh) enforces the checkpoint, lock, control flag, and gate
  re-run. You cannot opt out of them.

## 2. Mission   [project-specific — fill on init/adopt]
One paragraph: what this project is and what "done" looks like.

## 3. Each Cycle: What to Read   [source: AUTONOMOUS_ENGINEER.md startup]
config.sh (control + gates + executor), STATE.md (status/next/queue/blockers),
this file, then project docs (docs/ARCHITECTURE.md, docs/PLAN.md, TODO if present).

## 4. Planning — pick exactly ONE task   [source: PLANNING_ENGINE.md, DIFF_PLANNING.md]
Diff-aware: inspect `git diff`/status first; prefer stabilizing recently-changed
or broken modules over new features. Choose from STATE.md queue + a repo scan +
TODO. Write the chosen task into STATE.md before implementing.

## 5. Execution   [source: EXECUTION_CYCLE.md, EXECUTION_RULES.md, TASK_SIZE_POLICY.md]
One coherent objective per cycle. Respect S/M/L size limits — if too big, split and
do only the first slice. Design → implement → refactor. Advisory wall-clock budget:
CYCLE_TIMEOUT_MIN (from config.sh).

## 6. Quality Bar   [source: QUALITY_GATE.md, SELF_REVIEW.md, REVIEW_CHECKLIST.md]
Before committing: run the gate commands from config.sh yourself for fast feedback;
answer the self-review questions; verify the review checklist. Note: run.sh will
re-run the gates after you exit and roll back if they fail — so a green commit is
the only acceptable outcome.

## 7. Commit   [source: EXECUTION_RULES.md, GIT_SAFETY.md]
Commit your own work locally when gates pass: `git add -A && git commit -m "[agent] <task> — <result>"`.
Never push to a remote. Every change must be reversible.

## 8. Failure & Recovery   [source: FAILURE_RECOVERY.md]
On failure: log it, attempt a bounded fix. Do not swallow errors. If unrecoverable,
leave a clear WORKLOG entry; run.sh handles rollback and sets CONTROL=failed.

## 9. Control & Termination   [source: AUTONOMOUS_CONTROL.md, TERMINATION_POLICY.md, SUCCESS_CRITERIA.md, FINAL_SHUTDOWN.md]
Control states: enabled | paused | stop_requested | project_completed | failed.
When the project meets its success criteria (define them in Section 2), set
CONTROL=project_completed in config.sh so the loop stops. On stop_requested, finish
the current objective and do not start another.

## 10. State Discipline   [source: SYSTEM.md file-classification]
Every cycle, update STATE.md (status, next task, queue, blockers) and append to
WORKLOG.md (what you did, what remains). Record architectural decisions as
`[decision]`-tagged WORKLOG entries. No partial/untracked work left behind.
```

Acceptance criteria: all 10 headings present; Section 1 contains every core principle from `SYSTEM.md`; Sections 4–6 preserve the concrete rules (diff-aware planning, size limits, the gate list, self-review questions) from their source files; no references remain to deleted file names (e.g. "see RUNBOOK.md").

- [ ] **Step 2: Verify no dangling references**

Run:
```bash
grep -nE 'RUNBOOK|CHECKPOINT_MANAGER|CONTROL_FLAGS\.md|NEXT_TASK\.md|TASK_QUEUE\.md' .autoeng/AGENT.md || echo "clean"
```
Expected: `clean` (no references to removed files).

- [ ] **Step 3: Commit**

```bash
git add .autoeng/AGENT.md
git commit -m "docs: author AGENT.md — merged operating manual (constitution + workflow)"
```

---

## Task 12: Author `STATE.md` and `WORKLOG.md` templates

**Files:**
- Create: `.autoeng/STATE.md`
- Create: `.autoeng/WORKLOG.md`

- [ ] **Step 1: Write STATE.md**

Create `.autoeng/STATE.md`:

```markdown
# Project State

> The agent rewrites this file every cycle. It is the agent's working memory.

## Status
Not started. Set the mission in AGENT.md §2, then run `sh .autoeng/run.sh adopt`
(existing project) or seed a "Phase 0: bootstrap" task below (new project).

## Next task
(the single highest-priority task — chosen by the planning step each cycle)

## Task queue
- [ ] (prioritized backlog)

## Blockers
(none)

## Tech debt / risks
(none)
```

- [ ] **Step 2: Write WORKLOG.md**

Create `.autoeng/WORKLOG.md`:

```markdown
# Worklog

> Append-only. One entry per cycle. Tag architectural decisions with `[decision]`.

<!-- Newest entries on top. Format:
## YYYY-MM-DDTHH:MM:SSZ — <task>
- Did: ...
- Result: pass/fail, gates: ...
- Remaining: ...
-->
```

- [ ] **Step 3: Commit**

```bash
git add .autoeng/STATE.md .autoeng/WORKLOG.md
git commit -m "docs: add STATE.md and WORKLOG.md templates"
```

---

## Task 13: `install.sh` — copy the folder into a target project

**Files:**
- Create: `install.sh`
- Create: `tests/test_install.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_install.sh`:

```sh
# shellcheck disable=SC1091
. ./helpers.sh

target="$(mktemp -d)"
sh "$REPO_ROOT/install.sh" "$target" > out.log 2>&1
assert_file_exists "$target/.autoeng/run.sh" "run.sh copied to target"
assert_file_exists "$target/.autoeng/AGENT.md" "AGENT.md copied to target"
assert_file_exists "$target/.autoeng/config.sh" "config.sh copied to target"

# Refuses to clobber an existing .autoeng without --force.
sh "$REPO_ROOT/install.sh" "$target" > out2.log 2>&1
rc=$?
assert_eq "1" "$rc" "install refuses to overwrite existing .autoeng"
assert_contains "out2.log" "already exists" "explains the refusal"

rm -rf "$target"
exit "$TESTS_FAILED"
```

Note: run this test from the `tests/` dir (the runner does `cd tests`), so `$REPO_ROOT` resolves to the source repo root where `install.sh` and `.autoeng/` live.

- [ ] **Step 2: Run it to confirm it fails**

Run: `sh tests/run_tests.sh`
Expected: FAIL — `install.sh` does not exist.

- [ ] **Step 3: Write install.sh**

Create `install.sh`:

```sh
#!/bin/sh
# install.sh — copy the .autoeng/ framework into a target project.
# Usage: sh install.sh [target-dir]   (default: current directory)
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)/.autoeng"
TARGET="${1:-.}"
FORCE="${2:-}"

[ -d "$SRC" ] || { echo "ERROR: source .autoeng not found at $SRC" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "ERROR: target dir does not exist: $TARGET" >&2; exit 2; }

if [ -d "$TARGET/.autoeng" ] && [ "$FORCE" != "--force" ]; then
  echo "ERROR: $TARGET/.autoeng already exists. Re-run with --force to overwrite." >&2
  exit 1
fi

cp -r "$SRC" "$TARGET/.autoeng"
echo "Installed .autoeng/ into $TARGET"
echo "Next: edit $TARGET/.autoeng/config.sh (set EXECUTOR + CONTROL=enabled),"
echo "then run: sh $TARGET/.autoeng/run.sh adopt && sh $TARGET/.autoeng/run.sh loop"
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `sh tests/run_tests.sh`
Expected: `test_install.sh` passes (files copied; second run refused with exit 1).

- [ ] **Step 5: Commit**

```bash
git add install.sh tests/test_install.sh
git commit -m "feat: install.sh — copy framework into a target project"
```

---

## Task 14: Rewrite `README.md` and add `MIGRATION.md`

**Files:**
- Modify: `README.md` (full rewrite)
- Create: `MIGRATION.md`

- [ ] **Step 1: Rewrite README.md**

Replace `README.md` entirely with content covering, in this order:
1. **What it is** — 3 sentences (portable autonomous-engineering loop; drops into any repo; drives any coding agent).
2. **Quickstart (3 commands):**
   ```bash
   sh install.sh /path/to/your/project          # copy .autoeng/ in
   $EDITOR /path/to/your/project/.autoeng/config.sh   # set EXECUTOR + CONTROL=enabled
   sh /path/to/your/project/.autoeng/run.sh adopt && sh .../run.sh loop
   ```
3. **How it works** — the trust-boundary table (run.sh does lock/checkpoint/gate-verify/rollback/loop; the agent plans/implements/commits).
4. **Configuring the executor** — the three example strings (aider/claude/openclaw) + "any command works."
5. **Files** — the 5-item list (`AGENT.md`, `STATE.md`, `WORKLOG.md`, `config.sh`, `run.sh`).
6. **Greenfield vs existing** — `adopt` seeds gates + STATE; for new projects, set a Phase-0 bootstrap task.
7. **Safety** — checkpoints, lock, control flag, no remote pushes, gate rollback.
8. **Requirements** — Git, a POSIX shell, and any coding-agent CLI. No language runtime required by the framework itself.

Acceptance: no mention of OpenClaw as a *requirement*, no hardcoded `/mnt/c/...` paths, no `npm`-only assumptions, no reference to the 32-file layout.

- [ ] **Step 2: Write MIGRATION.md**

Create `MIGRATION.md` explaining, for existing `agent/` users: the `agent/` folder is replaced by `.autoeng/`; map old files → new (`SYSTEM.md`+workflow → `AGENT.md`; status/queue/etc → `STATE.md`; `CONTROL_FLAGS.md` → `CONTROL` in `config.sh`; cron → `run.sh loop` or cron calling `run.sh run`); steps to migrate (run `install.sh`, run `adopt`, port your mission into `AGENT.md §2`, delete `agent/`).

- [ ] **Step 3: Verify the quickstart commands are internally consistent**

Run:
```bash
grep -n "run.sh" README.md
```
Expected: every referenced subcommand (`adopt`, `loop`) exists in `.autoeng/run.sh` (cross-check against `main`'s `case`).

- [ ] **Step 4: Commit**

```bash
git add README.md MIGRATION.md
git commit -m "docs: rewrite README for portable framework; add MIGRATION guide"
```

---

## Task 15: Remove the old framework and finalize

**Files:**
- Delete: `agent/` (entire directory), `setup.sh`

- [ ] **Step 1: Confirm nothing still references the old layout**

Run:
```bash
grep -rnE 'agent/(SYSTEM|RUNBOOK|CONTROL_FLAGS|EXECUTION_CYCLE)' .autoeng README.md MIGRATION.md install.sh || echo "clean"
```
Expected: `clean`.

- [ ] **Step 2: Delete the old framework**

Run:
```bash
git rm -r agent setup.sh
```
(Git history preserves the old 32-file framework; no `profiles/strict/` copy — that would reintroduce the weight the redesign removed.)

- [ ] **Step 3: Run the full test suite**

Run: `sh tests/run_tests.sh`
Expected: `ALL TESTS PASSED`, exit 0.

- [ ] **Step 4: Lint the shell scripts (dev-only)**

Run:
```bash
command -v shellcheck >/dev/null && shellcheck -s sh .autoeng/run.sh install.sh tests/*.sh || echo "shellcheck not installed — skipping"
```
Expected: no errors (warnings acceptable; fix any genuine bug shellcheck flags).

- [ ] **Step 5: Smoke-test the real entrypoint end-to-end**

Run:
```bash
tmp="$(mktemp -d)"; ( cd "$tmp" && git init -q && git config user.email t@t && git config user.name t && echo x > a && git add -A && git commit -qm s )
sh install.sh "$tmp"
# Append overrides — config.sh is sourced top-to-bottom, so the last assignment wins.
# No sed/quote-escaping needed. Executor is a trivial "agent" that edits + commits.
cat >> "$tmp/.autoeng/config.sh" <<'EOF'
EXECUTOR="sh -c 'echo hi >> note.txt; git add -A; git commit -qm agent'"
GATE_BUILD="true"
GATE_LINT=""
GATE_TEST=""
CONTROL="enabled"
EOF
( cd "$tmp" && sh .autoeng/run.sh run )
test -f "$tmp/note.txt" && echo "SMOKE OK" || echo "SMOKE FAILED"
rm -rf "$tmp"
```
Expected: `SMOKE OK` — the real `run.sh` drove a real (trivial) executor, the gate passed, and a commit landed.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: remove legacy 32-file agent/ framework; .autoeng/ is now the framework"
```

---

## Self-review notes (already applied)

- **Spec coverage:** two-layer split (Tasks 3–10 run.sh + Task 11 AGENT.md); consolidation to 3 md + config + script (Tasks 2, 11, 12); executor as command string (Task 2 config, Task 6 invoke); trust boundary with gate re-run + rollback (Task 6); loop (Task 8); greenfield/existing via content + adopt (Task 10, 12); stack-agnostic gates (Task 10); migration + delete old files (Tasks 14, 15). All spec sections map to a task.
- **Control-state single source of truth:** `CONTROL` lives only in `config.sh`; `set_control`/`cmd_pause`/`cmd_stop` all edit it via the same `sed` form; `load_config` re-reads it every cycle (Task 8 loop relies on this).
- **Naming consistency:** `checkpoint_create`/`checkpoint_rollback`, `lock_acquire`/`lock_release`, `run_gates`, `invoke_executor`, `set_control`, `set_gate`, `cmd_run`/`cmd_loop`/`cmd_adopt`/`cmd_status`/`cmd_pause`/`cmd_stop` are used identically across every task that references them.
- **Marker cleanup:** the temporary `EXECUTOR_RAN` marker introduced in Task 4 is removed in Task 6, and the two dependent assertions in `test_lock.sh` are migrated to log-based assertions in the same task.
```
