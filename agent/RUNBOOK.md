# RUNBOOK â€” {{PROJECT_NAME}} Autonomous Runtime

> **Single source of truth for runtime execution.** Every autonomous execution starts here. This document defines the exact sequence of operations for one autonomous run.

---

## Entrypoint Rule

Every autonomous execution starts from `RUNBOOK.md`. No exceptions.

The runbook MUST:
1. Verify `CONTROL_FLAGS.md`
2. Verify `SYSTEM.md` exists and is readable
3. Load `AUTONOMOUS_ENGINEER.md`
4. Load `PLANNING_ENGINE.md`
5. Load `EXECUTION_CYCLE.md`
6. Load `QUALITY_GATE.md`
7. Load all tracking files (PROJECT_STATUS, NEXT_TASK, TASK_QUEUE, BLOCKERS, TECH_DEBT, RISK_REGISTER, DECISIONS, WORKLOG, TODO)

---

## Pre-Flight Checks

Before any work begins, the runtime performs these checks in order:

| # | Check | Action on failure |
|---|-------|-------------------|
| 1 | Verify `agent/CONTROL_FLAGS.md` exists | Abort, log error |
| 2 | Read `CONTROL_FLAGS.md` state | If not ENABLED â†’ Step 2 (exit) |
| 3 | Verify `agent/SYSTEM.md` exists | Abort, log error |
| 4 | Verify `agent/LOCK` does not exist (or is stale) | If LOCK exists and fresh â†’ exit (another run active). If stale â†’ remove LOCK, log recovery, continue |
| 5 | Create `agent/LOCK` with timestamp | If cannot create â†’ abort |
| 6 | Verify git repo is clean (`git status`) | If dirty â†’ log warning, continue (autonomous changes may be uncommitted from previous run) |
| 7 | Load environment variables | If API keys missing â†’ log warning, continue (task may not need them) |
| 8 | Create git checkpoint | Run `bash agent/CHECKPOINT_MANAGER.sh "<objective>"` â€” creates baseline commit. If fails â†’ abort. Write hash to `agent/CHECKPOINT`. |

---

## Execution Flow

### Step 1: Load System State

Read all documents per `AUTONOMOUS_ENGINEER.md` Startup Procedure:
- `CONTROL_FLAGS.md` (already checked in pre-flight)
- `SYSTEM.md` (already verified in pre-flight)
- `docs/ARCHITECTURE.md`
- `docs/prompts/*`
- `docs/SCIENTIFIC_FOUNDATION.md`
- `TODO.md`
- `docs/PLAN.md`
- `agent/PROJECT_STATUS.md`
- `agent/NEXT_TASK.md`
- `agent/TASK_QUEUE.md`
- `agent/BLOCKERS.md`
- `agent/TECH_DEBT.md`
- `agent/RISK_REGISTER.md`
- `agent/DECISIONS.md`
- `agent/WORKLOG.md`
- `agent/PLANNING_ENGINE.md`
- `agent/EXECUTION_CYCLE.md`
- `agent/EXECUTION_RULES.md`
- `agent/TASK_SIZE_POLICY.md`
- `agent/QUALITY_GATE.md`
- `agent/REVIEW_CHECKLIST.md`
- `agent/SELF_REVIEW.md`
- `agent/CHECKLIST.md`
- `agent/FAILURE_RECOVERY.md`
- `agent/AUTONOMOUS_CONTROL.md`
- `agent/EXECUTION_TIMEOUT.md`

### Step 2: Check Control Flags

Read `CONTROL_FLAGS.md`:
- **ENABLED** â†’ proceed to Step 3
- **PAUSED** â†’ log "Execution skipped â€” PAUSED" in WORKLOG, remove LOCK, exit
- **STOP_REQUESTED** â†’ log "Execution skipped â€” STOP_REQUESTED" in WORKLOG, remove LOCK, exit (if no objective in progress)
- **PROJECT_COMPLETED** â†’ log "Execution skipped â€” PROJECT_COMPLETED" in WORKLOG, remove LOCK, exit
- **FAILED** â†’ log "Execution skipped â€” FAILED, human review required" in WORKLOG, remove LOCK, exit

### Step 3: Planning Engine Cycle

Execute `PLANNING_ENGINE.md`:
1. Evaluate repository (git status, file tree, package.json, build/test/lint state)
2. Discover tasks (documented in TODO.md + discovered via code scan)
3. Classify tasks (priority Ã— state)
4. Apply resolution rules
5. Select one task

### Step 4: Select Next Task

- If `NEXT_TASK.md` is valid (matches planner selection) â†’ reuse it
- If `NEXT_TASK.md` is stale (planner selected different task) â†’ overwrite NEXT_TASK.md with new selection, log reason in WORKLOG
- Write selected task to `NEXT_TASK.md`

### Step 5: Execute One Engineering Objective

Follow `EXECUTION_CYCLE.md` phases 0-7:
0. **Git Checkpoint** â€” baseline commit via CHECKPOINT_MANAGER.sh (already done in pre-flight)
1. **Design** â€” identify files to create/modify, check against ARCHITECTURE.md
2. **Implement** â€” write code per design
3. **Refactor** â€” review and improve before validation

Enforce `TASK_SIZE_POLICY.md`: if task exceeds size limits, split and execute only the first subtask.

Enforce `EXECUTION_TIMEOUT.md`: monitor elapsed time per phase.

### Step 6: Quality Validation

Run the validation pipeline:

| # | Validation | Command | Timeout |
|---|-----------|---------|---------|
| 1 | Build | `npm run build` | 60s |
| 2 | Lint | `npm run lint` | 30s |
| 3 | Typecheck | `npx tsc --noEmit` | 30s |
| 4 | Tests | `npm test` | 120s |

If any validation is not yet configured (no test runner, no lint script), skip and log in WORKLOG.

### Step 7: Failure Handling

If any validation fails:
1. Trigger `FAILURE_RECOVERY.md` for the specific failure type
2. **Git rollback is PRIMARY recovery** â€” if failure is unfixable after 3 attempts:
   - `git reset --hard <checkpoint>` (read from `agent/CHECKPOINT`)
   - Re-run `npm run build` to verify recovery
   - Create `TECH_DEBT.md` entry with root cause
   - Create `DECISIONS.md` entry with rollback incident
3. Log failure details in WORKLOG
4. Update `TASK_QUEUE.md` â€” task state = "In Progress"
5. Update `PROJECT_STATUS.md` â€” add to "Known Issues"
6. Remove `agent/LOCK`
7. Exit â€” next run will continue

Max 3 recovery rounds per execution. If still failing after 3 rounds:
1. Set `CONTROL_FLAGS.md` to `FAILED`
2. Log detailed failure summary in WORKLOG
3. Update `PROJECT_STATUS.md` with failure details
4. Remove `agent/LOCK`
5. Exit

### Step 8: Success Path

If all validations pass:

1. **Run `SELF_REVIEW.md`** â€” answer 10 retrospective questions
2. **Run `REVIEW_CHECKLIST.md`** â€” verify 14 categories
3. **Run `QUALITY_GATE.md`** â€” verify all 16 conditions

If Quality Gate fails â†’ return to Step 7 (treat as failure)

If Quality Gate passes:

4. **Update `PROJECT_STATUS.md`** â€” completion %, features, issues
5. **Update `WORKLOG.md`** â€” append entry with timestamp, objectives, tasks, bugs, tests, docs
6. **Update `NEXT_TASK.md`** â€” select and write next task
7. **Update `TASK_QUEUE.md`** â€” regenerate prioritized list
8. **Update `TODO.md`** â€” check off completed items
9. **Update `TECH_DEBT.md`** â€” if debt was created or resolved
10. **Update `DECISIONS.md`** â€” if architectural decisions were made

### Step 9: Termination Check

Read `agent/TERMINATION_POLICY.md`:
- If termination condition met â†’ gracefully exit (remove LOCK, commit, terminate)
- If not â†’ exit normally (cron will trigger next cycle)

Before exiting:
1. Run `agent/CHECKLIST.md` â€” verify all pre-finish items
2. Git commit (if changes and build passes): `git add -A && git commit -m "[autonomous] [task] â€” [result]"`
3. Remove `agent/LOCK`
4. Exit

---

## Lock Management

| When | Action |
|------|--------|
| Before pre-flight | Check if `agent/LOCK` exists |
| LOCK exists, age < 30 min | Exit â€” another run is active |
| LOCK exists, age â‰¥ 30 min | Stale lock â€” remove, log recovery in WORKLOG, continue |
| Pre-flight passed | Create `agent/LOCK` with current timestamp |
| Execution complete (success or failure) | Remove `agent/LOCK` |
| Crash (process killed) | LOCK remains â€” next run detects stale lock and recovers |

**LOCK file format:**
```
LOCKED
timestamp: YYYY-MM-DDTHH:MM:SSZ
pid: <process_id>
```

---

## Guarantees

| Guarantee | How |
|-----------|-----|
| No parallel execution | LOCK file â€” only one instance runs at a time |
| No overlapping runs | LOCK check at startup â€” fresh LOCK means exit |
| No uncontrolled loops | Max 2 internal iterations per execution (EXECUTION_TIMEOUT.md) |
| Deterministic single-step progression | One task per run, next task written to NEXT_TASK.md |
| Full traceability | WORKLOG.md append-only, DECISIONS.md for architecture, TECH_DEBT.md for debt |
| Safe crash recovery | Stale LOCK detection (30 min threshold) |
| Clean exit on failure | All tracking documents updated before removing LOCK |
| Every change is reversible | Git checkpoint before any modification (GIT_SAFETY.md) |
| No irreversible state without checkpoint | CHECKPOINT_MANAGER.sh enforces baseline commit |
| Planning is diff-aware | DIFF_PLANNING.md â€” planner analyzes git diff before task selection |
| Rollback is always available | `git reset --hard <checkpoint>` restores pre-execution state |