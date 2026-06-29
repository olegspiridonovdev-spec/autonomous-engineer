# Autonomous Engineer â€” {{PROJECT_NAME}}

> **Main entry point for every autonomous execution.** This document orchestrates the autonomous development system. It references other files instead of duplicating their contents.

---

## Authority

**`agent/SYSTEM.md` is the highest authority in this system.** It defines immutable constraints that can never be modified, bypassed, or overridden.

This document (`AUTONOMOUS_ENGINEER.md`) defines **workflow strategy only** â€” how the autonomous engineer operates within the constraints set by SYSTEM.md.

**Hierarchy**: SYSTEM.md (immutable) â†’ AUTONOMOUS_ENGINEER.md (orchestrator) â†’ all other agent modules (subordinate).

If any document in the system contradicts SYSTEM.md, SYSTEM.md wins. Contradictions must be logged in `DECISIONS.md` for human review.

---

## Mission

Autonomously move the {{PROJECT_NAME}} project toward production readiness while preserving quality and architecture.

Every execution makes measurable progress: one task implemented, tested, documented, and committed. No execution leaves the project in a worse state than it found it.

---

## Startup Procedure

**Step 0: Check control flags.** Read `agent/CONTROL_FLAGS.md` before any other file. If the state is not `ENABLED`, follow `agent/AUTONOMOUS_CONTROL.md` for the current state and do not proceed with normal execution.

**Step 1: Read SYSTEM.md.** Acknowledge immutable constraints. The autonomous engineer must never modify this file.

**Step 2: Read all documents in this exact order:**

| # | Document | Why |
|---|----------|-----|
| 0 | `agent/CONTROL_FLAGS.md` | Execution state â€” must be ENABLED to proceed |
| 1 | `agent/SYSTEM.md` | Immutable foundational rules â€” highest authority |
| 2 | `docs/ARCHITECTURE.md` | Source of truth for system design |
| 3 | `docs/prompts/*` | project-specific prompts and documentation |
| 4 | `docs/SCIENTIFIC_FOUNDATION.md` | Scoring rubrics |
| 5 | `TODO.md` | Implementation checklist by phase |
| 6 | `docs/PLAN.md` | Phased plan, timeline |
| 7 | `agent/PROJECT_STATUS.md` | Current project state |
| 8 | `agent/NEXT_TASK.md` | Pre-selected task |
| 9 | `agent/TASK_QUEUE.md` | Full prioritized task list |
| 10 | `agent/BLOCKERS.md` | Active blockers |
| 11 | `agent/TECH_DEBT.md` | Technical debt items |
| 12 | `agent/RISK_REGISTER.md` | Project risks |
| 13 | `agent/DECISIONS.md` | Architecture decision log |
| 14 | `agent/WORKLOG.md` | Recent work history |
| 15 | `agent/PLANNING_ENGINE.md` | Planning algorithm |
| 16 | `agent/DIFF_PLANNING.md` | Diff-based planning strategy |
| 17 | `agent/EXECUTION_CYCLE.md` | 21-phase execution lifecycle (Phase 0-20) |
| 18 | `agent/EXECUTION_RULES.md` | Permanent engineering rules |
| 19 | `agent/TASK_SIZE_POLICY.md` | Task size limits |
| 20 | `agent/QUALITY_GATE.md` | Definition of Done |
| 21 | `agent/REVIEW_CHECKLIST.md` | Code review checklist |
| 22 | `agent/SELF_REVIEW.md` | Retrospective questions |
| 23 | `agent/CHECKLIST.md` | Pre-finish checklist |
| 24 | `agent/FAILURE_RECOVERY.md` | Failure protocols (rollback is primary) |
| 25 | `agent/GIT_SAFETY.md` | Git checkpoint and rollback system |
| 26 | `agent/AUTONOMOUS_CONTROL.md` | State management protocol |
| 27 | `agent/EXECUTION_TIMEOUT.md` | Timeout policy |
| 28 | `agent/RUNBOOK.md` | Runtime execution sequence |
| 29 | `agent/TERMINATION_POLICY.md` | When to stop |
| 30 | `agent/SUCCESS_CRITERIA.md` | Project completion criteria |
| 31 | `agent/CRON_SETUP.md` | Scheduling configuration |

After reading all documents, proceed to Planning.

---

## Execution Model

Every execution consists of **repeated internal iterations**. Each iteration:

1. Completes exactly **ONE coherent engineering objective** (per `TASK_SIZE_POLICY.md`)
2. Follows the **20-phase lifecycle** defined in `EXECUTION_CYCLE.md`
3. Must satisfy **all conditions** in `QUALITY_GATE.md` before the objective is considered done
4. Is reviewed via `SELF_REVIEW.md` and `REVIEW_CHECKLIST.md`

**Never begin another objective until the current one satisfies QUALITY_GATE.md.**

Per `SYSTEM.md`: each cycle must end in a valid system state. No partial or untracked work is allowed.

After a completed objective, the internal cycle decision (`EXECUTION_CYCLE.md` Phase 19) determines whether another iteration runs. Max 2 iterations per execution (per `EXECUTION_TIMEOUT.md`). Before each new iteration, re-check `CONTROL_FLAGS.md`.

---

## Planning

Planning decisions are delegated to:

â†’ **`agent/PLANNING_ENGINE.md`**

---

## Execution

The execution lifecycle is delegated to:

â†’ **`agent/EXECUTION_CYCLE.md`**

---

## Engineering Rules

Permanent engineering standards are delegated to:

â†’ **`agent/EXECUTION_RULES.md`**

These rules are subordinate to `SYSTEM.md` core principles.

---

## Quality

Completion requirements are delegated to:

â†’ **`agent/QUALITY_GATE.md`**

â†’ **`agent/SELF_REVIEW.md`**

â†’ **`agent/REVIEW_CHECKLIST.md`**

Per `SYSTEM.md`: no bypassing of QUALITY_GATE, no skipping of SELF_REVIEW.

---

## Recovery

Failure handling is delegated to:

â†’ **`agent/FAILURE_RECOVERY.md`**

Per `SYSTEM.md`: no ignoring failures. Every failure is logged and either fixed or escalated.

---

## Completion

Before terminating execution â€” **always**, regardless of success or failure:

| # | Action | File |
|---|--------|------|
| 1 | Update project status | `agent/PROJECT_STATUS.md` |
| 2 | Write next task | `agent/NEXT_TASK.md` |
| 3 | Synchronize checklist | `TODO.md` |
| 4 | Append work journal | `agent/WORKLOG.md` |
| 5 | Regenerate task list | `agent/TASK_QUEUE.md` |
| 6 | Update technical debt | `agent/TECH_DEBT.md` (if debt was created or resolved) |
| 7 | Log architecture decisions | `agent/DECISIONS.md` (if decisions were made) |

Run the pre-finish checklist: â†’ **`agent/CHECKLIST.md`**

Commit changes (only if build passes):
```bash
git add -A && git commit -m "[autonomous] [task name] â€” [result]"
```

---

## Orchestration Flow

```
START
  â”‚
  â–¼
Check CONTROL_FLAGS.md
  â”‚
  â”œâ”€ not ENABLED â†’ follow AUTONOMOUS_CONTROL.md â†’ terminate
  â”‚
  â–¼ ENABLED
Read SYSTEM.md (acknowledge immutable constraints)
  â”‚
  â–¼
Read all 32 documents (Startup Procedure)
  â”‚
  â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ GIT CHECKPOINT (Phase 0)        â”‚
â”‚ Create baseline commit          â”‚
â”‚ Verify build passes             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ PLANNING ENGINE                 â”‚
â”‚ Evaluate repo â†’ Diff analysis   â”‚
â”‚ Discover tasks â†’ Classify       â”‚
â”‚ Prioritize â†’ Select             â”‚
â”‚ Write NEXT_TASK.md              â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ EXECUTION CYCLE (Phase 0-20)    â”‚
â”‚ Checkpoint â†’ Design â†’ Implement â”‚
â”‚ Refactor â†’ Build â†’ Lint         â”‚
â”‚ Typecheck â†’ Tests â†’ Fix â†’ Tests â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ SELF_REVIEW (10 questions)      â”‚
â”‚ REVIEW_CHECKLIST (14 categories)â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ QUALITY GATE (16 conditions)    â”‚
â”‚ All pass?                       â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚               â”‚
       Yes              No
        â”‚               â”‚
        â”‚               â–¼
        â”‚         FAILURE RECOVERY
        â”‚         Rollback if unfixable
        â”‚         Fix if simple error
        â”‚               â”‚
        â”‚               â–¼
        â”‚         Quality Gate again
        â”‚         (max 3 rounds)
        â”‚
        â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ COMPLETION                      â”‚
â”‚ Update 7 agent files            â”‚
â”‚ Run CHECKLIST.md                â”‚
â”‚ Git commit                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Re-check CONTROL_FLAGS.md       â”‚
â”‚ Another iteration?              â”‚
â”‚ (per EXECUTION_CYCLE Phase 19)  â”‚
â”‚ Max 2 iterations per execution  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚               â”‚
       Yes              No
        â”‚               â”‚
        â–¼               â–¼
   Back to START    FINISH
```

---

## Quick Reference: Document Responsibilities

| Concern | Document |
|---------|----------|
| Immutable foundational rules | `SYSTEM.md` |
| Execution state control | `CONTROL_FLAGS.md` â†’ `AUTONOMOUS_CONTROL.md` |
| Git checkpoint and rollback | `GIT_SAFETY.md` â†’ `CHECKPOINT_MANAGER.sh` |
| Diff-based planning | `DIFF_PLANNING.md` |
| What to work on next | `PLANNING_ENGINE.md` â†’ `DIFF_PLANNING.md` |
| How to execute a task | `EXECUTION_CYCLE.md` (Phase 0-20) |
| What rules to follow | `EXECUTION_RULES.md` |
| When a task is done | `QUALITY_GATE.md` |
| How to review code | `REVIEW_CHECKLIST.md` |
| How to self-review | `SELF_REVIEW.md` |
| How to handle failures | `FAILURE_RECOVERY.md` (rollback is primary) |
| How large a task can be | `TASK_SIZE_POLICY.md` |
| Timeout limits | `EXECUTION_TIMEOUT.md` |
| What to check before finishing | `CHECKLIST.md` |
| When to stop a run | `TERMINATION_POLICY.md` |
| How to shut down permanently | `FINAL_SHUTDOWN.md` |
| When the project is done | `SUCCESS_CRITERIA.md` |
| How to schedule runs | `CRON_SETUP.md` |
| How to execute a run | `RUNBOOK.md` |
| What tasks exist | `TASK_QUEUE.md` |
| What's blocking progress | `BLOCKERS.md` |
| What debt exists | `TECH_DEBT.md` |
| What risks exist | `RISK_REGISTER.md` |
| What was decided | `DECISIONS.md` |
| What happened | `WORKLOG.md` |
| What's the project state | `PROJECT_STATUS.md` |
| What's the next task | `NEXT_TASK.md` |
| What's the architecture | `docs/ARCHITECTURE.md` |
| What's the plan | `docs/PLAN.md` |
| What are the prompts | `docs/prompts/*` |
| What's the science | `docs/SCIENTIFIC_FOUNDATION.md` |
| What's the checklist | `TODO.md` |