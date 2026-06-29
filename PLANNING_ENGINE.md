# Planning Engine â€” {{PROJECT_NAME}} Autonomous Engineer

> **This document defines how the autonomous engineer decides what to work on next.** The planner runs at the start of every execution cycle (Phase 1-4) and produces a prioritized task queue.

---

## Planning Algorithm

### Step 1: Repository Evaluation

Every execution begins by evaluating the entire repository. The planner inspects:

1. **`TODO.md`** â€” documented task checklist by phase
2. **`docs/PLAN.md`** â€” phased plan, timeline, decision points
3. **`docs/ARCHITECTURE.md`** â€” architecture, file structure, data models, API contract
4. **`agent/PROJECT_STATUS.md`** â€” current project state
5. **`agent/NEXT_TASK.md`** â€” pre-selected next task
6. **`agent/WORKLOG.md`** â€” recent work history (last 5 entries)
7. **`agent/DECISIONS.md`** â€” architecture decision log
8. **`agent/TECH_DEBT.md`** â€” tracked technical debt items
9. **`agent/RISK_REGISTER.md`** â€” known risks
10. **`agent/BLOCKERS.md`** â€” active blockers
11. **Existing source code** â€” `src/` directory tree, file contents
12. **Existing tests** â€” test files, coverage, pass/fail status
13. **`package.json`** â€” dependencies, scripts
14. **`git log --oneline -20`** â€” recent commit history
15. **`git status`** â€” uncommitted changes

### Step 2: Task Discovery

The planner collects tasks from two sources:

#### A. Documented Tasks

Tasks explicitly listed in:
- `TODO.md` (unchecked items)
- `agent/NEXT_TASK.md` (pre-selected task)
- `docs/PLAN.md` (current phase tasks)

#### B. Discovered Tasks

The planner automatically discovers work that is not explicitly documented by scanning:

| Discovery Method | What It Finds |
|-----------------|---------------|
| `grep -rn "TODO" src/` | TODO comments in code |
| `grep -rn "FIXME" src/` | Known bugs marked in code |
| `grep -rn "HACK" src/` | Technical debt markers |
| Compare `src/` tree vs ARCHITECTURE.md file structure | Missing files |
| Check for empty/stub files | Unfinished implementations |
| Run `npm run build` | Build errors |
| Run `npx tsc --noEmit` | Type errors |
| Run `npm run lint` | Lint violations |
| Run `npm test` | Failing tests |
| Check for files > 300 lines | Large files (refactoring candidates) |
| Check for duplicate function signatures | Duplicated logic |
| Check for unused imports/variables | Dead code |
| Compare test files vs source files | Missing test coverage |
| Check `.gitignore` for missing entries | Security issues (e.g., `.env` not ignored) |
| Scan for `as any` / `@ts-ignore` | Type safety bypasses |
| Check for hardcoded values that should be config | Configuration issues |
| Check for missing error handling | Error handling gaps |
| Check for missing loading states | UX gaps |
| Check for missing accessibility attributes | a11y issues |

### Step 2.5: Diff-Based Analysis

The planner MUST analyze actual code changes before classification. This step is defined in detail in `agent/DIFF_PLANNING.md`.

**Summary:**

1. **Extract diff**: Read `agent/CHECKPOINT` for last checkpoint hash. Run `git diff <checkpoint>..HEAD --stat` and `git diff <checkpoint>..HEAD`.
2. **Classify changes**: For each modified file â€” new stub, new partial, new complete, modified minor, modified major, deleted, config change.
3. **Identify hotspots**: 3+ files in same directory modified, single file > 50 lines diff, file with new code + TODOs, missing tests for modified code, API contract changes.
4. **Assess impact**: Diff size, files affected, API changes, test coverage, dependency on recently modified modules.
5. **Determine stability**: Unstable hotspots (failing build/tests) â†’ Critical. Stable hotspots with missing tests â†’ High. Stable hotspots with tests â†’ Low.

**Global principle enforced**: Stability > Progress. Completing partially modified areas takes priority over starting new ones.

**Output**: Hotspot list, risk assessment, priority adjustments, stability report â€” feeds into Step 3 and Step 4.

### Step 3: Task Classification

Every discovered task is classified by **priority** and **state**.

#### Priority Levels

| Priority | Definition | Examples |
|----------|-----------|----------|
| **Critical** | Blocks all other work or causes data loss / security risk | Build broken, tests failing, security vulnerability, data loss risk, `.env` committed to git |
| **High** | Blocks current phase progress or violates architecture | Architecture violation, missing type definitions for current task, API contract mismatch, unhandled error in core flow |
| **Medium** | Improves quality or completes current phase tasks | Next TODO item, missing tests for completed feature, refactoring candidate, documentation gap |
| **Low** | Nice to have, future phase, or cosmetic | Code style improvements, future phase items, optional features, minor optimizations |

#### Task States

| State | Definition |
|-------|-----------|
| **Completed** | Done, verified, tests pass |
| **In Progress** | Started but not finished (has code, but incomplete or untested) |
| **Blocked** | Cannot proceed â€” waiting on external dependency, decision, or another task |
| **Not Started** | Documented but no work begun |
| **Discovered** | Found by planner, not previously documented â€” needs to be added to TODO.md |

### Step 4: Priority Resolution Rules

When multiple tasks compete, apply these rules in order:

**Diff-aware rules (applied first, from DIFF_PLANNING.md):**

0. **Unstable modified modules are Critical.** If a file was modified since last checkpoint and its tests fail or it doesn't build, fixing it is the highest priority â€” above everything else.
0b. **Partially implemented files are High.** If a file was created but has TODOs or stubs, completing it takes priority over starting new work.
0c. **Modified but untested code is High.** If a file was modified and has no test coverage for the changes, adding tests is High priority.
0d. **Prefer completing partially modified areas.** If a module has 3 of 5 files implemented, finishing the remaining 2 takes priority over starting a new module.
0e. **Large diffs increase priority of stabilization.** If diff since last checkpoint exceeds 100 lines, stabilize existing changes before new work.
0f. **API changes require test verification.** If exported interfaces changed, all dependent modules must be checked for compatibility before new work begins.

**Standard rules (applied after diff-aware rules):**

1. **Critical tasks always go first.** No exceptions. A broken build blocks everything.
2. **Fix regressions before new features.** If something worked before and doesn't now, fix it first.
3. **Finish in-progress work before starting new work.** A half-done task from a previous run takes priority over a fresh task.
4. **Resolve blockers before dependent tasks.** If task B depends on task A, and A is blocked, either unblock A or pick an independent task.
5. **Follow TODO.md order within the same priority.** The documented order reflects intentional sequencing.
6. **Current phase tasks before future phase tasks.** Phase 1 items before Phase 2 items.
7. **Tests for completed features before new features.** If a feature is done but untested, add tests before building the next feature.
8. **Technical debt before new features (when debt is Critical or High).** A High-priority debt item blocks new work.

### Step 5: Task Selection

From the classified and prioritized task list, select exactly one task:

1. Filter to the highest priority level that has any Not Started or In Progress tasks
2. Within that priority level, apply the resolution rules above
3. The selected task becomes the execution target for this run
4. Write the selected task to `agent/NEXT_TASK.md` (overwrite)

### Step 6: Output

The planner produces three outputs:

1. **`agent/TASK_QUEUE.md`** â€” full prioritized task list (regenerated each run)
2. **`agent/NEXT_TASK.md`** â€” single selected task (overwritten each run)
3. **Updates to `TODO.md`** â€” any newly discovered tasks added with `Discovered` origin tag

---

## Planning Principles

1. **Stability > Progress.** The system prefers fixing broken areas, stabilizing modified modules, and reducing risk over adding new features or expanding scope. This is the highest planning principle.

2. **Reality over documentation.** If TODO says "done" but the code doesn't exist or doesn't work, the task is NOT done. Actual code state is authoritative.

3. **Discover aggressively.** The planner doesn't just read TODO.md â€” it scans the actual codebase for problems. Undocumented work is the most dangerous kind.

4. **Be diff-aware.** The planner inspects git diff before every decision. It identifies hotspots of change, prioritizes stabilization of unstable modules, and prefers completing partially modified areas over starting new ones.

5. **Prioritize ruthlessly.** Not all tasks are equal. A broken build is more important than a missing test. A missing test is more important than a code style improvement.

6. **Never lose discovered work.** If the planner finds a TODO comment in code, it gets added to TASK_QUEUE.md and TODO.md. Discovered work is never ignored.

7. **Respect the plan.** TODO.md and PLAN.md define the intended order. The planner follows that order unless a higher-priority issue overrides it.

8. **One task at a time.** The planner selects one task. The engineer executes one task. Multitasking leads to half-finished work.

9. **Blockers are first-class citizens.** A blocked task isn't ignored â€” it's tracked in BLOCKERS.md with a cause and suggested resolution. The human can then unblock it.

10. **Technical debt is tracked, not hidden.** Every shortcut, hack, or code smell goes into TECH_DEBT.md. Future runs can address it systematically.

11. **Risks are explicit.** Potential problems go into RISK_REGISTER.md with probability, impact, and mitigation. Silent risks become surprises.

12. **The planner is conservative.** When uncertain, it picks the safer option: fix before build, test before feature, refactor before new code.