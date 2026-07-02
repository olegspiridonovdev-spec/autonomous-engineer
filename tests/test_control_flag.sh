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
