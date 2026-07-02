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
  SANDBOX="$(mktemp -d)"
  cp -r "$REPO_ROOT/.autoeng" "$SANDBOX/.autoeng"
  cd "$SANDBOX" || exit 1
  git init -q
  git config user.email test@test.local
  git config user.name test
  echo "seed" > seed.txt
  git add -A && git commit -qm "seed"
  # Overwrite config for tests: executor = fake, gate = BUILD_OK sentinel.
  cat > .autoeng/config.sh <<EOF
EXECUTOR="sh $REPO_ROOT/tests/fake-executor.sh"
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
