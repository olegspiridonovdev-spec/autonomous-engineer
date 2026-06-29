# Self-Review â€” {{PROJECT_NAME}}

> **After every completed implementation, the autonomous engineer performs a structured retrospective.** This happens during Phase 7 (Refactor) and before the Quality Gate check. If serious issues are discovered, fix them before marking the task complete.

---

## Retrospective Questions

Answer each question honestly. The purpose is not to pat yourself on the back â€” it's to catch mistakes before they ship.

### 1. Did I Actually Solve the Requested Problem?

- Does the implementation do what NEXT_TASK.md specified?
- Does it meet the acceptance criteria?
- Does it pass the verification checklist from NEXT_TASK.md?
- Is there any part of the task spec that was skipped or quietly ignored?

**If no**: The task is not done. Return to Phase 6 (Implement) and finish the missing parts.

### 2. Did I Introduce Unnecessary Complexity?

- Are there abstractions that aren't needed yet?
- Are there configuration options that nobody asked for?
- Is there logic that handles cases that can't happen in Phase 1?
- Are there patterns (factories, builders, strategies) where a simple function would do?

**If yes**: Simplify. Remove the abstraction. YAGNI (You Aren't Gonna Need It).

### 3. Could This Implementation Be Simpler?

- Could a 50-line function be a 20-line function?
- Could three files be two files?
- Could a complex type be a simpler type?
- Could a loop be a map/filter/reduce?

**If yes**: Simplify before finishing. Simpler code is easier to test, review, and maintain.

### 4. Does It Match the Architecture?

- Does the implementation follow the patterns in ARCHITECTURE.md?
- Are the file locations correct per the MVP file structure?
- Are the TypeScript interfaces matching the data models section?
- Are the API calls matching the API contract section?

**If no**: Either fix the code to match the architecture, or update the architecture (with a DECISIONS.md entry explaining why). Never silently deviate.

### 5. Are There Edge Cases I Missed?

- What happens on empty input?
- What happens on null/undefined?
- What happens on API failure?
- What happens on network timeout?
- What happens on extremely long input?
- What happens on rapid repeated calls?
- What happens if localStorage is full or unavailable?

**If yes**: Add handling for the missed edge cases. Add tests for each edge case.

### 6. Are There Missing Tests?

- Does every new function have at least one test?
- Does every new component have a render test?
- Are there tests for error paths, not just happy paths?
- Are there tests for edge cases identified in question 5?

**If yes**: Write the missing tests before finishing.

### 7. Did I Duplicate Existing Logic?

- Is there already a utility function that does what my new code does?
- Is there already a component that handles the UI pattern I just created?
- Is there already a type that covers what my new type describes?

**If yes**: Remove the duplication. Use the existing code. If the existing code needs modification, modify it rather than duplicating.

### 8. Did I Create Technical Debt?

- Did I use `as any` or `@ts-ignore`?
- Did I leave a `// TODO` without a TECH_DEBT.md entry?
- Did I skip error handling "for now"?
- Did I hardcode a value that should be configurable?
- Did I write a function that's too long or too complex?

**If yes**: Either fix it now, or log it in TECH_DEBT.md with severity and a plan for resolution.

### 9. Did I Update Every Affected Document?

- Did ARCHITECTURE.md change? â†’ Update it.
- Did PLAN.md timeline change? â†’ Update it.
- Did README.md features change? â†’ Update it.
- Did a prompt file change? â†’ Update it.
- Did the file structure change? â†’ Update ARCHITECTURE.md MVP file structure section.

**If no**: Update the affected documents now. Stale docs are bugs.

### 10. What Should Be Improved Before Moving On?

- Is there anything about this implementation that would embarrass you in a code review?
- Is there anything you'd want to explain or apologize for?
- Is there anything that "works but isn't right"?

**If yes**: Fix it. The next run shouldn't inherit your shortcuts.

---

## Self-Review Flow

```
Implementation complete
        â”‚
        â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Answer Q1-Q10       â”‚
â”‚ honestly             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
          â”‚
    â”Œâ”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”
    â”‚           â”‚
  No issues   Issues found
    â”‚           â”‚
    â–¼           â–¼
  Continue   Fix issues
              â”‚
              â–¼
          Re-review
          (Q1-Q10 again)
              â”‚
              â–¼
          No serious issues?
              â”‚
              â–¼
          Continue to
          Quality Gate
```

---

## Rule

**Self-review is not optional.** It is not a formality. It is the last chance to catch mistakes before they become someone else's problem. Take it seriously. Be honest. Be critical. The code you save may be your own â€” in the next run.