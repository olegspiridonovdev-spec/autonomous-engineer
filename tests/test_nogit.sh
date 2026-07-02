# shellcheck disable=SC1091
. ./helpers.sh

# A control=enabled project dir that is NOT a git repo must fail cleanly and leak no LOCK.
sandbox="$(mktemp -d)"
cp -r "$REPO_ROOT/.autoeng" "$sandbox/.autoeng"
cd "$sandbox" || exit 1
sed 's/^CONTROL=.*/CONTROL="enabled"/' .autoeng/config.sh > .autoeng/config.sh.tmp \
  && mv .autoeng/config.sh.tmp .autoeng/config.sh
sh .autoeng/run.sh run > out.log 2>&1
rc=$?
[ "$rc" -ne 0 ] && _ok "run fails on a non-git dir" || _fail "run should fail on non-git dir (rc=$rc)"
assert_contains "out.log" "not a git repository" "logs a clear non-git error"
assert_file_absent ".autoeng/LOCK" "no LOCK leaked on non-git failure"

cd "$REPO_ROOT" || exit 1
rm -rf "$sandbox"
exit "$TESTS_FAILED"
