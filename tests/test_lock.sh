# shellcheck disable=SC1091
. ./helpers.sh

# Case A: a fresh LOCK blocks the run.
setup_repo
printf 'LOCKED\nepoch: %s\n' "$(date +%s)" > .autoeng/LOCK
FE_MARKER=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_contains "out.log" "another run" "fresh lock blocks executor"
teardown_repo

# Case B: a stale LOCK (old epoch) is recovered and the run proceeds.
setup_repo
printf 'LOCKED\nepoch: 100\n' > .autoeng/LOCK   # epoch 100 = 1970, always stale
FE_MARKER=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_contains "out.log" "invoking executor" "stale lock recovered, executor ran"
assert_contains "out.log" "stale lock" "logs stale-lock recovery"
teardown_repo

exit "$TESTS_FAILED"
