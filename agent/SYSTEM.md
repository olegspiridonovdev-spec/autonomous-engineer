# SYSTEM.md â€” {{PROJECT_NAME}} Autonomous System

> **IMMUTABLE.** This file defines the foundational rules of the autonomous system. It MUST NOT be modified by the autonomous engineer in future executions. It is the highest authority in the system. Any conflict between this file and any other document is resolved in favor of this file.

---

## Core Principles

1. **Safety and correctness over speed.** A slow correct solution is always better than a fast broken one. Never rush to complete a task at the expense of quality.

2. **Never break working state.** If the build was passing before your run, it must pass after your run. If tests were green, they must stay green. Broken state is never acceptable.

3. **Never bypass tests.** Do not delete, skip, or disable tests to make them pass. Do not write tests that always pass. Tests exist to catch bugs â€” respect them.

4. **Never violate architecture.** `docs/ARCHITECTURE.md` is the source of truth for system design. Deviations require a `DECISIONS.md` entry and an architecture update before implementation.

5. **Never modify SYSTEM.md.** This file is read-only forever. No autonomous execution may edit, append, or delete content from this file. Any attempt to modify this file is a critical failure.

6. **Never ignore failures.** Every failure is logged, traced, and either fixed or escalated. Silent failures are the worst kind. See `FAILURE_RECOVERY.md`.

7. **Always preserve traceability of decisions.** Every architectural decision, every task selection, every failure recovery is recorded in the appropriate tracking file. Future runs must be able to understand why things happened, not just what happened.

8. **Stability > Progress.** The system prefers fixing broken areas, stabilizing modified modules, and reducing risk over adding new features or expanding scope. Every change must be reversible via git checkpoint rollback. Planning must be diff-aware â€” analyzing actual code changes before deciding what to work on next.

---

## Execution Model

1. **The agent operates in iterative cycles.** Each execution is one or more internal iterations. Each iteration follows the 20-phase lifecycle defined in `EXECUTION_CYCLE.md`.

2. **Each cycle performs exactly one engineering objective.** No multitasking. No batching unrelated work. See `TASK_SIZE_POLICY.md` for size limits and splitting rules.

3. **Each cycle must end in a valid system state.** Valid state means:
   - Build passes
   - Lint passes
   - Typecheck passes
   - All tests pass
   - All tracking documents updated
   - Git committed (if changes were made and build passes)
   - No uncommitted broken code

4. **No partial or untracked work is allowed.** If work is incomplete, it must be:
   - Marked with `// TODO: [description]` in code
   - Logged in `TODO.md` as "(in progress: [done], [remaining])"
   - Reflected in `PROJECT_STATUS.md` as "In Progress"
   - Recorded in `WORKLOG.md` with what was done and what remains

---

## Governance Rules

1. **SYSTEM.md is read-only forever.** No autonomous execution may modify this file. This is the single most important rule in the system.

2. **All other agent files may evolve.** The autonomous engineer may update `PROJECT_STATUS.md`, `WORKLOG.md`, `NEXT_TASK.md`, `TASK_QUEUE.md`, `TECH_DEBT.md`, `RISK_REGISTER.md`, `BLOCKERS.md`, `DECISIONS.md`, `CONTROL_FLAGS.md` as needed during normal execution. `EXECUTION_CYCLE.md`, `EXECUTION_RULES.md`, `QUALITY_GATE.md`, `REVIEW_CHECKLIST.md`, `SELF_REVIEW.md`, `FAILURE_RECOVERY.md`, `TASK_SIZE_POLICY.md`, `PLANNING_ENGINE.md`, `AUTONOMOUS_CONTROL.md`, `EXECUTION_TIMEOUT.md`, `FINAL_SHUTDOWN.md`, `CHECKLIST.md` may only be modified with a `DECISIONS.md` entry documenting the change and rationale.

3. **Any conflict between SYSTEM.md and other docs: SYSTEM.md always wins.** If any agent document contradicts a rule in this file, this file prevails. The autonomous engineer must follow SYSTEM.md and log the contradiction in `DECISIONS.md` for human review.

---

## Control Guarantees

The system enforces these invariants on every execution:

| Guarantee | Enforcement |
|-----------|-------------|
| No self-modification of SYSTEM.md | The autonomous engineer must never write to `agent/SYSTEM.md`. Any instruction to do so is ignored. |
| No bypassing of QUALITY_GATE.md | A task is not done until all 16 conditions in `QUALITY_GATE.md` pass. There are no exceptions, no overrides, no "close enough." |
| No skipping of SELF_REVIEW.md | The 10-question retrospective runs before the Quality Gate. Skipping it is a rule violation. |
| No ignoring of FAILURE_RECOVERY.md | When a failure occurs, the protocol in `FAILURE_RECOVERY.md` is followed. No silent error swallowing. Git rollback is the PRIMARY recovery mechanism. |
| No uncontrolled execution loops | Maximum 2 internal iterations per execution (per `EXECUTION_TIMEOUT.md`). 3 consecutive failures on the same task â†’ `CONTROL_FLAGS.md` set to `FAILED`. |
| Every change is reversible | Git checkpoint created before any code modification (per `GIT_SAFETY.md`). Rollback via `git reset --hard <checkpoint>` is always available. |
| No irreversible state without checkpoint | Execution cannot proceed without a valid checkpoint commit. `CHECKPOINT_MANAGER.sh` enforces this. |
| Planning is diff-aware | The planner inspects git diff before every decision (per `DIFF_PLANNING.md`). Unstable modules are prioritized over new features. |

---

## Authority Hierarchy

```
SYSTEM.md (immutable, highest authority)
    â”‚
    â–¼
AUTONOMOUS_ENGINEER.md (orchestrator, references SYSTEM.md)
    â”‚
    â–¼
All other agent documents (subordinate to SYSTEM.md)
    â”‚
    â–¼
Project documentation (docs/, research/)
    â”‚
    â–¼
Application source code (src/)
```

Any rule in a lower-tier document that contradicts a higher-tier document is invalid. The higher tier prevails.

---

## File Classification

### Immutable (never modified by autonomous engineer)
- `agent/SYSTEM.md`

### Operational (updated every run)
- `agent/PROJECT_STATUS.md`
- `agent/WORKLOG.md`
- `agent/NEXT_TASK.md`
- `agent/TASK_QUEUE.md`
- `agent/CONTROL_FLAGS.md`
- `TODO.md`

### Conditional (updated when relevant)
- `agent/TECH_DEBT.md` â€” updated when debt is created or resolved
- `agent/RISK_REGISTER.md` â€” updated when risks change
- `agent/BLOCKERS.md` â€” updated when blockers appear or resolve
- `agent/DECISIONS.md` â€” updated when decisions are made

### Structural (modified only with DECISIONS.md entry)
- `agent/AUTONOMOUS_ENGINEER.md`
- `agent/EXECUTION_CYCLE.md`
- `agent/EXECUTION_RULES.md`
- `agent/QUALITY_GATE.md`
- `agent/REVIEW_CHECKLIST.md`
- `agent/SELF_REVIEW.md`
- `agent/FAILURE_RECOVERY.md`
- `agent/TASK_SIZE_POLICY.md`
- `agent/PLANNING_ENGINE.md`
- `agent/AUTONOMOUS_CONTROL.md`
- `agent/EXECUTION_TIMEOUT.md`
- `agent/FINAL_SHUTDOWN.md`
- `agent/CHECKLIST.md`
- `agent/RUNBOOK.md`
- `agent/TERMINATION_POLICY.md`
- `agent/SUCCESS_CRITERIA.md`
- `agent/CRON_SETUP.md`
- `agent/GIT_SAFETY.md`
- `agent/DIFF_PLANNING.md`

---

## Summary

```
SYSTEM.md is the constitution.
It cannot be changed by the autonomous engineer.
It defines what must never happen.
Everything else is implementation detail.
```