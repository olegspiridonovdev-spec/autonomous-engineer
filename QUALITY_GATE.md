# Quality Gate â€” {{PROJECT_NAME}}

> **Definition of Done.** A task is considered complete ONLY if ALL conditions below are true. If any condition fails, the task returns to "In Progress" and must be fixed before finishing the execution.

---

## Definition of Done

A task is **Done** when every one of these conditions is met:

### Code Conditions

| # | Condition | Verification Method |
|---|-----------|-------------------|
| 1 | Implementation finished â€” all planned changes are written | Manual inspection against task spec |
| 2 | Code compiles â€” no syntax errors | `npx tsc --noEmit` exits 0 |
| 3 | Build passes â€” production build succeeds | `npm run build` exits 0 |
| 4 | Typecheck passes â€” no type errors | `npx tsc --noEmit` exits 0 |
| 5 | Lint passes â€” no lint violations | `npm run lint` exits 0 |
| 6 | All existing tests pass â€” no regressions | `npm test` exits 0 |
| 7 | New tests added when appropriate â€” new functionality is tested | Review: does new code have tests? |
| 8 | No temporary code remains â€” no debug logs, commented-out code, or placeholders | `grep -rn "console.log\|debugger\|TODO_TEMP\|FIXME_TEMP" src/` returns nothing |
| 9 | No unfinished TODO or FIXME introduced â€” all new TODOs must be documented | Any new `// TODO` or `// FIXME` must have a TECH_DEBT.md entry |
| 10 | No architecture violations detected â€” implementation matches ARCHITECTURE.md | Manual review against ARCHITECTURE.md relevant sections |

### Documentation Conditions

| # | Condition | Verification Method |
|---|-----------|-------------------|
| 11 | Documentation updated â€” all affected docs reflect new code | Review: ARCHITECTURE.md, PLAN.md, README.md, docs/prompts/* as needed |
| 12 | TODO updated â€” completed items checked, partial items annotated | TODO.md reflects current state |
| 13 | PROJECT_STATUS updated â€” status, progress, issues reflect this run | PROJECT_STATUS.md is current |
| 14 | NEXT_TASK updated â€” next task selected and documented | NEXT_TASK.md has exactly one task |

### Process Conditions

| # | Condition | Verification Method |
|---|-----------|-------------------|
| 15 | WORKLOG appended â€” this run is documented | WORKLOG.md has new entry |
| 16 | Git committed â€” changes saved with descriptive message | `git log -1` shows this run's commit |

---

## Failure Protocol

If ANY condition fails:

1. **Task returns to "In Progress"** â€” do not mark as completed in TODO.md or PROJECT_STATUS.md
2. **Attempt to fix** â€” return to Phase 12 (Fix Failures) of the execution cycle
3. **Max 3 fix rounds** â€” if the condition still fails after 3 attempts, document the failure
4. **Log in WORKLOG** â€” record which conditions failed and why
5. **Update PROJECT_STATUS** â€” mark the task as "In Progress" with notes on what's blocking
6. **Finish execution** â€” do not proceed to the next task; the next run will continue

---

## Quality Gate Flow

```
Implementation complete
        â”‚
        â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Code conditions   â”‚â”€â”€failâ”€â”€â†’ Fix (max 3 rounds)â”€â”€â†’ Still failing? â”€â”€â†’ Document & finish
â”‚ (1-10)            â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚ pass
        â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Doc conditions    â”‚â”€â”€failâ”€â”€â†’ Fix immediatelyâ”€â”€â”€â”€â†’ Still failing? â”€â”€â†’ Document & finish
â”‚ (11-14)           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚ pass
        â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Process conditionsâ”‚â”€â”€failâ”€â”€â†’ Fix immediatelyâ”€â”€â”€â”€â†’ Still failing? â”€â”€â†’ Document & finish
â”‚ (15-16)           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â”‚ pass
        â–¼
   âœ… TASK DONE
   Mark completed in TODO.md
   Mark completed in PROJECT_STATUS.md
```

---

## Rule

**No task is "mostly done."** A task is done or it isn't. 90% done is not done. If any condition fails, the task is In Progress and the next run must finish it before starting new work.