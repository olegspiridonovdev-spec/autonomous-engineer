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
