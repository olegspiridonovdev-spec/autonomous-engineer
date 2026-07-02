# Autonomous Engineer v2 — Role Pipeline & Semantic Gates

**Date:** 2026-07-02
**Status:** Design sketch — not yet planned or built. Successor to the v1 portable redesign (now on `main`).
**Author:** Oleg Spiridonov (with Claude Code)
**Predecessor:** [2026-07-02-autonomous-engineer-portable-redesign-design.md](2026-07-02-autonomous-engineer-portable-redesign-design.md)

---

## The idea, in one paragraph

v1 proved the hard part: a dumb, deterministic shell harness that owns the safety rails (lock, checkpoint, gate re-run, rollback, land-on-success) and never trusts model output. But v1's *loop* is a single monolithic agent that plans, implements, and self-checks in one call, verified only by mechanical `build/lint/test` gates. v2 keeps the safety core **byte-for-byte** and rebuilds only the intelligence of the loop: the harness orchestrates a small **pipeline of specialized agent roles** (plan → implement → review) and the acceptance gate becomes a **semantic contract** (mechanical gates AND new-tests-present AND optional behavioral check AND an adversarial reviewer verdict). It is the multi-agent review process used to *build* v1, baked into how v1 *runs*.

## Motivation — what v1 can't do

1. **Verification is shallow.** `build + lint + test` catches broken code, not wrong-but-compiling code, missing requirements, or regressions in untested areas. The entire trust boundary is only as strong as the gates, and mechanical gates cannot judge *correctness*.
2. **The loop wanders.** Planning is implicit inside each cycle, so a confident agent can build many cycles in a slightly-wrong direction with nothing re-checking against the original goal.
3. **"One task" is a hope, not a contract.** v1 tells the agent "read state and pick one objective"; nothing enforces scope, and each cold-start re-reads everything.
4. **No behavioral feedback.** The agent never observes the running artifact — only that it compiles and tests pass.

## Goals

- Keep every v1 property: lightweight, dependency-free, drops into any repo, drives any coding agent, deterministic safety core.
- Make verification **semantic and adversarial**, not just mechanical.
- Make cycles **deterministically scoped** (harness hands in one task) and **coherent over long horizons** (periodic replanning, milestone human checkpoints).
- Remain a **strict superset of v1**: with review off and a single executor, v2 behaves exactly like v1. You opt into the pipeline.

## Non-goals

- Moving intelligence into the harness. The harness stays a dumb `sh` script that sequences role calls and checks exit codes / one verdict line. All reasoning lives in prompts.
- Parallelism (concurrent modules/worktrees), a structured-DB state model, or a plugin system. Deferred until a single-track v2 is proven.
- Replacing the safety core. Lock/checkpoint/rollback+clean/land/control/git-preflight/EXIT-trap are reused unchanged.

---

## Core reframe: pipeline of roles, evaluated by a semantic gate

**v1 cycle:** `harness → one executor (plan+implement+self-check) → mechanical gates → commit/rollback`

**v2 cycle:** `harness → plan → implement → mechanical gates → new-tests check → behavioral gate → reviewer verdict → accept & land, or reject & repair, or rollback & fail`

The safety core is unchanged; what expands is the middle: one executor call becomes a short, harness-sequenced pipeline, and the gate becomes a contract.

### 1. Roles as executors (generalizing v1's `EXECUTOR`)

Three optional command strings in `config.sh`, each of which may point at a different model/provider — the concrete payoff of "any AI":

```sh
# Each role falls back to $EXECUTOR when unset, so v2 degrades to v1.
EXECUTOR=""                    # fallback for any unset role (v1 compatibility)
EXECUTOR_PLAN=""               # e.g. a strong model — turns GOAL+STATE into ONE next task
EXECUTOR_IMPL=""               # e.g. a cheap/fast model — implements the handed-in task
EXECUTOR_REVIEW=""             # e.g. a strong, skeptical model — adversarial verdict
```

- **Planner** — reads the project GOAL (AGENT.md §Mission), `STATE.md`, and a repo scan → writes exactly **one** concrete task to `TASK.md`. May flag a phase boundary for human review or request a replan.
- **Implementer** — is handed `TASK.md` explicitly → implements it, writes/updates tests, runs gates for fast local feedback, commits.
- **Reviewer** — reads the diff (`git diff <checkpoint>..HEAD`) + `TASK.md` → adversarial verdict against the task's acceptance criteria.

Each role follows a dedicated section of `AGENT.md` (§PLAN / §IMPLEMENT / §REVIEW) under the shared constitution + mission — still one manual file.

### 2. The task handoff — deterministic scoping

The planner writes a single structured task file the harness passes to the implementer and reviewer:

```markdown
# TASK.md  (planner writes; implementer + reviewer read)
id: 2026-07-02-003
title: <one sentence>
rationale: <why this is the highest-value next step>
files-likely: <paths the change probably touches>
size: S | M | L
acceptance:
- [ ] <concrete, checkable criterion>
- [ ] <...>
checkpoint: none | human      # human ⇒ pause after this task for review
```

Because the harness hands `TASK.md` in, "one objective" is enforced by the *input*, not by hope; each role reads less; and the reviewer has explicit criteria to judge against.

### 3. The semantic gate contract

A cycle's change is **ACCEPTED iff every configured check passes**, all evaluated by the harness:

| # | Check | Enforced by | Config |
|---|-------|-------------|--------|
| 1 | build / lint / test pass | mechanical (v1) | `GATE_BUILD` / `GATE_LINT` / `GATE_TEST` |
| 2 | new tests present when source changed | sh heuristic on the diff | `REQUIRE_NEW_TESTS=on\|off` |
| 3 | the artifact behaves | a command that exercises it (curl/CLI/smoke) | `GATE_BEHAVIOR` (blank = skip) |
| 4 | reviewer verdict = accept | adversarial agent | `REVIEW=on\|off` |

Two invariants:

- **Reviewer is ANDed with the mechanical floor, never ORed.** A reviewer "accept" can never rescue a failing build/test. The model can only make acceptance *stricter*. This keeps a deterministic hard floor beneath the model judgment.
- **`REQUIRE_NEW_TESTS` is pure sh, zero model cost** — if the diff touches a source path, it must also touch a test path (configurable path globs). Closes the "gates green but nothing new tested" gap.

**Verdict mechanism (how a dumb harness reads a model's judgment):** the reviewer writes `.autoeng/REVIEW.md` whose last line is machine-readable — `VERDICT: accept` or `VERDICT: reject` — plus prose reasons above it. The harness greps the last `VERDICT:` line. No JSON parsing in sh.

### 4. The repair loop

On `VERDICT: reject`, the harness appends the reviewer's reasons to `TASK.md` and re-invokes the implementer, up to `REVIEW_RETRIES` times, re-gating each attempt. Still rejected after the budget → roll back to the checkpoint and set `CONTROL=failed`. This is adversarial-verify-then-repair, bounded, as a runtime behavior.

---

## Harness orchestration (still dumb sh)

`run.sh`'s `cmd_run` expands; everything marked (v1) is reused unchanged:

```
cmd_run():
  cd PROJECT_ROOT; load_config                                        # (v1)
  CONTROL == enabled ? else skip                                      # (v1)
  git preflight (is-inside-work-tree) else fail                       # (v1)
  lock_acquire || return 0 ; trap lock_release EXIT                   # (v1)
  checkpoint_create                                                   # (v1)

  [ -s TASK.md ] || run_role PLAN            # plan only if no task pending
  run_role IMPL   (TASK.md handed in)

  attempt = 0
  loop:
    run_gates (build/lint/test)      || { rollback; set_control failed; fail }   # (v1 core)
    require_new_tests                || { rollback; set_control failed; fail }
    behavior_gate (if GATE_BEHAVIOR) || { rollback; set_control failed; fail }
    if REVIEW == on:
        run_role REVIEW ; verdict = grep_last VERDICT REVIEW.md
        if verdict == reject:
            attempt++; [ attempt -le REVIEW_RETRIES ] || { rollback; set_control failed; fail }
            append reasons to TASK.md ; run_role IMPL ; continue loop
    break                                                             # all checks passed

  land uncommitted validated work                                     # (v1)
  clear TASK.md ; update STATE ; append events ; release lock         # (v1 + new events)
  if TASK.checkpoint == human: set_control paused ; log "review requested"
```

`run_role NAME` resolves `EXECUTOR_<NAME>` (falling back to `$EXECUTOR`), logs it, and runs it via `sh -c`, exactly like v1's `invoke_executor`. The harness never parses model output beyond the one `VERDICT:` line and process exit codes.

## Long-horizon coherence

- **Replan.** Every `REPLAN_EVERY` cycles, or after `REPLAN_AFTER_REJECTS` consecutive failed cycles, the planner runs in replan mode: re-derive the roadmap in `STATE.md` from GOAL vs. current reality, rather than only picking the next task.
- **Milestone human checkpoints.** A task's `checkpoint: human` flag makes the harness set `CONTROL=paused` after acceptance and log a review request — bounding how far a confident-but-wrong direction can run before a human sees it.
- **Backstops.** `MAX_CYCLES` per run (trivially enforced in sh) is a hard loop cap. `BUDGET` is best-effort: role wrappers append per-call usage (when the underlying harness reports it) to `.autoeng/COST`; the loop stops when exceeded. `MAX_CYCLES` is the reliable guard; token budgets are harness-dependent.
- **Observability.** Alongside the human `WORKLOG.md`, append `.autoeng/events.jsonl` — one line per phase: `{cycle, role, task_id, gate, verdict, duration_s}` — so a long run can be watched, debugged, and measured (progress per cycle / per dollar).

---

## Files: reuse vs. new

```
.autoeng/
  AGENT.md        # shared constitution + mission + role sections §PLAN / §IMPLEMENT / §REVIEW   (extended)
  STATE.md        # roadmap + status (planner-owned)                                             (v1 shape)
  TASK.md         # the current single task — planner writes, impl+review read                   (NEW)
  REVIEW.md       # last reviewer verdict (+ reasons); harness greps VERDICT:                     (NEW)
  WORKLOG.md      # append-only human journal                                                     (v1)
  events.jsonl    # structured per-phase events (git-ignored)                                     (NEW)
  COST            # best-effort accumulated usage (git-ignored)                                   (NEW)
  config.sh       # + EXECUTOR_PLAN/IMPL/REVIEW, GATE_BEHAVIOR, REVIEW, REQUIRE_NEW_TESTS,
  #                 TEST_PATH_GLOB, REVIEW_RETRIES, REPLAN_EVERY, REPLAN_AFTER_REJECTS, MAX_CYCLES (extended)
  .gitignore      # + REVIEW.md?, TASK.md?, events.jsonl, COST   (decide: keep TASK/REVIEW tracked for audit)
  run.sh          # safety core unchanged; cmd_run expands to the pipeline above                  (extended)
```

| Reused verbatim from v1 (`main`) | New / extended in v2 |
|---|---|
| lock / checkpoint / rollback+clean / land-on-success | `TASK.md` handoff, `REVIEW.md` verdict, `run_role` dispatch |
| control flag, git preflight + EXIT trap | three role sections in `AGENT.md`; role config keys |
| `install.sh`, whole plain-shell test-harness pattern | `require_new_tests` (sh), `GATE_BEHAVIOR`, repair loop |
| `config.sh` shape, `run.sh` dispatch + subcommands | replan trigger, human-checkpoint flag, `events.jsonl`, `MAX_CYCLES`, best-effort `COST` |

## The degradation property (keeps it honest)

With `REVIEW=off`, `REQUIRE_NEW_TESTS=off`, `GATE_BEHAVIOR=""`, and only `$EXECUTOR` set (no role overrides), the pipeline collapses to exactly v1: one agent, mechanical gates. v2 is a strict superset — lightweight by default, verification scaled up only when a project warrants it.

## Data flow

```
run.sh loop / cron
  │  (v1 safety preamble: control → git preflight → lock → trap → checkpoint)
  ▼
PLAN role  ──► TASK.md (one scoped task, acceptance criteria)      [skipped if TASK.md pending]
  ▼
IMPL role  ──► edits + tests + commit, handed TASK.md
  ▼
harness gate contract:
   build/lint/test ─ fail ─► rollback + CONTROL=failed
   new-tests       ─ fail ─► rollback + CONTROL=failed
   behavior        ─ fail ─► rollback + CONTROL=failed
   REVIEW role ─ reject ─► append reasons → IMPL (≤ REVIEW_RETRIES) → re-gate
                └ accept ─► land → clear TASK.md → update STATE → events → release lock
  ▼
TASK.checkpoint == human ? ─► CONTROL=paused (review requested)
  ▼
loop: replan every N cycles; stop at MAX_CYCLES / BUDGET / CONTROL != enabled
```

## Error handling

Unchanged safety semantics, extended surface:
- Any gate failure (mechanical, new-tests, behavioral) or exhausted review retries → `git reset --hard` + `git clean -fd` to the checkpoint, `CONTROL=failed`, lock released (v1 guarantees, including the EXIT trap).
- Reviewer verdict can only *withhold* acceptance; it can never override a failing mechanical gate.
- A role invocation that errors (non-zero exit) is treated like an executor error in v1: rollback + fail.
- No remote pushes; every change reversible via checkpoint.

## Testing strategy

Reuses v1's dependency-free plain-shell harness with fake role executors:
- **Role dispatch** — `run_role` resolves `EXECUTOR_<ROLE>` with fallback to `$EXECUTOR`; verify command selection without real models.
- **Gate contract** — fake IMPL that (a) passes everything, (b) skips new tests, (c) breaks the behavioral gate, (d) draws a `reject`; assert accept only when all configured checks pass; assert reviewer-accept cannot rescue a failing build.
- **Repair loop** — fake REVIEW that rejects N−1 times then accepts; assert bounded retries and that reasons reach `TASK.md`; assert exhaustion → rollback + failed.
- **Verdict parsing** — `REVIEW.md` with multiple/ambiguous lines; assert the harness reads the *last* `VERDICT:` and defaults to reject when absent.
- **Task handoff** — planner writes `TASK.md`; assert the implementer is handed it and the harness clears it on acceptance.
- **Long-horizon** — replan fires at `REPLAN_EVERY`; `MAX_CYCLES` caps the loop; `checkpoint: human` pauses control.
- **Degradation** — with review off and one executor, behavior is identical to v1's `test_run_happy` / `test_gate_rollback`.
- **End-to-end smoke** — a trivial three-role pipeline (echo-planner, edit-implementer, always-accept-reviewer) drives one real cycle to a landed commit.

## How to build it (if approved)

Mirror v1's flow: this spec → a TDD implementation plan → subagent-driven execution with two-stage review. Most safety-core tasks are "reuse, don't rewrite." Suggested task spine:
1. Extend `config.sh` (role + gate + governance keys) and `AGENT.md` (role sections).
2. `run_role` dispatch + fake role executors in the test harness.
3. `TASK.md` handoff (planner writes / harness hands in / clears on accept).
4. Gate contract: `require_new_tests`, `GATE_BEHAVIOR`, wired into `cmd_run`.
5. Reviewer verdict + repair loop.
6. Replan trigger, human checkpoint, `MAX_CYCLES`, `events.jsonl`.
7. Docs (README pipeline section, config reference), full suite + shellcheck + smoke.

## Rejected / deferred alternatives

- **Smart harness (parse structured model output, plan in-process).** Rejected: it would move intelligence into the harness and require a runtime/deps, breaking the "dumb, portable core" invariant. Roles shell out instead.
- **Parallel multi-track execution (worktrees).** Deferred: real coordination/merge complexity, cuts against lightweight; prove single-track first. The state model should not *preclude* it later.
- **Structured DB / strict schema for state.** Deferred: markdown stays human-readable; `TASK.md` gets just enough structure for the harness to hand off and the reviewer to judge.

## Open questions for planning

- Track `TASK.md` / `REVIEW.md` in git for audit, or gitignore them as ephemeral? (Leaning: track `TASK.md` history via WORKLOG summaries; keep `REVIEW.md` ephemeral.)
- Should the reviewer see the diff only, or also run the gates itself? (Leaning: harness runs mechanical gates; reviewer judges intent/completeness/tests — avoid duplicated cost.)
- Cost accounting is harness-dependent; is `MAX_CYCLES` a sufficient v2 backstop, with token budgets as a later, adapter-specific feature? (Leaning: yes.)
- Default `REVIEW_RETRIES` and `REPLAN_EVERY` values — carry conservative defaults (e.g. 1 and 5) pending real-run tuning.
