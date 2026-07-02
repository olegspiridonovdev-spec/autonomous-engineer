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
