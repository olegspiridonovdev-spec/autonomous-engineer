#!/usr/bin/env bash
# CHECKPOINT_MANAGER.sh â€” Git checkpoint management for autonomous execution
#
# Creates a safe baseline commit before each execution cycle.
# Never pushes to remote automatically.
#
# Usage: bash agent/CHECKPOINT_MANAGER.sh "<objective>"
#
# Exit codes:
#   0 â€” checkpoint created successfully
#   1 â€” git not initialized
#   2 â€” cannot create checkpoint (permission error, disk full, etc.)

set -euo pipefail

OBJECTIVE="${1:-unknown objective}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# --- 1. Detect git state ---

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: Git repository not initialized."
  echo "Run 'git init' before executing autonomous work."
  exit 1
fi

# --- 2. Ensure working directory is clean OR safely stashed ---

GIT_STATUS=$(git status --porcelain)

if [ -n "$GIT_STATUS" ]; then
  # Working directory is dirty â€” stash changes
  STASH_MSG="agent: stash before checkpoint ($OBJECTIVE)"
  git stash push -m "$STASH_MSG" --include-untracked || {
    echo "ERROR: Cannot stash uncommitted changes."
    exit 2
  }
  echo "STASHED: Uncommitted changes saved: $STASH_MSG"
fi

# --- 3. Read previous checkpoint (if exists) ---

PREVIOUS="none"
if [ -f "$SCRIPT_DIR/CHECKPOINT" ]; then
  PREVIOUS=$(grep "^checkpoint:" "$SCRIPT_DIR/CHECKPOINT" | head -1 | awk '{print $2}')
fi

# --- 4. Create checkpoint commit ---

CHECKPOINT_MSG="agent checkpoint: $TIMESTAMP - $OBJECTIVE"
git commit --allow-empty -m "$CHECKPOINT_MSG" 2>/dev/null || {
  # If nothing to commit and --allow-empty not supported, try without
  if git diff --cached --quiet && git diff --quiet; then
    # Force create empty commit
    git commit --allow-empty -m "$CHECKPOINT_MSG" || {
      echo "ERROR: Cannot create checkpoint commit."
      exit 2
    }
  fi
}

# --- 5. Get checkpoint hash ---

CHECKPOINT_HASH=$(git rev-parse HEAD)
SHORT_HASH=$(git rev-parse --short HEAD)

echo "CHECKPOINT: $SHORT_HASH ($CHECKPOINT_HASH)"
echo "MESSAGE: $CHECKPOINT_MSG"

# --- 6. Write checkpoint file ---

cat > "$SCRIPT_DIR/CHECKPOINT" << EOF
checkpoint: $CHECKPOINT_HASH
timestamp: $TIMESTAMP
objective: $OBJECTIVE
previous: $PREVIOUS
EOF

echo "WRITTEN: agent/CHECKPOINT"

# --- 7. Verify checkpoint ---

echo ""
echo "=== Verification ==="
git log --oneline -3

# --- 8. Confirm no push ---

# This script NEVER pushes to remote.
# All pushes are manual and performed by humans only.

exit 0