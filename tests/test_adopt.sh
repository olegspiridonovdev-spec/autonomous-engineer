# shellcheck disable=SC1091
. ./helpers.sh

# Node project → npm gates.
setup_repo
echo '{"name":"x","scripts":{"build":"echo b","lint":"echo l","test":"echo t"}}' > package.json
git add -A && git commit -qm "add package.json"
sh .autoeng/run.sh adopt > out.log 2>&1
assert_contains ".autoeng/config.sh" 'GATE_BUILD="npm run build"' "npm build gate detected"
assert_contains ".autoeng/config.sh" 'GATE_TEST="npm test"' "npm test gate detected"
assert_contains ".autoeng/STATE.md" "Adopted" "STATE.md seeded on adopt"
teardown_repo

# Go project → go gates.
setup_repo
echo "module x" > go.mod
git add -A && git commit -qm "add go.mod"
sh .autoeng/run.sh adopt > out.log 2>&1
assert_contains ".autoeng/config.sh" 'GATE_BUILD="go build ./..."' "go build gate detected"
teardown_repo

exit "$TESTS_FAILED"
