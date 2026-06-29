# Execution Cycle â€” {{PROJECT_NAME}} Autonomous Engineer

> **This document describes the exact lifecycle of every autonomous execution.** Each run follows these phases in order. No phase is skipped. No phase is reordered.

---

## Phase 0: Git Checkpoint

Before any work begins, create a safe baseline that can be rolled back to if anything goes wrong.

1. Run `bash agent/CHECKPOINT_MANAGER.sh "<objective from NEXT_TASK.md>"` â€” creates checkpoint commit
2. Verify `agent/CHECKPOINT` file was created with valid hash
3. Run `npm run build` â€” verify the project builds BEFORE making any changes
4. If build fails at checkpoint: the project was already broken â€” this becomes a Critical task (fix the pre-existing breakage before any new work)
5. Record checkpoint hash in mental context for potential rollback

**Output**: Valid git checkpoint with hash recorded in `agent/CHECKPOINT`.

**Failure condition**: If checkpoint cannot be created (git error, disk full), abort execution and log the error in WORKLOG.

**Rollback trigger**: If any subsequent phase fails beyond recovery (3 attempts), execute `git reset --hard <checkpoint-hash>` per `GIT_SAFETY.md`.

---

## Phase 1: Load Context

Read all reference files to build a complete understanding of the project state:

1. Read `agent/AUTONOMOUS_ENGINEER.md` â€” operating instructions
2. Read `agent/PROJECT_STATUS.md` â€” current project state
3. Read `agent/NEXT_TASK.md` â€” the single highest-priority task
4. Read `agent/WORKLOG.md` â€” recent work history (last 5 entries)
5. Read `agent/DECISIONS.md` â€” architecture decisions log
6. Read `TODO.md` â€” implementation checklist
7. Read `docs/ARCHITECTURE.md` â€” system architecture (scan relevant sections for current task)
8. Read `docs/PLAN.md` â€” current phase context
9. Read relevant `docs/prompts/*` files if task involves prompts
10. Read relevant source files if task modifies existing code

**Output**: Full mental model of project state, current task, and constraints.

**Failure condition**: If any required file is missing or unreadable, abort execution and log the error in WORKLOG.

---

## Phase 2: Analyze Repository

Inspect the actual codebase to verify it matches documented state:

1. Run `git status` â€” check for uncommitted changes
2. Run `git log --oneline -10` â€” recent commit history
3. List `src/` directory tree â€” verify file structure matches ARCHITECTURE.md
4. Check `package.json` â€” verify dependencies are installed
5. Run `npm ls --depth=0` â€” confirm no missing packages
6. Scan for TODO/FIXME/HACK comments in source: `grep -rn "TODO\|FIXME\|HACK" src/`
7. Check for TypeScript errors: `npx tsc --noEmit` (if project is scaffolded)
8. Check for lint errors: `npm run lint` (if linting is configured)

**Output**: Verified snapshot of actual repo state vs documented state. Discrepancies noted.

**Action on discrepancy**: If actual state differs from PROJECT_STATUS.md, update PROJECT_STATUS.md in Phase 16 to reflect reality.

---

## Phase 3: Determine Current Progress

Cross-reference multiple sources to determine true progress:

1. Check `TODO.md` â€” count completed vs total items in current phase
2. Check `agent/PROJECT_STATUS.md` â€” completion percentage
3. Check `agent/WORKLOG.md` â€” last completed tasks
4. Check actual source files â€” do they exist and contain real implementation?
5. Check `git log` â€” what was actually committed

**Output**: Accurate progress assessment with evidence.

**Rule**: Actual code state is authoritative. If TODO says "done" but code doesn't exist or doesn't work, mark as NOT done.

---

## Phase 4: Select Highest Priority Task

Determine the single most important task to execute:

1. Read `agent/NEXT_TASK.md` â€” this is the pre-selected task
2. Validate it against TODO.md â€” is it the next logical item?
3. Validate it against PROJECT_STATUS.md â€” is it the highest-impact remaining work?
4. Check for blocking issues â€” are there known issues or regressions that must be fixed first?
5. Check for partially finished work â€” is there incomplete work from a previous run that should be finished first?

**Priority order** (highest first):
1. Fix regressions / failing tests / broken build
2. Finish partially started work from previous run
3. Next item in TODO.md for current phase
4. Task from NEXT_TASK.md

**Output**: One clearly defined task with acceptance criteria.

**Action**: If the selected task differs from NEXT_TASK.md, update NEXT_TASK.md with the new task and note the reason in WORKLOG.

---

## Phase 5: Design Solution

Before writing any code, design the solution:

1. Re-read the relevant section of `docs/ARCHITECTURE.md` for the component being built
2. Identify which files need to be created or modified
3. Identify which interfaces/types are involved
4. Identify dependencies on other components
5. Sketch the implementation approach (data flow, function signatures, component structure)
6. Check if the design violates any entry in `agent/DECISIONS.md`
7. If the design introduces a new architectural pattern, draft a DECISIONS.md entry

**Output**: Clear implementation plan â€” which files, what changes, what order.

**Rule**: If the design contradicts ARCHITECTURE.md, either adjust the design or update ARCHITECTURE.md first (with a DECISIONS.md entry explaining why).

---

## Phase 6: Implement

Write the code according to the design from Phase 5:

1. Create or modify files in the order determined by dependencies (types â†’ utilities â†’ components â†’ pages)
2. Follow the patterns and conventions in ARCHITECTURE.md
3. Use the exact interfaces and type definitions from ARCHITECTURE.md data models section
4. Embed prompt texts from `docs/prompts/*` into `src/lib/prompts/*` files
5. Write clean, readable code â€” no clever tricks at the expense of clarity
6. Add inline comments only for non-obvious logic
7. Mark any incomplete work with `// TODO: [description]` comments

**Output**: Working implementation of the selected task.

**Rule**: Never leave a file half-implemented without a `// TODO` comment explaining what's missing and why.

**Rule**: Never implement something that contradicts the documented architecture. If the architecture needs to change, update the docs first (Phase 14).

---

## Phase 7: Refactor

Review the code just written and improve it before validation:

1. Check for code duplication â€” extract shared logic into utility functions
2. Check for overly long functions â€” split into smaller, named functions
3. Check for unclear naming â€” rename variables/functions for readability
4. Check for missing or incorrect TypeScript types â€” no `any` without explicit justification
5. Check for dead code â€” remove unused imports, variables, functions
6. Check for consistency with existing codebase patterns
7. Verify error handling is present where needed
8. Verify edge cases are handled (null, undefined, empty arrays, API failures)

**Output**: Clean, production-quality code.

**Rule**: Refactoring must not change behavior. If behavior changes, it's a new feature or bug fix â€” treat accordingly.

---

## Phase 8: Run Build

Validate that the code compiles:

```bash
npm run build
```

**On success**: Proceed to Phase 9.

**On failure**:
1. Read the error messages
2. Fix the root cause (not just the symptom)
3. Re-run build
4. Repeat until build passes (max 3 attempts)
5. If build still fails after 3 attempts, log the failure in WORKLOG, update PROJECT_STATUS with the error, and finish execution

**Output**: Successful build or documented failure.

---

## Phase 9: Run Lint

Validate code quality:

```bash
npm run lint
```

**On success**: Proceed to Phase 10.

**On failure**:
1. Read lint errors
2. Fix each error (auto-fix where possible: `npm run lint -- --fix`)
3. Re-run lint
4. If lint still fails after fixes, log remaining issues and assess severity
5. Never disable lint rules to bypass errors â€” fix the code instead

**Output**: Clean lint or documented exceptions.

---

## Phase 10: Run Typecheck

Validate TypeScript types:

```bash
npx tsc --noEmit
```

**On success**: Proceed to Phase 11.

**On failure**:
1. Read type errors
2. Fix each error (add proper types, fix type mismatches)
3. Re-run typecheck
4. Never use `as any` or `// @ts-ignore` to bypass type errors â€” fix the root cause
5. If typecheck still fails after 3 attempts, log failure and finish execution

**Output**: Clean typecheck or documented failure.

---

## Phase 11: Run Tests

Validate behavior:

```bash
npm test
```

**On success**: Proceed to Phase 12.

**On failure** or **no tests exist yet**:
1. If no test runner is configured, skip this phase (note in WORKLOG)
2. If tests exist but fail, proceed to Phase 12 (Fix Failures)
3. If tests pass, proceed to Phase 13

**Output**: Test results (pass count, fail count, coverage if available).

---

## Phase 12: Fix Failures

Address any failures from Phase 8-11:

1. **Build failures**: Fix compilation errors (missing imports, syntax errors, type errors)
2. **Lint failures**: Fix code quality issues
3. **Typecheck failures**: Fix type errors
4. **Test failures**:
   a. Read the failing test
   b. Determine if the test is wrong or the code is wrong
   c. If the test is wrong â†’ fix the test
   d. If the code is wrong â†’ fix the code
   e. Re-run the failing test
5. After each fix, re-run the relevant validation (build/lint/typecheck/test)

**Max attempts**: 3 rounds of fixes per failure type. If still failing, document the failure and finish execution.

**Output**: All validations passing, or documented unresolved failures.

---

## Phase 13: Add Missing Tests

Ensure test coverage for the work just completed:

1. Identify what was implemented in this run
2. Check if tests exist for the new functionality
3. If no tests exist, write them:
   - Unit tests for utility functions and pure logic
   - Component tests for React components (rendering, user interaction)
   - Integration tests for API calls (mocked)
4. Run tests to verify they pass
5. If tests reveal bugs, go back to Phase 12

**Rule**: Every new feature or behavior change must have tests. No exceptions.

**Output**: Test suite covering the new implementation, all passing.

---

## Phase 14: Update Documentation

Keep documentation in sync with code:

1. Update `docs/ARCHITECTURE.md` if architectural details changed
2. Update `docs/PLAN.md` if timeline or scope changed
3. Update `TODO.md` â€” check off completed items
4. Update `README.md` if features or setup instructions changed
5. If a new architectural decision was made, append to `agent/DECISIONS.md`
6. Update any inline documentation (JSDoc, component comments) that is now stale

**Rule**: Documentation is never "later." If behavior changed, docs change in the same run.

**Output**: All documentation reflects the current code state.

---

## Phase 15: Update TODO

Synchronize the implementation checklist:

1. Read `TODO.md`
2. Check off items completed in this run
3. If a task was partially completed, leave it unchecked but add a note: `(in progress: [what's done], [what's left])`
4. Do not add new tasks that aren't in the plan â€” use DECISIONS.md for scope changes
5. Ensure the next unchecked item is the logical next task

**Output**: TODO.md accurately reflects what's done and what's next.

---

## Phase 16: Update PROJECT_STATUS

Reflect the new state of the project:

1. Update completion percentage (count completed TODO items / total items in current phase)
2. Move completed features to "Completed Features" section
3. Update "Features In Progress" with any partially done work
4. Update "Remaining Work" â€” remove completed items, add newly discovered work
5. Update "Known Issues" with any unresolved problems
6. Update "Test Status" with current test results
7. Update "Build Status" with current build result
8. Update "Last Execution Summary" with a 2-3 sentence summary of this run

**Output**: PROJECT_STATUS.md is an accurate snapshot of project health.

---

## Phase 17: Update NEXT_TASK

Select and document the single next task:

1. Read `TODO.md` â€” find the next unchecked item
2. Read `PROJECT_STATUS.md` â€” check for blocking issues or in-progress work
3. If there are blocking issues â†’ next task is fixing them
4. If there is partially finished work â†’ next task is completing it
5. Otherwise â†’ next task is the next unchecked TODO item
6. Write the task into `agent/NEXT_TASK.md` â€” completely overwrite the file
7. Include: task title, priority, steps, expected output, verification checklist

**Output**: NEXT_TASK.md contains exactly one task, fully specified, ready for the next run.

---

## Phase 18: Append WORKLOG

Record what happened in this run:

1. Append a new entry to `agent/WORKLOG.md` (do not modify existing entries)
2. Use the entry template format
3. Fill in all fields:
   - Timestamp (ISO format with timezone)
   - Objectives (what was planned)
   - Tasks completed (what was actually done)
   - Bugs fixed (if any)
   - Tests added (if any)
   - Documentation updated (which files)
   - Remaining work (what's left from this run's objectives)

**Output**: WORKLOG.md has a new entry documenting this run.

---

## Phase 19: Decide Whether Another Internal Cycle Should Run

Evaluate whether another execution cycle should run immediately:

**Run another cycle if ALL of these are true:**
- Build passes
- Tests pass (or no tests configured yet)
- There is a clear next task in NEXT_TASK.md
- The next task is estimated to take less than the remaining time budget
- No human input is required for the next task
- The previous cycle produced meaningful output (not just fixes)

**Do NOT run another cycle if ANY of these are true:**
- Build or tests are failing
- The next task requires a decision not covered by existing documentation
- The next task involves external dependencies (API keys, third-party services)
- The previous cycle failed to complete its primary objective
- Human review is needed before proceeding

**Action**: If running another cycle, return to Phase 1. If not, proceed to Phase 20.

---

## Phase 20: Finish Execution

Clean up and report:

1. Run `git status` â€” note any uncommitted changes
2. Run `git add -A && git commit -m "[autonomous] [task name] â€” [brief result]"` if changes were made
3. Verify all agent files are consistent:
   - PROJECT_STATUS.md reflects reality
   - NEXT_TASK.md has exactly one task
   - WORKLOG.md has the new entry
   - TODO.md is synchronized
   - DECISIONS.md has any new decisions
4. Print execution summary:
   - Task attempted
   - Task result (completed / partial / failed)
   - Build/lint/typecheck/test status
   - Files created/modified
   - Next task preview
5. Execution is complete

**Output**: Clean git state, consistent agent files, clear summary.

---

## Quick Reference: Phase Order

```
 0. Git Checkpoint (NEW â€” safety baseline before any work)
 1. Load Context
 2. Analyze Repository
 3. Determine Current Progress
 4. Select Highest Priority Task
 5. Design Solution
 6. Implement
 7. Refactor
 8. Run Build
 9. Run Lint
10. Run Typecheck
11. Run Tests
12. Fix Failures
13. Add Missing Tests
14. Update Documentation
15. Update TODO
16. Update PROJECT_STATUS
17. Update NEXT_TASK
18. Append WORKLOG
19. Decide Whether Another Internal Cycle Should Run
20. Finish Execution
```

No phase is skipped. No phase is reordered. Phase 0 is mandatory â€” no execution may proceed without a valid checkpoint.