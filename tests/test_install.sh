# shellcheck disable=SC1091
. ./helpers.sh

target="$(mktemp -d)"
sh "$REPO_ROOT/install.sh" "$target" > "$target/out.log" 2>&1
assert_file_exists "$target/.autoeng/run.sh" "run.sh copied to target"
assert_file_exists "$target/.autoeng/AGENT.md" "AGENT.md copied to target"
assert_file_exists "$target/.autoeng/config.sh" "config.sh copied to target"

# Refuses to clobber an existing .autoeng without --force.
sh "$REPO_ROOT/install.sh" "$target" > "$target/out2.log" 2>&1
rc=$?
assert_eq "1" "$rc" "install refuses to overwrite existing .autoeng"
assert_contains "$target/out2.log" "already exists" "explains the refusal"

# --force overwrites cleanly (no nested .autoeng/.autoeng).
sh "$REPO_ROOT/install.sh" "$target" --force > "$target/out3.log" 2>&1
rc=$?
assert_eq "0" "$rc" "install --force succeeds"
assert_file_absent "$target/.autoeng/.autoeng/run.sh" "no nested .autoeng after --force"
assert_file_exists "$target/.autoeng/run.sh" "run.sh still present after --force"

rm -rf "$target"
exit "$TESTS_FAILED"
