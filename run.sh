#!/usr/bin/env bash
# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# {{PROJECT_NAME}} â€” Autonomous Engineer Launcher
# This is the ONLY executable entrypoint for autonomous execution.
# It contains NO logic. It only sets up the environment and
# delegates to the agent runner.
# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

set -euo pipefail

# â”€â”€â”€ Project root â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="$PROJECT_ROOT/agent"

# â”€â”€â”€ Load environment variables â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ENV_KEYS_FILE="${ENV_KEYS_FILE:-/mnt/c/Users/Oleg/.env.keys.txt}"
if [ -f "$ENV_KEYS_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_KEYS_FILE"
  set +a
fi

# Export Vite-compatible variables for the project
export VITE_OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export VITE_ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export VITE_GOOGLE_API_KEY="${GEMINI_API_KEY:-}"

# â”€â”€â”€ Verify git state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
cd "$PROJECT_ROOT"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

# Report git status (informational, not blocking)
GIT_STATUS="$(git status --porcelain)"
if [ -n "$GIT_STATUS" ]; then
  echo "INFO: Git working tree has uncommitted changes"
else
  echo "INFO: Git working tree is clean"
fi

# â”€â”€â”€ Verify required files exist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
for REQUIRED in \
  "$AGENT_DIR/SYSTEM.md" \
  "$AGENT_DIR/CONTROL_FLAGS.md" \
  "$AGENT_DIR/RUNBOOK.md" \
  "$AGENT_DIR/AUTONOMOUS_ENGINEER.md"; do
  if [ ! -f "$REQUIRED" ]; then
    echo "ERROR: Required file missing: $REQUIRED" >&2
    exit 1
  fi
done

# â”€â”€â”€ Verify CONTROL_FLAGS is ENABLED â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CONTROL_STATE="$(grep -E '^(ENABLED|PAUSED|STOP_REQUESTED|PROJECT_COMPLETED|FAILED)$' "$AGENT_DIR/CONTROL_FLAGS.md" | head -1)"
if [ "$CONTROL_STATE" != "ENABLED" ]; then
  echo "INFO: Control flag is $CONTROL_STATE â€” autonomous execution not enabled"
  exit 0
fi

# â”€â”€â”€ Delegate to agent runner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# The agent runner is the AI model/agent that reads RUNBOOK.md
# and executes the autonomous cycle. In OpenClaw, this is
# triggered by sending a message to the autonomous engineer
# session with instructions to follow RUNBOOK.md.
#
# This script is called by cron. The actual AI execution is
# handled by the OpenClaw runtime which invokes the agent.
#
# See CRON_SETUP.md for scheduling configuration.

echo "=== Autonomous execution started at $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "Project: $PROJECT_ROOT"
echo "Control: $CONTROL_STATE"
echo "Git: $(git log --oneline -1)"
echo "---"

# Signal to OpenClaw runtime that an autonomous run is requested.
# The runtime picks this up and executes RUNBOOK.md via the agent.
echo "RUNBOOK_TRIGGERED"

exit 0