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
