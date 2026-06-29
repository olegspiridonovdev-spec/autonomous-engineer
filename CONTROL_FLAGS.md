# Control Flags â€” {{PROJECT_NAME}}

> **Lightweight control mechanism.** The autonomous engineer checks this file before doing any work. If the state is not ENABLED, follow AUTONOMOUS_CONTROL.md before proceeding.

---

## Current State

```
ENABLED
```

---

## Possible Values

| Value | Meaning | Action |
|-------|---------|--------|
| `ENABLED` | Agent may execute normally | Proceed with full execution cycle |
| `PAUSED` | Execution suspended | Update status, terminate immediately (see AUTONOMOUS_CONTROL.md) |
| `STOP_REQUESTED` | Graceful stop after current objective | Finish current objective, do not start another (see AUTONOMOUS_CONTROL.md) |
| `PROJECT_COMPLETED` | Project satisfies SUCCESS_CRITERIA.md | No further development (see AUTONOMOUS_CONTROL.md) |
| `FAILED` | Recovery limits exceeded, human review required | Suspend execution (see AUTONOMOUS_CONTROL.md) |

---

## Check Points

The autonomous engineer reads this file:

1. **At startup** â€” before reading any other documents
2. **Before each internal iteration** â€” before starting a new objective (EXECUTION_CYCLE.md Phase 19)
3. **Before committing** â€” verify execution was not paused mid-run

If the state is not `ENABLED`, do not proceed with work. Follow the protocol in AUTONOMOUS_CONTROL.md for the current state.

---

## How to Change State

**Human changes:**
- Edit this file and replace the value between the triple backticks above
- No other action needed â€” the autonomous engineer will pick up the new state on next invocation

**Autonomous engineer changes:**
- `STOP_REQUESTED` â†’ `PAUSED` (after finishing current objective)
- `ENABLED` â†’ `FAILED` (after exceeding recovery limits)
- `ENABLED` â†’ `PROJECT_COMPLETED` (after satisfying SUCCESS_CRITERIA.md)
- All changes logged in WORKLOG.md

---

## Rule

**This file is the single source of truth for execution state.** No other file overrides or contradicts the state set here. The autonomous engineer must never ignore or bypass the control flag.