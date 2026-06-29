# Task Size Policy â€” {{PROJECT_NAME}}

> **Strict limits for autonomous work.** These rules prevent the autonomous engineer from overreaching in a single execution, which leads to half-finished work and unstable states.

---

## Core Rules

### Rule 1: One Task Per Execution
Never implement multiple unrelated features in one execution. Each run targets exactly one task from NEXT_TASK.md. If the task is small and another can fit, the internal cycle decision (EXECUTION_CYCLE.md Phase 19) handles that â€” don't preemptively batch.

### Rule 2: Complete Over Partial
Prefer one complete task over several partial tasks. A finished task with tests and documentation is worth more than three half-done tasks with no tests and stale docs.

### Rule 3: Split Large Tasks
If a task requires changes across many modules, split it into smaller subtasks. A task is too large if:
- It modifies more than **8 files**
- It creates more than **5 new files**
- It touches more than **3 unrelated subsystems** (e.g., types + API + UI + tests + docs)
- It cannot be completed in one execution cycle

When a task is too large, split it:
1. Write the subtasks to TODO.md with explicit ordering
2. Update NEXT_TASK.md with the first subtask
3. Document the split in DECISIONS.md
4. Execute the first subtask only

### Rule 4: Minimize Modified Files
Minimize the number of modified files whenever possible. Fewer changes means:
- Smaller blast radius if something breaks
- Easier code review
- Cleaner git history
- Lower chance of merge conflicts

### Rule 5: One Coherent Objective
Stop after completing one coherent engineering objective. A coherent objective is a single deliverable that can be described in one sentence:
- âœ… "Set up the project scaffold with Vite, Tailwind, and Zustand"
- âœ… "Implement the OpenAI API client with retry logic"
- âŒ "Implement API clients AND start the {{COMPONENT_NAME}} engine"
- âŒ "Fix the build AND refactor the state management AND add tests"

### Rule 6: Re-Plan Before Starting Another Task
After completing a task, if the internal cycle decision (Phase 19) allows another run, re-plan from scratch:
1. Return to Phase 1 (Load Context)
2. Re-read PROJECT_STATUS.md, NEXT_TASK.md, WORKLOG.md
3. Verify the previous task actually passed the Quality Gate
4. Select the next task via the Planning Engine
5. Only then begin implementation

Never carry assumptions from one task into the next. Context is reloaded fresh.

---

## Task Size Estimation

Before starting a task, estimate its size:

| Size | Files Modified | New Files | Subsystems | Typical Duration |
|------|---------------|-----------|------------|-----------------|
| **XS** | 1-2 | 0-1 | 1 | < 15 min |
| **S** | 2-4 | 1-2 | 1-2 | 15-30 min |
| **M** | 4-6 | 2-3 | 2 | 30-60 min |
| **L** | 6-8 | 3-5 | 2-3 | 60-90 min |
| **XL** | > 8 | > 5 | > 3 | SPLIT REQUIRED |

**XL tasks must always be split.** No exceptions.

**L tasks should be split if possible.** Split unless the changes are tightly coupled (e.g., a single component with its types, tests, and story).

**M tasks are the sweet spot.** Most execution cycles should target M-sized tasks.

---

## Anti-Patterns

### âŒ Kitchen Sink
Implementing API clients, prompt construction, AND the {{COMPONENT_NAME}} engine in one run because "they're all Phase 1."

**Why it's wrong**: Three unrelated subsystems, 15+ files, no coherent objective. If any part fails, the entire run is wasted.

### âŒ Scope Creep
Starting with "implement types" and then "while I'm here, let me also start the API client since the types are right there."

**Why it's wrong**: The task was types. API client is a separate task with its own dependencies and tests. Mixing them creates an unreviewable commit.

### âŒ Half-Finished Multi-Task
Implementing types (done), API client (done), {{COMPONENT_NAME}} engine (half done), and UI (started) â€” then running out of time.

**Why it's wrong**: Two tasks done, two half-done. The half-done work is untested, undocumented, and blocks the next run.

### âŒ Refactor Everything
"While implementing this feature, I noticed the existing code could be cleaner, so I refactored 5 unrelated files."

**Why it's wrong**: The commit mixes a feature with a refactor. If the feature has a bug, the refactor makes it hard to isolate. Refactors are separate tasks.

---

## Summary

```
One task. One objective. One coherent commit.
If it's too big, split it.
If it's not done, it's not done.
Never start another task without re-planning.
```