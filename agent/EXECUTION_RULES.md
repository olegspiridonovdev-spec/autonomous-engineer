# Execution Rules â€” {{PROJECT_NAME}} Autonomous Engineer

> **Permanent engineering rules.** These rules apply to every autonomous execution, every phase, every task. They are never overridden, never suspended, never relaxed.

---

## Build & Tests

1. **Never intentionally break the build.** If the build was passing before your run, it must pass after your run. If you cannot make it pass, revert your changes and log the failure.

2. **Never ignore failing tests.** A failing test is a bug. Fix the bug or fix the test. Never delete a test to make it pass. Never skip a test with `.skip` without a documented reason in the test file.

3. **Fix regressions before implementing new features.** If something that worked before is now broken, fixing it is priority #1. No new features ship on top of a broken build.

4. **Every new feature must have tests.** If you add functionality, you add tests. If you add a function, you test it. If you add a component, you test it. No tests = feature is not done.

---

## Code Quality

5. **Never leave unfinished code without marking it.** If a function is a stub, add `// TODO: implement [what]`. If a component renders a placeholder, add `// TODO: complete [what]`. Unmarked unfinished code is a lie.

6. **Prefer refactoring over duplication.** If you're about to copy-paste a block of code, extract a function instead. If you see existing duplication, refactor it. Duplication is technical debt.

7. **Never use `as any` or `// @ts-ignore` to bypass type errors.** Fix the root cause. TypeScript types exist to catch bugs. Bypassing them defeats the purpose. The only exception: mocking in tests, with a comment explaining why.

8. **Never disable lint rules to bypass errors.** Fix the code. Lint rules exist to enforce quality. If a rule is genuinely wrong, propose changing it in DECISIONS.md â€” don't silently disable it.

---

## Architecture

9. **Never violate the documented architecture.** `docs/ARCHITECTURE.md` is the source of truth for system design. If you need to deviate, either change the architecture (with a DECISIONS.md entry) or don't deviate.

10. **Always update documentation when behavior changes.** If you change how something works, update the docs in the same run. Documentation is never "later." Stale docs are worse than no docs.

---

## Task Management

11. **Always keep TODO synchronized.** `TODO.md` must reflect reality. If something is done, check it off. If something is partially done, note what's left. If something is blocked, note the blocker.

12. **Prefer completing partially finished work before starting unrelated work.** If a previous run left a task 80% done, finish it. Don't start a new task while an old one hangs.

13. **One task per run.** Each execution cycle targets exactly one task (as defined in NEXT_TASK.md). If the task is small and another can fit, the internal cycle decision (Phase 19) handles that. Don't multitask.

---

## Git & Commits

14. **Commit after each successful run.** If the build passes and tests pass, commit with a descriptive message: `[autonomous] [task] â€” [result]`. If the build fails, do not commit broken code.

15. **Never force-push.** Never rewrite history. Never delete branches you didn't create. Standard git hygiene.

16. **Never commit secrets.** API keys, passwords, tokens â€” none of these go into git. If `.env` is accidentally staged, unstage it immediately.

---

## Scope & Boundaries

17. **Do not expand scope without authorization.** If you discover a new feature that would be "nice to have," document it in PROJECT_STATUS.md under "Remaining Work" â€” don't implement it.

18. **Do not modify files outside the project scope.** Don't touch `.openclaw/` files, workspace files, or system configuration. Only modify files within `C:\Users\Oleg\Documents\Projects\{{PROJECT_SLUG}}\`.

19. **Do not install new dependencies without justification.** Every new dependency must be justified in a DECISIONS.md entry. Prefer using what's already installed. Prefer standard library over third-party.

20. **When in doubt, document and ask.** If a decision is not covered by existing documentation, don't guess. Log the question in WORKLOG.md and pick the most conservative option. Let the human review.

---

## Summary

```
Build must pass. Tests must pass. Types must be clean. Lint must be clean.
Docs must be updated. TODO must be synced. One task per run.
Never break what worked. Never skip what's required.
When in doubt, be conservative.
```