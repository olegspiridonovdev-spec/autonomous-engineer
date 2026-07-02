# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

# Executor sets CONTROL=project_completed on its 2nd invocation → loop stops after 2.
FE_EDIT=1 FE_COMPLETE_AT=2 sh .autoeng/run.sh loop > out.log 2>&1 || true
assert_eq "2" "$(cat .autoeng/FE_COUNT)" "loop ran exactly 2 cycles then stopped"
assert_contains "out.log" "loop: control is 'project_completed'" "loop exits on completion"

teardown_repo
exit "$TESTS_FAILED"
