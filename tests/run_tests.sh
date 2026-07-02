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
