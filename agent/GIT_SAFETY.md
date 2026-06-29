# Git Safety â€” {{PROJECT_NAME}} Autonomous System

> **Every autonomous execution MUST create a git checkpoint before making changes.** This document defines the rollback system that guarantees all autonomous changes are reversible.

---

## Core Principle

**Stability > Progress.** The system prefers fixing broken areas, stabilizing modified modules, and reducing risk over adding new features or expanding scope.

---

## Checkpoint Requirements

Every autonomous execution MUST:

1. **Create a git checkpoint BEFORE making any changes** â€” a baseline commit that represents the last known-good state
2. **Ensure ability to rollback in one command** â€” `git reset --hard <checkpoint>` must restore the pre-execution state
3. **Tag or mark safe state for recovery** â€” the checkpoint commit hash is recorded in WORKLOG.md
4. **Never proceed without a valid baseline commit** â€” if the repo has no commits, create one before any work begins

---

## Checkpoint Creation

Before any code changes (EXECUTION_CYCLE.md Phase 0):

1. Run `git status` â€” verify working directory state
2. If working directory is dirty (uncommitted changes from previous run or human):
   - `git stash` with message `agent: stash before checkpoint`
   - Log in WORKLOG: "Stashed uncommitted changes before checkpoint"
3. Create checkpoint commit: `git commit --allow-empty -m "agent checkpoint: <timestamp> - <objective>"`
4. Record checkpoint hash: `git rev-parse HEAD`
5. Write checkpoint hash to `agent/CHECKPOINT` file:
   ```
   checkpoint: <hash>
   timestamp: <ISO-8601>
   objective: <task name from NEXT_TASK.md>
   ```
6. Verify checkpoint: `git log --oneline -3` â€” confirm checkpoint is the latest commit

**The checkpoint is the baseline.** All autonomous changes in this run are made on top of the checkpoint. If anything fails, rollback restores this exact state.

---

## Rollback Strategy

If ANY of the following occur during execution:

| Trigger | Detection |
|---------|-----------|
| Build failure | `npm run build` exits non-zero after 3 fix attempts |
| Test failure | `npm test` exits non-zero after 3 fix attempts |
| Broken typecheck | `npx tsc --noEmit` exits non-zero after 3 fix attempts |
| Critical runtime error introduced | Code causes crash that didn't exist before this run |

Then execute **immediate rollback**:

1. **Revert to last safe checkpoint**: `git reset --hard <checkpoint-hash>` (read from `agent/CHECKPOINT`)
2. **Log failure in WORKLOG.md**: append entry with:
   - Timestamp
   - What triggered the rollback
   - What changes were lost (files modified/created)
   - Checkpoint hash rolled back to
3. **Create entry in TECH_DEBT.md**: document the root cause of the failure:
   - What was the task
   - What went wrong
   - Root cause (not symptom)
   - Suggested approach for next attempt
4. **Record incident in DECISIONS.md**: append entry with:
   - Date
   - Decision: "Rolled back to checkpoint <hash> due to <failure type>"
   - Reasoning: what happened, why rollback was necessary
   - Impact: what work was lost, what needs to be redone
5. **Remove `agent/LOCK`** and exit â€” next run will re-attempt with a fresh approach informed by the TECH_DEBT and DECISIONS entries

---

## Checkpoint Lifecycle

```
START
  â”‚
  â–¼
Read CHECKPOINT file (if exists)
  â”‚
  â”œâ”€ No previous checkpoint â†’ create initial checkpoint
  â”‚
  â–¼
Create new checkpoint commit
  â”‚
  â”œâ”€ git stash (if dirty)
  â”œâ”€ git commit --allow-empty -m "agent checkpoint: ..."
  â”œâ”€ Write hash to agent/CHECKPOINT
  â”‚
  â–¼
Execute task (Design â†’ Implement â†’ Refactor)
  â”‚
  â”œâ”€ All validations pass â†’ keep changes, commit, continue
  â”‚
  â”œâ”€ Validation fails after 3 attempts â†’ ROLLBACK
  â”‚   â”œâ”€ git reset --hard <checkpoint>
  â”‚   â”œâ”€ Log in WORKLOG.md
  â”‚   â”œâ”€ Create TECH_DEBT.md entry
  â”‚   â”œâ”€ Create DECISIONS.md entry
  â”‚   â””â”€ Exit
  â”‚
  â–¼
SUCCESS â€” checkpoint served its purpose
  (checkpoint commit remains in history as a marker)
```

---

## Safety Guarantees

| Guarantee | How |
|-----------|-----|
| Every change is reversible | Checkpoint created before any modification |
| No irreversible state without checkpoint | Execution cannot proceed without a valid checkpoint |
| Rollback is always one command | `git reset --hard <hash>` from CHECKPOINT file |
| Failed changes are never committed | Build/test failures trigger rollback before commit |
| Checkpoint hash is always recorded | Written to `agent/CHECKPOINT` and WORKLOG.md |
| Stashed changes are preserved | `git stash` before checkpoint, can be restored by human |

---

## Interaction with Other Systems

| System | Interaction |
|--------|-------------|
| `EXECUTION_CYCLE.md` | Phase 0 (new) creates checkpoint before Phase 1-20 |
| `FAILURE_RECOVERY.md` | Rollback is PRIMARY recovery mechanism for build/test/typecheck failures |
| `PLANNING_ENGINE.md` | Diff-based planning analyzes changes since last checkpoint |
| `WORKLOG.md` | Every checkpoint and rollback is logged |
| `TECH_DEBT.md` | Every rollback creates a root-cause entry |
| `DECISIONS.md` | Every rollback creates an incident entry |
| `RUNBOOK.md` | Pre-flight checks verify `agent/CHECKPOINT` file from previous run |

---

## Checkpoint File Format

`agent/CHECKPOINT` (created/updated every run):

```
checkpoint: <git-commit-hash>
timestamp: <ISO-8601>
objective: <task name from NEXT_TASK.md>
previous: <previous checkpoint hash or "none">
```

This file is NOT committed to git (add to `.gitignore`). It is a runtime artifact for the current execution only.

---

## Global Principle

**Stability > Progress.**

The autonomous system must prefer:

| Prefer | Over |
|--------|------|
| Fixing broken areas | Adding new features |
| Stabilizing modified modules | Expanding scope |
| Reducing risk | Increasing velocity |
| Completing partially modified areas | Starting new ones |
| Reverting to known-good state | Debugging in unknown state |

This principle is enforced through:
- Mandatory checkpoints before every execution
- Automatic rollback on validation failures
- Diff-based planning that prioritizes unstable areas
- TECH_DEBT tracking for every rollback incident