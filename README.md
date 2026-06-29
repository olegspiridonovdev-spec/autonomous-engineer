# Autonomous Engineer

A universal autonomous engineering agent framework for AI-driven software development.

## What This Is

A self-contained agent system that autonomously develops software projects through iterative cycles. Each cycle:
- Reads project state and tracking files
- Plans the highest-priority task
- Implements it with quality gates (build, lint, typecheck)
- Commits with git checkpoints (rollback-safe)
- Updates all tracking files

The agent runs on a cron schedule and operates entirely through file-based state — no database, no external services, no state outside your git repo.

## Quick Start

### 1. Scaffold into your project

```bash
# Clone this repo
git clone https://github.com/spiridonov-oa/autonomous-engineer.git

# Copy agent/ folder into your project
cp -r autonomous-engineer/agent /path/to/your/project/agent

# Or use the setup script
bash autonomous-engineer/setup.sh /path/to/your/project
```

### 2. Configure for your project

Edit these files to match your project:

| File | What to Change |
|------|----------------|
| `agent/SYSTEM.md` | Replace `{{PROJECT_NAME}}` with your project name |
| `agent/AUTONOMOUS_ENGINEER.md` | Replace `{{PROJECT_NAME}}`, update mission statement |
| `agent/CONTROL_FLAGS.md` | Replace `{{PROJECT_NAME}}`, set state to `ENABLED` |
| `agent/PROJECT_STATUS.md` | Define your project phases and progress |
| `agent/NEXT_TASK.md` | Set your first task |
| `agent/TASK_QUEUE.md` | Populate with your task list |
| `agent/SUCCESS_CRITERIA.md` | Define what "done" means for your project |
| `agent/CRON_SETUP.md` | Configure cron job for your OpenClaw setup |

### 3. Create project-specific docs

The agent expects these files in your project root:

```
your-project/
├── agent/              ← this framework
├── docs/
│   ├── ARCHITECTURE.md ← system design source of truth
│   └── PLAN.md         ← phased plan, timeline
├── TODO.md             ← implementation checklist
└── ...your source code
```

### 4. Set up the cron job

See `agent/CRON_SETUP.md` for OpenClaw cron configuration. The agent runs as an isolated cron job.

### 5. Enable and go

Set `agent/CONTROL_FLAGS.md` to `ENABLED` and the agent starts working on next cron tick.

## How It Works

```
┌─────────────────────────────────────────────────┐
│                  Cron Tick                        │
│                                                   │
│  1. Check CONTROL_FLAGS.md → ENABLED?             │
│  2. Check LOCK → not running?                     │
│  3. Create git checkpoint (rollback baseline)     │
│  4. Read all tracking files + project docs        │
│  5. Plan: analyze git diff, select highest task   │
│  6. Execute: implement task (edit, write, code)   │
│  7. Validate: build, lint, typecheck               │
│  8. If fail: FAILURE_RECOVERY (rollback if needed)│
│  9. If pass: SELF_REVIEW → QUALITY_GATE            │
│ 10. Update tracking files + git commit             │
│ 11. Remove LOCK                                   │
│ 12. Exit                                          │
└─────────────────────────────────────────────────┘
```

## File Structure

```
agent/
├── SYSTEM.md              ← Immutable foundational rules (DO NOT EDIT during runs)
├── AUTONOMOUS_ENGINEER.md  ← Orchestrator — workflow strategy
├── RUNBOOK.md              ← Entry point — exact execution sequence
├── CONTROL_FLAGS.md       ← ENABLED / PAUSED / STOP_REQUESTED / FAILED
├── AUTONOMOUS_CONTROL.md  ← State machine for control flags
├── PLANNING_ENGINE.md     ← Task discovery, selection, prioritization
├── EXECUTION_CYCLE.md     ← 20-phase execution lifecycle
├── EXECUTION_RULES.md     ← Rules governing execution behavior
├── EXECUTION_TIMEOUT.md   ← Time budget management
├── TASK_SIZE_POLICY.md    ← S/M/L task sizing constraints
├── QUALITY_GATE.md        ← Build/lint/typecheck validation
├── REVIEW_CHECKLIST.md    ← Pre-commit review checklist
├── SELF_REVIEW.md         ← Post-implementation self-review
├── CHECKLIST.md           ← General execution checklist
├── FAILURE_RECOVERY.md    ← Error handling, rollback, retry
├── GIT_SAFETY.md          ← Git operations safety rules
├── DIFF_PLANNING.md       ← Diff-aware planning strategy
├── TERMINATION_POLICY.md  ← When to stop running
├── SUCCESS_CRITERIA.md    ← Define project completion
├── FINAL_SHUTDOWN.md      ← Clean shutdown procedure
├── CRON_SETUP.md          ← OpenClaw cron job configuration
├── CHECKPOINT_MANAGER.sh ← Git checkpoint script
├── run.sh                 ← Manual run script
│
├── PROJECT_STATUS.md      ← Current project state (updated each run)
├── NEXT_TASK.md           ← Single highest-priority task (updated each run)
├── TASK_QUEUE.md          ← Full prioritized task list
├── BLOCKERS.md            ← Active blockers
├── TECH_DEBT.md           ← Technical debt tracker
├── RISK_REGISTER.md       ← Project risks
├── DECISIONS.md           ← Architecture decision log (append-only)
├── WORKLOG.md             ← Chronological execution log (append-only)
├── CHECKPOINT             ← Last checkpoint hash (auto-generated)
└── LOCK                   ← Run lock (auto-created/removed)
```

## Safety Features

- **Git checkpoints** — every run starts with a baseline commit for rollback
- **LOCK file** — prevents concurrent runs
- **Control flags** — human can pause/stop at any time via a single file
- **Quality gates** — build + lint + typecheck must pass before commit
- **Failure recovery** — automatic rollback on 3 consecutive build failures
- **No remote pushes** — agent never pushes to remote, only commits locally
- **File-based state** — all state lives in your git repo, fully auditable

## Requirements

- **OpenClaw** — the agent runs as an OpenClaw cron job with `agentTurn` payload
- **Git** — project must be a git repo
- **Node.js** — for build/lint/typecheck validation (configurable in QUALITY_GATE.md)
- **LLM model** — any model supported by OpenClaw (tested with GLM 5.2)

## Customization

The framework is designed to be project-agnostic. Key customization points:

1. **Quality gates** (`QUALITY_GATE.md`) — change build/lint/test commands to match your stack
2. **Task sizing** (`TASK_SIZE_POLICY.md`) — adjust S/M/L limits for your complexity
3. **Success criteria** (`SUCCESS_CRITERIA.md`) — define what "done" means
4. **Planning** (`PLANNING_ENGINE.md`) — customize task discovery for your workflow
5. **Timeouts** (`EXECUTION_TIMEOUT.md`) — tune for your model speed

## License

MIT — use freely, share with friends, build cool stuff.

## Origin

Extracted from the [IQ Assessor](https://github.com/spiridonov-oa/iq-assessor) project, where this framework autonomously implemented Phase 1 (MVP) and Phase 2 (Backend) over 17+ successful runs.