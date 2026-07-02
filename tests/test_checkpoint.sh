# shellcheck disable=SC1091
. ./helpers.sh
setup_repo

head_before="$(git rev-parse HEAD)"
sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_exists ".autoeng/CHECKPOINT" "checkpoint file written"
recorded="$(cat .autoeng/CHECKPOINT)"
assert_eq "$head_before" "$recorded" "checkpoint records HEAD when tree is clean"

# Dirty tree: checkpoint commits pending work so rollback can restore it.
setup_repo
echo "dirty" >> seed.txt
sh .autoeng/run.sh run > out.log 2>&1 || true
assert_file_exists ".autoeng/CHECKPOINT" "checkpoint file written (dirty)"
test -z "$(git status --porcelain)" && _ok "tree clean after checkpoint commit" \
  || _fail "tree still dirty after checkpoint"
teardown_repo

exit "$TESTS_FAILED"
