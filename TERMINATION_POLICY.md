# Termination Policy â€” {{PROJECT_NAME}}

> **Defines when an autonomous execution should stop.** Checked at RUNBOOK.md Step 9 after a completed engineering objective.

---

## Termination Conditions

An execution terminates after completing one engineering objective if ANY of the following are true:

| # | Condition | Action |
|---|-----------|--------|
| 1 | **Max iterations reached** â€” 2 internal iterations completed this execution | Exit normally. Cron triggers next cycle. |
| 2 | **Total timeout reached** â€” 15 minutes wall clock exceeded | Save progress, update docs, exit. See EXECUTION_TIMEOUT.md. |
| 3 | **CONTROL_FLAGS changed** â€” state is no longer ENABLED (e.g., human set PAUSED or STOP_REQUESTED during execution) | Follow AUTONOMOUS_CONTROL.md for new state. |
| 4 | **No more tasks** â€” TASK_QUEUE.md has no Not Started or In Progress items | Check if SUCCESS_CRITERIA.md is satisfied. If yes â†’ FINAL_SHUTDOWN.md. If no â†’ exit (waiting for human to add tasks). |
| 5 | **Recovery limit hit** â€” 3 consecutive failures on the same task | Set CONTROL_FLAGS.md to FAILED. Exit. |
| 6 | **Recovery limit hit** â€” 3 consecutive timeouts on the same task | Set CONTROL_FLAGS.md to FAILED. Exit. |

---

## Non-Termination (Continue) Conditions

An execution may proceed to another internal iteration if ALL of the following are true:

- [ ] Fewer than 2 internal iterations completed this execution
- [ ] Total wall clock < 15 minutes
- [ ] CONTROL_FLAGS.md is ENABLED
- [ ] Previous objective passed Quality Gate
- [ ] Next task is clear (NEXT_TASK.md is valid)
- [ ] Next task is estimated to complete within remaining time budget
- [ ] No human input required for next task
- [ ] Previous objective produced meaningful output (not just fixes)

If ALL conditions are met â†’ return to RUNBOOK.md Step 3 (Planning).
If ANY condition is not met â†’ exit.

---

## Normal Exit

When terminating normally (not due to failure or timeout):

1. Run `agent/CHECKLIST.md` â€” verify all pre-finish items
2. Git commit if changes were made and build passes
3. Remove `agent/LOCK`
4. Exit

The next cron trigger (in ~15 minutes) will start a fresh execution.

---

## Emergency Exit

When terminating due to failure, timeout, or CONTROL_FLAGS change:

1. Update `PROJECT_STATUS.md` with current state and reason for exit
2. Update `WORKLOG.md` with exit reason
3. Do NOT commit if build is broken
4. Remove `agent/LOCK`
5. Exit

---

## Rule

**Every exit removes the LOCK file.** No exceptions. If the process is killed before reaching the exit, the LOCK remains and the next run detects it as stale (after 30 minutes) and recovers.