# Failure Recovery â€” {{PROJECT_NAME}}

> **How the autonomous engineer reacts when something goes wrong.** Every failure type has a detection method, immediate action, recovery strategy, and escalation criteria. Never ignore failures â€” always follow the protocol.

---

## Failure Type 1: Compilation Fails

**Detection**: `npx tsc --noEmit` or `npm run build` exits non-zero.

**Immediate action**:
1. Read the error output completely
2. Identify the root cause (missing import, wrong type, syntax error)
3. Fix the specific error â€” do not rewrite large sections

**Recovery strategy**:
1. Fix errors one at a time, starting with the first reported error (subsequent errors may be cascading from it)
2. After each fix, re-run `npx tsc --noEmit`
3. Continue until typecheck passes
4. If the error is in code written in this run: fix it
5. If the error is in pre-existing code: this is a regression â€” see Failure Type 7

**Escalation criteria**:
- **3 failed fix attempts** on the same error â†’ stop, document in WORKLOG, finish with "partial" status
- **Error requires architectural change** â†’ stop, log in DECISIONS.md, request human review
- **Error caused by missing dependency** â†’ install the dependency (with DECISIONS.md entry) or find an alternative

---

## Failure Type 2: Tests Fail

**Detection**: `npm test` exits non-zero or reports failing tests.

**Immediate action**:
1. Read the failing test output â€” what test, what expected vs actual
2. Determine: is the test wrong or is the code wrong?

**Recovery strategy**:

**If the code is wrong (test is correct)**:
1. Identify the bug in the implementation
2. Fix the bug
3. Re-run the failing test
4. Run the full test suite to check for regressions

**If the test is wrong (code is correct)**:
1. Identify why the test is wrong (changed behavior, stale assertion, wrong mock)
2. Fix the test
3. Re-run the test suite
4. Document in WORKLOG why the test was wrong

**If unclear who's wrong**:
1. Re-read the task spec in NEXT_TASK.md
2. Re-read the relevant section of ARCHITECTURE.md
3. Determine the intended behavior
4. Fix whichever is wrong

**Escalation criteria**:
- **3 failed fix attempts** on the same test â†’ stop, document, finish with "partial"
- **Test reveals architecture issue** â†’ log in DECISIONS.md, request human review
- **Multiple tests failing for different reasons** â†’ fix one at a time, but after 5 total failures, stop and document

---

## Failure Type 3: Unexpected Runtime Behavior

**Detection**: Code compiles and tests pass, but manual testing reveals unexpected behavior (blank screen, wrong data, crash on interaction).

**Immediate action**:
1. Reproduce the behavior reliably
2. Trace the data flow: input â†’ processing â†’ output
3. Identify where the behavior diverges from expectation

**Recovery strategy**:
1. Add a test that reproduces the unexpected behavior
2. Fix the code so the test passes
3. Verify the fix doesn't break other tests
4. Run the full test suite

**Escalation criteria**:
- **Cannot reproduce** â†’ log in WORKLOG, add to KNOWN ISSUES in PROJECT_STATUS.md
- **Behavior is caused by external API** â†’ check API response, add mock, test locally
- **Behavior requires design decision** â†’ log in DECISIONS.md, request human review

---

## Failure Type 4: Architecture Conflict

**Detection**: Implementation requires a pattern, structure, or data flow that contradicts ARCHITECTURE.md.

**Immediate action**:
1. Stop implementation
2. Identify the specific conflict (which section of ARCHITECTURE.md, what the code needs)
3. Assess: is the architecture wrong, or is the implementation wrong?

**Recovery strategy**:

**If the architecture is wrong (reality requires a change)**:
1. Draft a DECISIONS.md entry: date, decision, reasoning, alternatives
2. Update ARCHITECTURE.md to reflect the new pattern
3. Resume implementation following the updated architecture
4. Note in WORKLOG that architecture was updated

**If the implementation is wrong (code should follow existing architecture)**:
1. Rewrite the implementation to follow ARCHITECTURE.md
2. No documentation changes needed
3. Note in WORKLOG that a deviation was corrected

**Escalation criteria**:
- **Architecture change affects multiple components** â†’ stop, document, request human review
- **Architecture change contradicts a previous DECISIONS.md entry** â†’ do not change without human approval
- **Unsure whether it's an architecture issue or implementation issue** â†’ default to following existing architecture, log the tension in WORKLOG

---

## Failure Type 5: Dependency Conflict

**Detection**: `npm install` fails, package version mismatch, or a dependency doesn't work as expected.

**Immediate action**:
1. Read the error output
2. Identify the conflicting package and version

**Recovery strategy**:

**Version conflict**:
1. Check if the required version is compatible with the project
2. If a newer version is needed: update `package.json`, run `npm install`, verify build still passes
3. If an older version is needed: pin the version in `package.json`
4. Log the dependency change in DECISIONS.md

**Package not found or deprecated**:
1. Search for an alternative package
2. Evaluate: does it do what we need? Is it maintained? Is it secure?
3. Install the alternative, verify it works
4. Log in DECISIONS.md with reasoning

**Peer dependency conflict**:
1. Try `npm install --legacy-peer-deps` as a temporary measure
2. Log in TECH_DEBT.md â€” this needs proper resolution
3. Do not make `--legacy-peer-deps` a permanent solution without a DECISIONS.md entry

**Escalation criteria**:
- **No suitable alternative package** â†’ stop, log in BLOCKERS.md, request human review
- **Installing the package requires changing Node version** â†’ stop, request human review
- **Package has known security vulnerabilities** â†’ do not install, find alternative

---

## Failure Type 6: Merge Conflict

**Detection**: `git status` shows unmerged files, or `git merge` reports conflicts.

**Immediate action**:
1. Run `git status` to see conflicted files
2. Do not force-resolve without understanding both sides

**Recovery strategy**:
1. Read both sides of the conflict (ours and theirs)
2. Determine which side is correct, or if a manual merge is needed
3. Resolve the conflict by editing the file
4. Run `npm run build` and `npm test` to verify the resolution is correct
5. `git add` the resolved files and continue

**Escalation criteria**:
- **Conflict involves files modified by human** â†’ prefer the human's changes, log in WORKLOG
- **Conflict cannot be resolved without understanding intent** â†’ stop, log in BLOCKERS.md, request human review
- **Same file conflicts repeatedly** â†’ may indicate a design issue; log in DECISIONS.md

---

## Failure Type 7: Regression â€” Previously Working Code Breaks

**Detection**: Code that passed build/tests in a previous run now fails.

**Immediate action**:
1. Run `git diff` to identify what changed
2. Determine which change caused the regression

**Recovery strategy**:
1. **Priority: fix the regression before any new work** (per EXECUTION_RULES.md Rule 3)
2. If the regression is caused by this run's changes:
   a. Fix the code that caused the regression
   b. Add a test that would have caught the regression
   c. Re-run full test suite
3. If the regression is caused by a dependency update:
   a. Revert the dependency update
   b. Log in DECISIONS.md why the update was reverted
   c. Find a compatible alternative
4. If the regression is pre-existing (not caused by this run):
   a. This becomes the highest priority task (Critical)
   b. Fix the regression
   c. Document in WORKLOG and PROJECT_STATUS.md

**Escalation criteria**:
- **Regression in core flow** ({{COMPONENT_NAME}}, {{COMPONENT_NAME}}, {{COMPONENT_NAME}}) â†’ stop all other work, fix immediately
- **Regression fix requires significant rework** â†’ stop, log in BLOCKERS.md, request human review
- **Multiple regressions** â†’ fix the most severe first, log all in PROJECT_STATUS.md

---

## Failure Type 8: Infinite Implementation Loop

**Detection**: The same task has been attempted 3+ times without completion. WORKLOG shows repeated entries for the same task with "remaining work: same task."

**Immediate action**:
1. Stop implementing
2. Read the last 3 WORKLOG entries for this task
3. Identify what's blocking completion each time

**Recovery strategy**:
1. **The task is too large** â†’ split it into smaller subtasks (per TASK_SIZE_POLICY.md Rule 3)
2. **The task has hidden dependencies** â†’ resolve the dependencies first, then retry
3. **The task requires a decision not in the docs** â†’ log in BLOCKERS.md, request human review
4. **The approach is fundamentally wrong** â†’ draft a new approach, log in DECISIONS.md, restart

**Escalation criteria**:
- **3 failed attempts on the same task** â†’ mandatory stop, log in BLOCKERS.md, request human review
- **Task was split but subtasks also fail** â†’ the problem is upstream (architecture or design), request human review
- **Same error keeps recurring despite fixes** â†’ the fix is treating symptoms, not root cause. Stop and analyze.

---

## Failure Type 9: Repeated Unsuccessful Attempts

**Detection**: The same error keeps occurring after multiple fix attempts. The fix-and-retry cycle isn't converging.

**Immediate action**:
1. Stop fixing
2. Read all attempted fixes from WORKLOG
3. Identify the pattern â€” are all fixes addressing the same symptom?

**Recovery strategy**:
1. **Root cause analysis**: the real problem is likely upstream from where the error manifests
2. Trace the error backward: error â†’ function that threw â†’ data that caused it â†’ source of the data
3. Fix the root cause, not the symptom
4. If the root cause is in a different part of the codebase, fix there instead
5. Add a test that verifies the root cause is fixed

**Escalation criteria**:
- **3 failed fix attempts on the same error** â†’ stop, perform root cause analysis
- **Root cause analysis reveals architecture issue** â†’ log in DECISIONS.md, request human review
- **Root cause is in external API behavior** â†’ add workaround with explicit `// HACK:` comment and TECH_DEBT.md entry, log in WORKLOG

---

## Failure Type 10: Out of Time / Token Budget

**Detection**: The execution is taking significantly longer than expected, or the task is clearly too large for one cycle.

**Immediate action**:
1. Assess: can the current task be completed in the remaining time?
2. If yes: continue, but skip non-essential phases (Phase 13 â€” Add Missing Tests can be deferred to next run with a TODO)
3. If no: wrap up cleanly

**Recovery strategy**:
1. Ensure all code written so far compiles (`npx tsc --noEmit`)
2. If code doesn't compile: add `// TODO: [what's left]` to all incomplete files
3. Update TODO.md â€” mark task as "(in progress: [what's done], [what's left])"
4. Update PROJECT_STATUS.md â€” task is "In Progress", not "Completed"
5. Update NEXT_TASK.md â€” same task, with notes on what's already done
6. Append WORKLOG entry â€” explain what was accomplished and what remains
7. Commit the partial work (if it compiles)
8. Finish execution

**Escalation criteria**:
- **Task has been "in progress" across 3 runs** â†’ see Failure Type 8 (Infinite Implementation Loop)
- **Partial work doesn't compile** â†’ do not commit, log in WORKLOG, request human review

---

## General Failure Protocol

Regardless of failure type, these rules always apply:

0. **Git rollback is the PRIMARY recovery mechanism.** If recovery is required:
   1. Revert to last checkpoint: `git reset --hard <checkpoint-hash>` (read from `agent/CHECKPOINT`)
   2. Re-run build: `npm run build` â€” verify the rollback restored a working state
   3. Re-evaluate task queue: the failed task may need to be split or approached differently
   4. Update `TECH_DEBT.md` with root cause analysis of what went wrong
   5. Log the rollback incident in `DECISIONS.md`
   6. Log the rollback in `WORKLOG.md` with checkpoint hash and reason
   7. Remove `agent/LOCK` and exit â€” next run will attempt a fresh approach

   **When to rollback vs. fix in place:**
   - **Rollback**: Build/test/typecheck fails after 3 fix attempts. Critical runtime error introduced. Regression that can't be quickly fixed.
   - **Fix in place**: Simple typo, missing import, wrong type annotation. Fixable in < 5 minutes.

1. **Never hide a failure.** Log it in WORKLOG with full details.
2. **Never commit broken code.** If build/tests fail, do not commit.
3. **Never blame the tools.** "The compiler is buggy" is almost never true. Look at your code first.
4. **Never fix symptoms.** Always trace to the root cause.
5. **Never skip the Quality Gate.** Even if the task took 3 hours, the checklist still runs.
6. **Always update PROJECT_STATUS.md with failures.** Known Issues section must reflect reality.
7. **Always request human review when escalation criteria are met.** Do not keep trying indefinitely.

---

## Summary

```
ANY failure (after 3 fix attempts) â†’ ROLLBACK to checkpoint (PRIMARY)
  â”œâ”€ git reset --hard <checkpoint>
  â”œâ”€ Re-run build to verify recovery
  â”œâ”€ Log in WORKLOG + TECH_DEBT + DECISIONS
  â””â”€ Exit â€” next run retries with fresh approach

Compilation fails â†’ Fix (3 attempts) â†’ Rollback if still failing
Tests fail â†’ Determine who's wrong â†’ Fix (3 attempts) â†’ Rollback if still failing
Runtime bug â†’ Reproduce â†’ Test â†’ Fix â†’ Rollback if regression
Architecture conflict â†’ Update docs or fix code â†’ Rollback if broke build
Dependency conflict â†’ Find alternative or pin version
Merge conflict â†’ Understand both sides â†’ Resolve carefully
Regression â†’ Fix before any new work â†’ Rollback if unfixable
Infinite loop â†’ Stop â†’ Split or escalate
Repeated failures â†’ Root cause analysis â†’ Rollback to checkpoint
Out of time â†’ Wrap up cleanly â†’ Commit partial if compiling
```