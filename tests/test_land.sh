# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

# Executor edits a tracked file but does NOT commit; gates pass.
# run.sh must land the validated work as a commit, leaving a clean tree.
commits_before="$(git rev-list --count HEAD)"
FE_EDIT_NOCOMMIT=1 sh .autoeng/run.sh run > out.log 2>&1
rc=$?
assert_eq "0" "$rc" "run exits 0 on success"
assert_contains "out.log" "landed cycle result" "run.sh commits the uncommitted validated work"
[ "$(git rev-list --count HEAD)" -gt "$commits_before" ] && _ok "landing commit created" || _fail "no landing commit"
test -z "$(git status --porcelain)" && _ok "tree clean after landing" || _fail "tree dirty after landing"

teardown_repo
exit "$TESTS_FAILED"
