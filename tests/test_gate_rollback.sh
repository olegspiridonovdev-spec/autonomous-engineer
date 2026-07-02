# shellcheck disable=SC1091
. ./helpers.sh

# Case 1: executor commits a change, then breaks the build. Rollback discards the commit.
setup_repo
checkpoint_head="$(git rev-parse HEAD)"
FE_EDIT=1 FE_BREAK=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_contains "out.log" "gate failed" "logs the gate failure"
assert_file_absent "work.txt" "executor's change was rolled back"
assert_eq "$checkpoint_head" "$(git rev-parse HEAD)" "HEAD reset to checkpoint"
assert_contains ".autoeng/config.sh" 'CONTROL="failed"' "control set to failed"
assert_file_absent ".autoeng/LOCK" "lock released after failure"
teardown_repo

# Case 2: executor leaves an UNTRACKED file and breaks the gate. Rollback must clean it.
setup_repo
FE_BREAK=1 FE_UNTRACKED=1 sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_absent "untracked_junk.txt" "untracked leftover cleaned on rollback"
assert_file_exists "BUILD_OK" "reset restored the tracked gate sentinel"
teardown_repo

exit "$TESTS_FAILED"
