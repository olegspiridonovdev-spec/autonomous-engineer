# Autonomous Control â€” {{PROJECT_NAME}}

> **Defines how autonomous execution is enabled, paused, and stopped.** The autonomous engineer checks `CONTROL_FLAGS.md` before any work and follows this document when the state is not ENABLED.

---

## States

### ENABLED

The agent may execute normally. All 20 phases of the execution cycle run. Internal iterations may continue per Phase 19 of EXECUTION_CYCLE.md.

### PAUSED

The scheduler may still invoke the agent, but the agent must immediately terminate after updating its status.

**What happens when PAUSED:**
1. Read CONTROL_FLAGS.md at startup â€” state is PAUSED
2. Do not read any other documents
3. Do not execute any phases
4. Update PROJECT_STATUS.md: set status to "Paused â€” awaiting human action"
5. Append WORKLOG.md: "Execution skipped â€” system is PAUSED"
6. Terminate immediately

**How to resume:** Human changes CONTROL_FLAGS.md back to ENABLED.

### STOP_REQUESTED

Finish the current engineering objective. Do not begin another objective.

**What happens when STOP_REQUESTED is detected:**
1. If no objective is in progress: treat as PAUSED (update status, terminate)
2. If an objective is in progress:
   a. Continue execution through Phase 12 (Fix Failures)
   b. Skip Phase 13 (Add Missing Tests) â€” log as remaining work in WORKLOG
   c. Run Phases 14-18 (Update Documentation, TODO, Status, Next Task, Worklog)
   d. Skip Phase 19 (Decide Whether Another Internal Cycle Should Run) â€” do not start another cycle
   e. Run Phase 20 (Finish Execution)
   f. Update CONTROL_FLAGS.md to PAUSED
3. All tracking documents must reflect the completed objective and remaining work
4. Terminate gracefully

**How to resume:** Human changes CONTROL_FLAGS.md back to ENABLED.

### PROJECT_COMPLETED

The project satisfies SUCCESS_CRITERIA.md. No further autonomous development should occur.

**What happens when PROJECT_COMPLETED:**
1. Read CONTROL_FLAGS.md â€” state is PROJECT_COMPLETED
2. Do not execute any phases
3. Append WORKLOG.md: "Execution skipped â€” project is completed"
4. Terminate immediately

**How to resume:** Not applicable. Project is complete. If human wants further work, they must:
1. Update SUCCESS_CRITERIA.md with new requirements
2. Change CONTROL_FLAGS.md to ENABLED
3. Update TODO.md with new tasks

### FAILED

Autonomous execution is suspended because repeated failures exceeded recovery limits. Human review is required before execution may continue.

**What happens when FAILED:**
1. Read CONTROL_FLAGS.md â€” state is FAILED
2. Do not execute any phases
3. Read PROJECT_STATUS.md â€” check "Known Issues" for failure details
4. Append WORKLOG.md: "Execution skipped â€” system is FAILED, human review required"
5. Terminate immediately

**How to resume:** Human must:
1. Review WORKLOG.md and PROJECT_STATUS.md for failure details
2. Fix the underlying issue or approve a new approach
3. Update CONTROL_FLAGS.md to ENABLED
4. Optionally update BLOCKERS.md with the resolution

---

## State Transitions

```
                    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                    â”‚ ENABLED  â”‚â—„â”€â”€â”€â”€ human sets to ENABLED
                    â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜
                         â”‚
            â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
            â”‚            â”‚            â”‚
            â–¼            â–¼            â–¼
     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”
     â”‚  PAUSED  â”‚ â”‚STOP_REQ   â”‚ â”‚ FAILED  â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                        â”‚
                        â–¼
                 â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                 â”‚ finish currentâ”‚
                 â”‚ objective     â”‚
                 â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜
                        â”‚
                        â–¼
                 â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                 â”‚  PAUSED  â”‚
                 â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜

     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
     â”‚PROJECT_COMPLETEDâ”‚â”€â”€â”€â”€ FINAL_SHUTDOWN sequence
     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

**Who changes states:**
- **ENABLED â†’ PAUSED**: Human (pause work)
- **PAUSED â†’ ENABLED**: Human (resume work)
- **ENABLED â†’ STOP_REQUESTED**: Human (graceful stop)
- **STOP_REQUESTED â†’ PAUSED**: Autonomous engineer (after finishing current objective)
- **ENABLED â†’ FAILED**: Autonomous engineer (recovery limits exceeded)
- **FAILED â†’ ENABLED**: Human (after review and fix)
- **ENABLED â†’ PROJECT_COMPLETED**: Autonomous engineer (SUCCESS_CRITERIA.md satisfied)
- **PROJECT_COMPLETED â†’ ENABLED**: Human (new requirements added)

---

## Rules

1. **The autonomous engineer never sets ENABLED.** Only the human resumes execution.
2. **The autonomous engineer may set FAILED** when recovery limits are exceeded (per FAILURE_RECOVERY.md escalation criteria).
3. **The autonomous engineer may set PROJECT_COMPLETED** when SUCCESS_CRITERIA.md is fully satisfied.
4. **The autonomous engineer sets STOP_REQUESTED â†’ PAUSED** after finishing the current objective.
5. **State changes are logged in WORKLOG.md** with timestamp, old state, new state, and reason.
6. **CONTROL_FLAGS.md is checked at startup AND before each internal iteration** (EXECUTION_CYCLE.md Phase 19).