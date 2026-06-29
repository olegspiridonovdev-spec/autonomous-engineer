# Cron Setup â€” {{PROJECT_NAME}} Autonomous Execution

> **How to enable autonomous execution via cron.** This document describes the scheduling configuration, concurrency rules, and logging.

---

## Schedule

Autonomous execution runs every **15 minutes** via cron.

### Cron Expression

```
*/15 * * * * bash /path/to/{{PROJECT_SLUG}}/agent/run.sh >> /path/to/{{PROJECT_SLUG}}/agent/execution.log 2>&1
```

Replace `/path/to/{{PROJECT_SLUG}}/` with the actual project path:
```
/mnt/c/Users/Oleg/Documents/Projects/{{PROJECT_SLUG}}
```

### Why 15 Minutes

- Short enough to make meaningful progress across a day (96 runs/day max)
- Long enough to avoid overlapping with a previous run (typical run: 2-10 min)
- Allows the agent to complete one task per run without time pressure
- Matches the EXECUTION_TIMEOUT.md total wall clock of 15 minutes

### Alternative Schedules

| Frequency | Cron | Use case |
|-----------|------|----------|
| Every 10 min | `*/10 * * * *` | Aggressive development â€” more runs per day |
| Every 15 min | `*/15 * * * *` | **Recommended** â€” balanced |
| Every 30 min | `*/30 * * * *` | Conservative â€” lower API costs, slower progress |
| Every hour | `0 * * * *` | Maintenance mode â€” only bug fixes and small tasks |

---

## Concurrency Rules

### Rule 1: Only One Instance at a Time

The `agent/LOCK` file ensures no parallel execution. Before any work, `run.sh` checks for LOCK:
- **LOCK exists, age < 30 min** â†’ skip this run (another instance is active)
- **LOCK exists, age â‰¥ 30 min** â†’ stale lock, remove and continue (previous run crashed)
- **LOCK does not exist** â†’ create LOCK, proceed with execution

### Rule 2: No Overlapping Runs

If a previous run is still active when cron triggers the next:
- The new run detects the LOCK and exits immediately
- No work is duplicated
- No git conflicts

### Rule 3: Log All Executions

Every run appends to `agent/execution.log`:
```
=== Autonomous execution started at 2026-06-29T01:15:00Z ===
Project: /mnt/c/Users/Oleg/Documents/Projects/{{PROJECT_SLUG}}
Control: ENABLED
Git: abc1234 [autonomous] 1.2 TypeScript Types â€” completed
---
```

The log is append-only and rotated when it exceeds 1MB (rename to `execution.log.old`).

---

## OpenClaw Cron Integration

In OpenClaw, autonomous execution is triggered via a cron job that sends a message to the autonomous engineer agent session.

### Setup via OpenClaw Cron

Instead of system crontab, use OpenClaw's cron tool:

```
Job: {{PROJECT_SLUG}}-autonomous
Schedule: every 15 minutes
SessionTarget: isolated
Payload: agentTurn
Message: "Execute autonomous engineering cycle. Read agent/RUNBOOK.md and follow it completely."
Working directory: C:\Users\Oleg\Documents\Projects\{{PROJECT_SLUG}}
```

This creates an isolated session for each autonomous run, preventing context pollution in the main session.

### Manual Trigger

To trigger a manual run (outside of cron):

```bash
bash /mnt/c/Users/Oleg/Documents/Projects/{{PROJECT_SLUG}}/agent/run.sh
```

Or via OpenClaw:

Send a message to the autonomous engineer session:
> "Execute autonomous engineering cycle. Read agent/RUNBOOK.md and follow it completely."

---

## Lifecycle

```
cron triggers (every 15 min)
        â”‚
        â–¼
run.sh executes
        â”‚
        â–¼
Check LOCK file
        â”‚
        â”œâ”€ LOCK exists (fresh) â†’ exit (skip)
        â”œâ”€ LOCK exists (stale) â†’ remove, log recovery
        â””â”€ no LOCK â†’ create LOCK
                â”‚
                â–¼
        Check CONTROL_FLAGS.md
                â”‚
                â”œâ”€ not ENABLED â†’ log, remove LOCK, exit
                â””â”€ ENABLED
                        â”‚
                        â–¼
                Delegate to agent runner
                        â”‚
                        â–¼
                Agent reads RUNBOOK.md
                        â”‚
                        â–¼
                Execute one engineering objective
                        â”‚
                        â–¼
                Quality validation (build/lint/typecheck/test)
                        â”‚
                        â”œâ”€ fail â†’ FAILURE_RECOVERY â†’ update docs â†’ remove LOCK â†’ exit
                        â””â”€ pass â†’ SELF_REVIEW â†’ QUALITY_GATE â†’ update docs â†’ commit â†’ remove LOCK â†’ exit
```

---

## Monitoring

### Health Checks

| Check | How | Alert |
|-------|-----|-------|
| Is cron running? | Check `execution.log` last entry timestamp | If > 30 min since last entry, cron may be down |
| Is agent making progress? | Check `WORKLOG.md` last entry | If no new entry in 1 hour, agent may be stuck |
| Is build passing? | Check `PROJECT_STATUS.md` Build Status | If "failing" for > 1 hour, investigate |
| Is system FAILED? | Check `CONTROL_FLAGS.md` | If FAILED, human intervention needed |
| Is LOCK stale? | Check `agent/LOCK` timestamp | If LOCK exists and is > 30 min old, previous run crashed |

### Log Files

| File | Content |
|------|---------|
| `agent/execution.log` | All run.sh invocations (cron log) |
| `agent/WORKLOG.md` | Detailed engineering journal per run |
| `agent/PROJECT_STATUS.md` | Current project state snapshot |

---

## Safety

1. **No parallel execution** â€” LOCK file guarantees this
2. **No uncontrolled loops** â€” max 2 internal iterations per run (EXECUTION_TIMEOUT.md)
3. **Automatic recovery** â€” stale LOCK detection after 30 minutes
4. **Graceful degradation** â€” FAILED state stops execution until human review
5. **Full traceability** â€” every run logged in execution.log + WORKLOG.md + git commits