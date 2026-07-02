# tests/fake-executor.sh — stand-in for a real coding agent.
# Runs inside the sandbox repo (cwd) exactly like a real $EXECUTOR would.
# Env knobs (all optional):
#   FE_MARKER=1     -> write .autoeng/EXECUTOR_RAN so tests can prove it was invoked
#   FE_EDIT=1       -> make a change and commit it (simulates real work)
#   FE_BREAK=1      -> remove BUILD_OK so the gate re-run fails
#   FE_COMPLETE_AT=N-> on the Nth invocation, set CONTROL=project_completed (for loop tests)

COUNT_FILE=".autoeng/FE_COUNT"
n=0; [ -f "$COUNT_FILE" ] && n=$(cat "$COUNT_FILE"); n=$((n + 1)); echo "$n" > "$COUNT_FILE"

[ "${FE_MARKER:-0}" = 1 ] && : > .autoeng/EXECUTOR_RAN
[ "${FE_BREAK:-0}" = 1 ] && rm -f BUILD_OK

if [ "${FE_EDIT:-0}" = 1 ]; then
  echo "work $n" >> work.txt
  git add -A && git commit -qm "[agent] work $n"
fi

if [ -n "${FE_COMPLETE_AT:-}" ] && [ "$n" -ge "$FE_COMPLETE_AT" ]; then
  sed -i.bak 's/^CONTROL=.*/CONTROL="project_completed"/' .autoeng/config.sh && rm -f .autoeng/config.sh.bak
fi
exit 0
