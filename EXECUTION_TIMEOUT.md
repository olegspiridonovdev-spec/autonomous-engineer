# Execution Timeout â€” {{PROJECT_NAME}}

> **Timeout policy for autonomous execution.** Each phase of the execution cycle has a maximum duration. If any timeout is reached, save progress, update all tracking documents, and terminate gracefully. Never abandon partially completed work without recording its status.

---

## Timeout Limits

| Phase | Timeout | Description |
|-------|---------|-------------|
| **Total wall clock** | 15 minutes | Maximum duration of a single execution from start to finish |
| **Planning** | 3 minutes | Phases 1-4: Load Context, Analyze, Determine Progress, Select Task |
| **Implementation** | 8 minutes | Phases 5-7: Design, Implement, Refactor |
| **Review** | 2 minutes | Self-Review + Review Checklist + Quality Gate |
| **Recovery** | 5 minutes | Fix Failures (Phase 12) â€” max 3 rounds, each round capped at ~90 seconds |
| **Documentation** | 2 minutes | Phases 14-18: Update docs, TODO, status, next task, worklog |

**Internal iteration cap**: Maximum 2 internal iterations per execution (i.e., at most 2 completed objectives per run).

---

## Timeout Response

When any timeout is reached:

### Immediate Action

1. **Stop the current phase** â€” do not continue the current operation
2. **Save current state** â€” write any in-progress code to disk (even if incomplete)
3. **Mark incomplete code** â€” add `// TODO: [what was being done, what's left]` to any unfinished files

### Required Updates

4. **Update PROJECT_STATUS.md** â€” set task to "In Progress", note which timeout was hit
5. **Update NEXT_TASK.md** â€” same task, with notes on what's already done and what remains
6. **Update TODO.md** â€” mark task as "(in progress: [done], [remaining])"
7. **Update TASK_QUEUE.md** â€” task state = "In Progress"
8. **Append WORKLOG.md** â€” record:
   - Which timeout was hit (total, planning, implementation, review, recovery, documentation)
   - What was completed before the timeout
   - What remains to be done
   - Any partial code that was saved
9. **Update CONTROL_FLAGS.md** â€” if this is the 3rd consecutive timeout on the same task, set to `FAILED`

### Git

10. **Commit partial work** â€” only if the code compiles (`npx tsc --noEmit` passes). If it doesn't compile, do not commit.
11. **Commit message**: `[autonomous] [task name] â€” partial (timeout: [which timeout])`

### Terminate

12. **Terminate gracefully** â€” do not start another iteration

---

## Timeout Tracking

The autonomous engineer tracks timeout occurrences per task:

| Task ID | Consecutive Timeouts | Action |
|---------|---------------------|--------|
| Any | 1 | Normal â€” resume next run |
| Any | 2 | Warning â€” log in WORKLOG, consider splitting task (TASK_SIZE_POLICY.md) |
| Any | 3 | Set CONTROL_FLAGS.md to `FAILED` â€” human review required |

Consecutive timeouts are tracked in PROJECT_STATUS.md under "Known Issues":
```
Task T-XXX has N consecutive timeouts. Last timeout: [which phase].
```

When a task completes successfully, its timeout counter resets to 0.

---

## Rules

1. **Never silently abandon work.** If a timeout is hit, all tracking documents must be updated to reflect what was done and what remains.

2. **Never skip the update phase to save time.** Even if the total timeout is hit during implementation, the engineer must still update PROJECT_STATUS.md, NEXT_TASK.md, and WORKLOG.md before terminating. Documentation updates are not optional, even when rushed.

3. **Never use timeouts as an excuse for poor quality.** If the implementation phase timed out, the code that was written still must compile. Partial code with syntax errors is unacceptable â€” add `// TODO` and make it compile.

4. **Timeouts are symptoms, not causes.** If a task consistently times out, the task is too large (split per TASK_SIZE_POLICY.md) or the approach is wrong (escalate per FAILURE_RECOVERY.md).

5. **The total wall clock timeout is a hard limit.** No phase may extend beyond it. If the total timeout is reached mid-phase, stop immediately and follow the timeout response.