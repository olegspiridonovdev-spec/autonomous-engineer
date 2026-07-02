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
