# Autonomous Engineer — Portable Redesign

**Date:** 2026-07-02 (revised same day after a "cut the fat" pass)
**Status:** Approved design, ready for implementation planning
**Author:** Oleg Spiridonov (with Claude Code)

---

## The idea, in one paragraph

A folder you drop into any repo. It contains **instructions the AI reads** plus **a thin loop that repeatedly wakes up whatever coding agent you already use** (Claude Code, aider+DeepSeek, OpenClaw, …) and tells it to do one safe unit of work. The framework owns only what a model can't be trusted to do itself — locking, git checkpoints, the on/off switch, and the loop. Everything else is markdown the agent reads. Lightweight, dependency-free, and agent-agnostic by construction.

## Design targets (the three tests every decision is measured against)

1. **Lightweight** — few files, no runtime dependencies, nothing to install.
2. **Easy to integrate into any existing system** — copy a folder, edit two lines, run one command.
3. **Works on top of any agent** — the executor is a command string; no per-tool code.

## Problem with what exists today

The current framework is a strong *governance spec* (git checkpoints, LOCK, control flags, quality gates, failure recovery, diff-aware planning, traceability). But:

1. **No engine.** `agent/run.sh` prints `RUNBOOK_TRIGGERED` and relies on the OpenClaw runtime. It only runs inside OpenClaw; nothing actually calls a model.
2. **Hardcoded to one environment.** `/mnt/c/Users/Oleg/.env.keys.txt`, Windows paths, `npm run build` / `npx tsc` baked in.
3. **Too heavy.** The agent is told to read 32 documents every tick.

## Non-goals

- Building our own agent loop / tool-use / file-editing engine. Raw model APIs can't edit files or run builds; we lean on mature harnesses instead.
- A globally-installed CLI, a package to publish, a GUI, or a hosted service.
- Per-agent adapter code. The command string is the universal adapter.
- Weakening any existing safety guarantee.

---

## Core reframe: two layers, one trust boundary

Separate the **portable spec** (markdown any AI reads) from the **thin executor** (the command that runs a coding agent). The architecture is defined by *what runs where*:

| Runs **outside** the model — `run.sh`, deterministic, trustworthy | Runs **inside** the model — the agent, via `AGENT.md` |
|---|---|
| Acquire LOCK (stale-lock recovery) | Read `STATE.md`, pick exactly **one** task |
| Create pre-cycle git checkpoint | Implement it |
| Check control flag; stop if not `enabled` | Run gates for fast feedback |
| Invoke the executor (the agent) | Update `STATE.md` and `WORKLOG.md` |
| **Re-run the gate commands itself**; on failure roll back to checkpoint and set `CONTROL=failed` | Commit the change |
| Loop | |

The key guarantee: a hallucinating or dishonest agent cannot lie its way past a gate, because `run.sh` re-runs the gates itself and rolls back on failure. That external verification is the whole reason `run.sh` exists.

---

## Files (3 markdown + 1 config + 1 script)

Framework directory `agent/` → `.autoeng/`:

```
your-project/
├── .autoeng/
│   ├── AGENT.md      # immutable rules (top section) + workflow + planning + quality bar + recovery. Read each cycle.
│   ├── STATE.md      # working memory: status, next task, queue, blockers. Rewritten each run.
│   ├── WORKLOG.md    # append-only journal; decisions included as tagged entries.
│   ├── config.sh     # sourced sh: EXECUTOR, GATE_*, CONTROL, timeouts.
│   └── run.sh        # the only script. Subcommands + loop + all safety rails.
└── ...your code
```

Runtime artifacts (`LOCK`, `CHECKPOINT`, `execution.log`) live in `.autoeng/` and are git-ignored.

**Mapping — every existing rule survives, nothing is dropped:**

| New file | Absorbs |
|----------|---------|
| `AGENT.md` | `SYSTEM.md` (as the immutable top section), `AUTONOMOUS_ENGINEER.md`, `RUNBOOK.md`, `PLANNING_ENGINE.md`, `DIFF_PLANNING.md`, `EXECUTION_CYCLE.md`, `EXECUTION_RULES.md`, `TASK_SIZE_POLICY.md`, `QUALITY_GATE.md`, `REVIEW_CHECKLIST.md`, `SELF_REVIEW.md`, `CHECKLIST.md`, `FAILURE_RECOVERY.md`, `GIT_SAFETY.md`, `AUTONOMOUS_CONTROL.md`, `EXECUTION_TIMEOUT.md`, `TERMINATION_POLICY.md`, `FINAL_SHUTDOWN.md`, `SUCCESS_CRITERIA.md` |
| `STATE.md` | `PROJECT_STATUS.md`, `NEXT_TASK.md`, `TASK_QUEUE.md`, `BLOCKERS.md`, `TECH_DEBT.md`, `RISK_REGISTER.md` |
| `WORKLOG.md` | `WORKLOG.md` + `DECISIONS.md` (decisions tagged `[decision]`) |
| `config.sh` | `CONTROL_FLAGS.md` (state), `CRON_SETUP.md` (schedule), all hardcoded commands/paths |
| `run.sh` | `CHECKPOINT_MANAGER.sh`, old `run.sh`, quality-gate execution |

`SYSTEM.md` merges into `AGENT.md` as a clearly-marked immutable top section. Its immutability was always enforced by instruction, never by being a separate file — so a separate file bought nothing.

The agent reads ~3 files per cycle instead of 32.

---

## The executor — "works on top of any agent"

`config.sh`:

```sh
# The command that runs ONE cycle. It is invoked to read .autoeng/AGENT.md,
# perform exactly one engineering objective, then exit.
EXECUTOR="aider --model deepseek/deepseek-chat --yes --message-file .autoeng/AGENT.md"

# Examples (any coding agent works — this string is the only adapter):
#   claude   -> EXECUTOR="claude -p 'Follow .autoeng/AGENT.md and execute one autonomous cycle.'"
#   openclaw -> EXECUTOR="openclaw run --message 'Follow .autoeng/AGENT.md, one cycle.'"

# Quality gates. Blank = skipped (and logged). Auto-filled by `run.sh adopt`.
GATE_BUILD="npm run build"
GATE_LINT="npm run lint"
GATE_TEST="npm test"

# Control: enabled | paused | stop_requested | project_completed | failed
CONTROL="enabled"

# Optional tuning (defaults carried over from the current framework)
LOCK_STALE_MIN=30
CYCLE_TIMEOUT_MIN=15
```

**Executor contract:** invoked with a working directory and an instruction to read `.autoeng/AGENT.md`, the command performs **exactly one** engineering objective and then exits. That is the entire integration surface for a new agent — no adapter code. The three "presets" from the earlier draft become the three commented example strings above; they are documentation, not code that can drift.

---

## `run.sh` — the only script

Subcommands (called by path, e.g. `bash .autoeng/run.sh loop` — nothing to install):

| Command | Behavior |
|---------|----------|
| `run.sh run` | One guarded cycle: control check → LOCK → checkpoint → invoke `$EXECUTOR` → re-run gates → pass: release LOCK; fail: rollback + `CONTROL=failed`. |
| `run.sh loop` | Repeat `run` until `CONTROL != enabled`. The agent sets `CONTROL=project_completed` when it judges SUCCESS criteria met (documented in `AGENT.md`), or `run.sh` sets `failed` on unrecoverable gate failure. This is the long start-to-finish cycle. |
| `run.sh adopt` | Best-effort (~20 lines): detect stack, write `GATE_*` defaults into `config.sh`, seed `STATE.md` from a repo/TODO scan. Convenience only — a user can skip it and fill `config.sh` by hand. |
| `run.sh status` | Print `CONTROL`, last `WORKLOG` entry, gate/build status, LOCK state. |
| `run.sh pause` / `run.sh stop` | Set `CONTROL` in `config.sh`. (Enable = edit the file or `CONTROL=enabled run.sh run`.) |

A cron entry just calls `run.sh run`; the same guards apply, so cron and terminal behave identically.

**Greenfield vs existing is content, not code.** Greenfield: `adopt` (or the user) seeds `STATE.md` with a "Phase 0: bootstrap" task; the agent's first cycles author `docs/ARCHITECTURE.md`, `docs/PLAN.md`, `TODO.md`, then build. Existing: `adopt` detects the stack and seeds `STATE.md` from the repo. Same framework, no special subsystem.

**Stack auto-detection** (best-effort, in `adopt`):

| Detected file | `GATE_*` defaults |
|---------------|-------------------|
| `package.json` | npm scripts (+ `tsc --noEmit` if TS) |
| `Cargo.toml` | `cargo build` / `cargo clippy` / `cargo test` |
| `go.mod` | `go build ./...` / `go vet` / `go test ./...` |
| `pyproject.toml` | `ruff` / `pytest` |

---

## Data flow

```
run.sh loop / cron
   │
   ▼
source config.sh  ──►  CONTROL != enabled ? ──► log + exit
   │
   ├─ LOCK (stale-lock recovery)
   ├─ git checkpoint
   ▼
invoke $EXECUTOR  (any agent, any model)
   │
   ▼
agent: read AGENT.md + STATE.md → one task → implement → gates → update STATE/WORKLOG → commit
   │
   ▼
run.sh re-runs GATE_* itself
   ├─ fail ─► git reset --hard <checkpoint> ─► CONTROL=failed ─► exit
   └─ pass ─► release LOCK ─► loop re-checks CONTROL ─► next / finish
```

## Error handling

Unchanged in substance; relocated into `run.sh` + `AGENT.md`:

- **Checkpoint before every cycle**; `git reset --hard <checkpoint>` is the primary recovery, now enforced by `run.sh` after failed gate verification.
- **LOCK** prevents concurrent runs; stale lock (≥ `LOCK_STALE_MIN`) auto-recovers.
- **Control flag** lets a human pause/stop by editing `config.sh` or `run.sh pause`.
- **Unrecoverable failure** → `CONTROL=failed`, execution suspends for human review.
- **No remote pushes** — agent commits locally only.

## Testing strategy

- **`run.sh`** — against a scratch git-repo fixture: honors `CONTROL`; creates/releases LOCK; recovers stale LOCK; creates a checkpoint; **rolls back when a gate fails**; skips blank gates.
- **Executor contract** — a fake `$EXECUTOR` (a script that edits a file) proves the loop drives it and gate-verify runs afterward, with no real model.
- **`run.sh adopt`** — against fixture repos (Node, Go, empty dir): asserts correct `GATE_*` and `STATE.md` seed.
- **End-to-end smoke** — one real `run.sh run` on a trivial project with a cheap model; assert a commit lands and gates ran. Manual/optional.

## Migration path

1. Author `AGENT.md` (immutable top section from `SYSTEM.md` + merged workflow) and `STATE.md` by merging existing files section-by-section — content deduped, nothing dropped.
2. Extract every hardcoded path/command into `config.sh`; add best-effort detection to `adopt`.
3. Rewrite `run.sh` as the single script (subcommands + safety rails + gate-verify + loop).
4. Rewrite `README.md`; add a 3-command quickstart and a short `MIGRATION.md` for existing `agent/` users.
5. Delete the old 32-file set (git history preserves it). No `profiles/strict/` — that would reintroduce the weight we just removed.

## What changed from the first draft (the "cut the fat" pass)

| Cut / changed | Reason |
|---|---|
| `ae` global CLI → subcommands of `run.sh` | A CLI needs an install/PATH story, which fights "easy to integrate." Called-by-path = zero install. |
| Preset adapters as shell code → 3 example command strings | The command string is the universal adapter; per-tool code drifts and contradicts "any agent." |
| `config.yml` → `config.sh` | YAML needs a parser; sourced sh is zero-dependency and runs anywhere. |
| Separate `CONSTITUTION.md` → top section of `AGENT.md` | Immutability is enforced by instruction, not by file separation. |
| Separate `DECISIONS.md` → tagged `WORKLOG.md` entries | A decision is a kind of journal entry. |
| `lib/` + `quality-gate.sh` → folded into `run.sh` | One script is lighter and makes the trust boundary explicit. |
| `init`/`adopt` as subsystems → content + a ~20-line detect | Greenfield vs existing is a content difference, not code. |
| 5 files → 3 md + config + script | Further consolidation toward "lightweight." |

## Open items for planning

- Exact stale-lock threshold / cycle timeout: carry over current values (30 min / 15 min) via `config.sh`, revisit if needed.
- Whether `run.sh adopt` should prompt-confirm detected gates or write silently (lean: write, then print what it wrote).
