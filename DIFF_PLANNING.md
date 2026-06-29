# Diff-Based Planning â€” {{PROJECT_NAME}} Autonomous System

> **The planner MUST analyze actual code changes (git diff) before deciding what to work on next.** Relying only on TODO.md is insufficient â€” the real codebase state is authoritative.

---

## Principle

Planning must be **diff-aware**. The planner inspects what actually changed since the last checkpoint, identifies hotspots of change, and prioritizes stabilization of unstable modules over starting new work.

**Stability > Progress.** Completing partially modified areas takes priority over beginning new ones.

---

## Diff Analysis Protocol

Before task selection (PLANNING_ENGINE.md Step 4), the planner MUST perform diff-based analysis:

### Step A: Extract Diff

1. Read `agent/CHECKPOINT` â€” get last checkpoint hash
2. Run `git diff <checkpoint>..HEAD --stat` â€” identify which files changed
3. Run `git diff <checkpoint>..HEAD` â€” full diff of all changes
4. Run `git status` â€” check for uncommitted changes

### Step B: Classify Changes

For each modified file, classify:

| Category | Indicators | Priority Impact |
|----------|-----------|----------------|
| **New file (stub)** | File exists but has `throw new Error('not yet implemented')` or placeholder returns | High â€” finish implementation |
| **New file (partial)** | File has some real code + `// TODO` comments | High â€” complete the work |
| **New file (complete)** | File has full implementation, no TODOs | Low â€” may need tests |
| **Modified file (minor)** | < 20 lines changed (bug fix, small refactor) | Low â€” verify tests cover change |
| **Modified file (major)** | â‰¥ 20 lines changed (feature, significant refactor) | Medium â€” ensure stability |
| **Deleted file** | File removed | High â€” verify nothing depends on it |
| **Config change** | package.json, tsconfig, vite.config, tailwind.config | High â€” verify build still passes |

### Step C: Identify Hotspots

A module is a **hotspot** if any of:

- 3+ files in the same directory were modified since last checkpoint
- A single file has > 50 lines of diff
- A file has both new code and TODO/FIXME comments
- A module's tests are failing or missing for modified code
- An API contract changed (function signatures, type exports, interfaces)

**Hotspots get planning priority.** The planner must:
1. List all hotspots
2. For each hotspot, assess: is it stable (builds, tests pass) or unstable?
3. Unstable hotspots â†’ Critical priority
4. Stable hotspots with missing tests â†’ High priority
5. Stable hotspots with full tests â†’ Low priority (monitor)

### Step D: Assess Impact

For each candidate task, assess:

| Factor | Question | Impact |
|--------|----------|--------|
| Diff size | How many lines changed in relevant files? | Large diff = higher risk |
| Files affected | How many files would this task touch? | More files = higher risk |
| API changes | Does this task change exported interfaces? | API change = higher risk |
| Test coverage | Do modified areas have tests? | No tests = higher risk |
| Dependencies | Does this task depend on recently modified modules? | Yes = higher risk |

---

## Planning Priority Shift

Planning priorities MUST shift based on diff analysis:

### When diff shows unstable areas:

1. **CRITICAL**: Stabilize unstable modules (failing build/tests in modified code)
2. **HIGH**: Complete partially implemented files (stubs with TODOs)
3. **HIGH**: Add tests for modified but untested code
4. **MEDIUM**: Continue with next TODO.md task
5. **LOW**: Start new features in untouched areas

### When diff shows stable state:

1. Apply normal PLANNING_ENGINE.md priority resolution
2. But still prefer completing partially modified areas over starting new ones

### When diff shows no changes (fresh start):

1. Apply normal PLANNING_ENGINE.md priority resolution
2. No diff-based priority shifts needed

---

## Size-Based Prioritization

| Diff Size | Risk Level | Planning Action |
|-----------|-----------|-----------------|
| 0 lines (no changes) | None | Normal planning |
| 1-20 lines | Low | Normal planning, verify changes tested |
| 21-100 lines | Medium | Prefer stabilizing modified areas |
| 101-500 lines | High | Mandatory stabilization before new work |
| 500+ lines | Critical | Split into smaller tasks, stabilize first |

---

## Integration with PLANNING_ENGINE.md

Diff-based analysis runs as a **new step** in the planning algorithm:

```
PLANNING_ENGINE.md Step 1: Repository Evaluation
    â†“
PLANNING_ENGINE.md Step 2: Task Discovery
    â†“
PLANNING_ENGINE.md Step 2.5 (NEW): Diff-Based Analysis   â† THIS DOCUMENT
    â†“
PLANNING_ENGINE.md Step 3: Task Classification
    â†“
PLANNING_ENGINE.md Step 4: Priority Resolution (now diff-aware)
    â†“
PLANNING_ENGINE.md Step 5: Task Selection
    â†“
PLANNING_ENGINE.md Step 6: Output
```

---

## Diff-Aware Priority Resolution Rules

These rules supplement (not replace) the existing priority resolution rules in PLANNING_ENGINE.md:

1. **Unstable modified modules are Critical.** If a file was modified since the last checkpoint and its tests fail or it doesn't build, fixing it is the highest priority.

2. **Partially implemented files are High.** If a file was created but has TODOs or stubs, completing it takes priority over starting new work.

3. **Modified but untested code is High.** If a file was modified and has no test coverage for the changes, adding tests is High priority.

4. **Prefer completing partially modified areas.** If a module has 3 of 5 files implemented, finishing the remaining 2 takes priority over starting a new module.

5. **Large diffs increase priority of stabilization.** If the diff since last checkpoint exceeds 100 lines, the planner must prioritize stabilizing existing changes before introducing new ones.

6. **API changes require test verification.** If exported interfaces changed, all dependent modules must be checked for compatibility before new work begins.

---

## Output

Diff-based analysis produces:

1. **Hotspot list** â€” modules/files with significant changes, classified by stability
2. **Risk assessment** â€” overall risk level of current codebase state
3. **Priority adjustments** â€” recommended priority shifts based on diff
4. **Stability report** â€” which modified areas are stable vs unstable

This output feeds directly into PLANNING_ENGINE.md Step 3 (Classification) and Step 4 (Priority Resolution).