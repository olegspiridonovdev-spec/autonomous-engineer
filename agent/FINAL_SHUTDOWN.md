# Final Shutdown â€” {{PROJECT_NAME}}

> **The final shutdown sequence after the project is complete.** Once SUCCESS_CRITERIA.md is satisfied, this procedure runs once to verify, document, and permanently stop autonomous development.

---

## Precondition

Final shutdown may only begin when ALL of these are true:

- [ ] `CONTROL_FLAGS.md` is `ENABLED`
- [ ] `SUCCESS_CRITERIA.md` is satisfied (all criteria checked)
- [ ] Build passes (`npm run build`)
- [ ] Lint passes (`npm run lint`)
- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] All tests pass (`npm test`)
- [ ] No active blockers in `BLOCKERS.md`
- [ ] No Critical or High severity items in `TECH_DEBT.md`

If any precondition fails, do not begin final shutdown. Continue normal execution to resolve the issue first.

---

## Shutdown Sequence

### Step 1: Verify SUCCESS_CRITERIA.md

1. Read `agent/SUCCESS_CRITERIA.md`
2. Verify every criterion is met
3. If any criterion is not met: do not proceed. Continue normal execution.
4. Record the verification result in WORKLOG.md

### Step 2: Run Full Validation Pipeline

Run the complete validation suite and record results:

```bash
npm run build       # Production build
npm run lint        # Code quality
npx tsc --noEmit    # Type safety
npm test            # All tests
npm run build       # Verify reproducibility (run twice, same result)
```

Record each result (pass/fail, duration) in WORKLOG.md.

If any validation fails:
1. Do not proceed with shutdown
2. Record the failure in PROJECT_STATUS.md
3. Continue normal execution to fix the issue
4. Retry final shutdown in a future run

### Step 3: Generate Final Project Summary

Create a comprehensive summary covering:

1. **Project overview** â€” what was built, what it does
2. **Phases completed** â€” Phase 0 through Phase 4, with dates
3. **Features delivered** â€” all features from TODO.md, checked off
4. **Architecture** â€” final architecture (reference ARCHITECTURE.md)
5. **Test coverage** â€” number of tests, coverage percentage, key test categories
6. **Known limitations** â€” from RISK_REGISTER.md and TECH_DEBT.md
7. **Tech stack** â€” final dependencies from package.json
8. **Key decisions** â€” summary of all DECISIONS.md entries
9. **Metrics** â€” total commits, total files, total lines of code, total tests
10. **What was learned** â€” key lessons from WORKLOG.md

Write the summary to `agent/FINAL_REPORT.md`.

### Step 4: Update PROJECT_STATUS.md

Set the following in PROJECT_STATUS.md:

- **Completion percentage**: 100%
- **Completed features**: all features listed
- **Features in progress**: (none)
- **Remaining work**: (none)
- **Known issues**: any remaining Low-severity debt or risks
- **Test status**: all tests passing, coverage percentage
- **Build status**: passing
- **Last execution summary**: "Final shutdown â€” project completed. See FINAL_REPORT.md for full summary."

### Step 5: Mark PROJECT_COMPLETED

Update `agent/CONTROL_FLAGS.md`:

```
PROJECT_COMPLETED
```

### Step 6: Record Completion in WORKLOG.md

Append a final entry:

```
## [YYYY-MM-DD HH:MM TZ] â€” FINAL SHUTDOWN

**Objectives:**
- Verify project completion
- Generate final report
- Permanently stop autonomous development

**Tasks completed:**
- Verified SUCCESS_CRITERIA.md â€” all criteria met
- Ran full validation pipeline â€” all passing
- Generated FINAL_REPORT.md
- Updated PROJECT_STATUS.md to 100%
- Set CONTROL_FLAGS.md to PROJECT_COMPLETED

**Remaining work:**
- None â€” project is complete

**Note:**
This is the final autonomous execution. No further development will occur unless a human updates SUCCESS_CRITERIA.md with new requirements and sets CONTROL_FLAGS.md to ENABLED.
```

### Step 7: Create Final Engineering Report

Write `agent/FINAL_REPORT.md` with the full project summary from Step 3.

This document is the permanent record of the completed project.

### Step 8: Final Commit

```bash
git add -A
git commit -m "[autonomous] FINAL SHUTDOWN â€” project completed. All criteria met. See FINAL_REPORT.md."
```

### Step 9: Terminate

Execution is permanently complete. No further autonomous work.

---

## Post-Completion Rules

1. **Never perform additional refactoring after project completion** unless explicitly requested by a human.

2. **Never start new features** unless:
   - Human updates SUCCESS_CRITERIA.md with new requirements
   - Human sets CONTROL_FLAGS.md to ENABLED
   - Human updates TODO.md with new tasks

3. **Never modify FINAL_REPORT.md** after creation â€” it is a permanent historical record.

4. **The autonomous engineer may still be invoked** (e.g., by scheduler), but when CONTROL_FLAGS.md reads PROJECT_COMPLETED, it must immediately terminate per AUTONOMOUS_CONTROL.md.

---

## Summary

```
Verify criteria â†’ Validate â†’ Summarize â†’ Update status â†’ Mark complete â†’ Log â†’ Report â†’ Commit â†’ Stop
```

No shortcuts. No skipping steps. The final shutdown is the last thing the autonomous engineer does, and it must be done right.