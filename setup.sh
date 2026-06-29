#!/usr/bin/env bash
# setup.sh — Scaffold Autonomous Engineer into a new project
#
# Usage: bash setup.sh /path/to/your/project [project-name]
#
# Copies agent/ folder, replaces template placeholders with project name,
# and creates initial docs/ structure if missing.

set -euo pipefail

TARGET="${1:-}"
PROJECT_NAME="${2:-My Project}"
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

if [ -z "$TARGET" ]; then
  echo "Usage: bash setup.sh /path/to/your/project [project-name]"
  echo ""
  echo "Example: bash setup.sh ~/projects/my-app 'My App'"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "ERROR: Target directory does not exist: $TARGET"
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  echo "WARNING: Target is not a git repo. Initializing..."
  (cd "$TARGET" && git init)
fi

AGENT_DIR="$TARGET/agent"

if [ -d "$AGENT_DIR" ]; then
  echo "WARNING: agent/ directory already exists. Overwrite? [y/N]"
  read -r REPLY
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Copy agent files
mkdir -p "$AGENT_DIR"
cp -r "$SCRIPT_DIR"/agent/* "$AGENT_DIR/"

# Replace placeholders
find "$AGENT_DIR" -type f \( -name "*.md" -o -name "*.sh" \) -exec sed -i \
  -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
  -e "s/{{PROJECT_SLUG}}/$PROJECT_SLUG/g" \
  {} +

# Create docs structure if missing
mkdir -p "$TARGET/docs"

if [ ! -f "$TARGET/docs/ARCHITECTURE.md" ]; then
  cat > "$TARGET/docs/ARCHITECTURE.md" << 'EOF
# Architecture

> Source of truth for system design. The autonomous agent respects this file.

## Overview

<!-- Describe your system architecture here -->

## Components

<!-- List your components and their responsibilities -->

## Data Flow

<!-- Describe how data moves through your system -->
EOF
  echo "Created: docs/ARCHITECTURE.md"
fi

if [ ! -f "$TARGET/docs/PLAN.md" ]; then
  cat > "$TARGET/docs/PLAN.md" << 'EOF'
# Project Plan

> Phased plan and timeline. The autonomous agent uses this for task prioritization.

## Phase 1: {{PHASE_NAME}}

<!-- Define your phases -->

## Milestones

<!-- Key milestones -->
EOF
  echo "Created: docs/PLAN.md"
fi

if [ ! -f "$TARGET/TODO.md" ]; then
  cat > "$TARGET/TODO.md" << 'EOF'
# TODO

> Implementation checklist by phase. The autonomous agent checks off items as they complete.

## Phase 1

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF
  echo "Created: TODO.md"
fi

# Set CONTROL_FLAGS to ENABLED
cat > "$AGENT_DIR/CONTROL_FLAGS.md" << EOF
# Control Flags — $PROJECT_NAME

> **Lightweight control mechanism.** The autonomous engineer checks this file before doing any work. If the state is not ENABLED, follow AUTONOMOUS_CONTROL.md before proceeding.

---

## Current State

\`\`\`
ENABLED
\`\`\`

---

## Possible Values

| Value | Meaning | Action |
|-------|---------|--------|
| \`ENABLED\` | Agent may execute normally | Proceed with full execution cycle |
| \`PAUSED\` | Execution suspended | Update status, terminate immediately |
| \`STOP_REQUESTED\` | Graceful stop after current objective | Finish current objective, do not start another |
| \`PROJECT_COMPLETED\` | Project satisfies SUCCESS_CRITERIA.md | No further development |
| \`FAILED\` | Recovery limits exceeded, human review required | Suspend execution |

---

## How to Change State

Edit this file and replace the value between the triple backticks above.
EOF

echo ""
echo "✅ Autonomous Engineer scaffolded into: $TARGET"
echo "   Project: $PROJECT_NAME"
echo "   Slug: $PROJECT_SLUG"
echo ""
echo "Next steps:"
echo "  1. Edit agent/PROJECT_STATUS.md with your project phases"
echo "  2. Edit agent/NEXT_TASK.md with your first task"
echo "  3. Edit agent/TASK_QUEUE.md with your task list"
echo "  4. Edit agent/SUCCESS_CRITERIA.md with completion criteria"
echo "  5. Configure cron job (see agent/CRON_SETUP.md)"
echo "  6. Set agent/CONTROL_FLAGS.md to ENABLED"
echo ""
echo "See README.md for full documentation."