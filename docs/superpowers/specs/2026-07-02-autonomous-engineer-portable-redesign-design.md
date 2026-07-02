# Autonomous Engineer — Portable Redesign

**Date:** 2026-07-02
**Status:** Approved design, ready for implementation planning
**Author:** Oleg Spiridonov (with Claude Code)

---

## Problem

The current framework is a strong *governance spec* — git checkpoints, LOCK, control flags, quality gates, failure recovery, diff-aware planning, and full traceability are well designed. But three things block the goal of *"drop into any project, drive it with any AI system, run a long autonomous cycle from start to finish."*

1. **No engine.** `agent/run.sh` doesn't invoke a model — it prints `RUNBOOK_TRIGGERED` and depends on the OpenClaw runtime to pick it up. It only runs inside OpenClaw. "Plug in Claude or DeepSeek" is impossible today because nothing calls a model.
2. **Hardcoded to one environment.** `/mnt/c/Users/Oleg/.env.keys.txt`, Windows paths, and `npm run build` / `npx tsc` are baked in. Not portable across projects or stacks.
3. **Too heavy.** The agent is instructed to read 32 documents every tick — expensive in tokens and a wall of complexity for a new adopter.

## Goal

A framework a user can drop into **any** project (greenfield or existing), point at **any** AI system (Claude, DeepSeek, OpenAI, Ollama, …), and let it run a **long autonomous cycle** — preserving the existing safety/governance model while cutting complexity.

## Non-Goals

- Building our own agent loop / tool-use / file-editing engine (raw model APIs can't edit files or run builds on their own). We deliberately lean on mature harnesses instead.
- Rewriting or weakening any existing safety guarantee.
- Language/stack-specific tooling beyond auto-detecting common gates.
- A GUI, dashboard, or hosted service. State stays file-based and in-repo.

---

## Core Reframe: Two Layers

The single idea behind the whole redesign: separate the **portable spec** from the **thin executor**.

| Layer | What it is | Model-aware? |
|-------|-----------|--------------|
| **Spec** | Governance + workflow as markdown any AI reads | No — fully portable |
| **Executor** | Config + adapter turning "run one cycle" into a concrete command for the chosen harness/model | Yes — the only model-aware part |

Everything below follows from this split.

---

## Design

### 1. File consolidation: 32 → ~5 + config

New layout (framework directory renamed `agent/` → `.autoeng/`):

```
your-project/
├── .autoeng/
│   ├── CONSTITUTION.md   # immutable core rules + governance. ~1 page. The one file the agent may never edit. (was SYSTEM.md, trimmed)
│   ├── AGENT.md          # operating manual: startup, planning, execution cycle, quality gate, self-review, failure recovery, termination. Merges ~12 files.
│   ├── STATE.md          # mutable dashboard, updated every run: status + next task + queue + blockers + tech-debt + risks.
│   ├── WORKLOG.md        # append-only journal (separate — it grows).
│   ├── DECISIONS.md      # append-only decision log (separate — it grows).
│   ├── config.yml        # the ONLY file a user must edit.
│   └── lib/
│       ├── checkpoint.sh
│       ├── quality-gate.sh
│       └── run.sh        # portable loop driver
└── ...your code
```

**Mapping — every existing rule survives, nothing is dropped:**

| New file | Absorbs |
|----------|---------|
| `CONSTITUTION.md` | `SYSTEM.md` (core principles, governance rules, authority hierarchy, control guarantees) |
| `AGENT.md` | `AUTONOMOUS_ENGINEER.md`, `RUNBOOK.md`, `PLANNING_ENGINE.md`, `DIFF_PLANNING.md`, `EXECUTION_CYCLE.md`, `EXECUTION_RULES.md`, `TASK_SIZE_POLICY.md`, `QUALITY_GATE.md`, `REVIEW_CHECKLIST.md`, `SELF_REVIEW.md`, `CHECKLIST.md`, `FAILURE_RECOVERY.md`, `GIT_SAFETY.md`, `AUTONOMOUS_CONTROL.md`, `EXECUTION_TIMEOUT.md`, `TERMINATION_POLICY.md`, `FINAL_SHUTDOWN.md`, `SUCCESS_CRITERIA.md` |
| `STATE.md` | `PROJECT_STATUS.md`, `NEXT_TASK.md`, `TASK_QUEUE.md`, `BLOCKERS.md`, `TECH_DEBT.md`, `RISK_REGISTER.md` |
| `WORKLOG.md` | `WORKLOG.md` (unchanged, append-only) |
| `DECISIONS.md` | `DECISIONS.md` (unchanged, append-only) |
| `config.yml` | `CONTROL_FLAGS.md` (state), `CRON_SETUP.md` (schedule), all hardcoded commands/paths |
| `lib/` | `CHECKPOINT_MANAGER.sh`, `run.sh`, quality-gate commands |

`CONSTITUTION.md` stays separate on purpose: "the agent must never edit its own constitution" is a property worth one dedicated, short, unambiguous file.

Result: the agent reads ~5 files per tick instead of 32. Content is deduped and authored, not concatenated.

### 2. The engine — "connect any AI system"

`config.yml` carries an `executor` block. `lib/run.sh` builds the invocation from it.

```yaml
executor:
  preset: aider              # aider | claude-code | openclaw | custom
  model: deepseek/deepseek-chat
  # custom escape hatch (used when preset: custom):
  # command: "claude -p 'Follow .autoeng/AGENT.md and execute one autonomous cycle.'"
```

**Preset adapters shipped first: `aider`, `claude-code`, `openclaw`.**

Each preset is a small shell function that renders the harness command from `model` + a fixed instruction ("read `.autoeng/AGENT.md`, execute exactly one cycle, then exit"). `aider` is the highest-leverage preset because it already speaks Claude, DeepSeek, OpenAI, and Ollama through one adapter — that single preset delivers most of "any AI system." `claude-code` covers native Claude usage; `openclaw` preserves the current runtime so nothing regresses. Additional presets (cursor-agent, etc.) and the raw `command:` escape hatch cover everything else.

**Contract every executor must satisfy:** given a working directory and the instruction to read `.autoeng/AGENT.md`, it performs **exactly one** engineering objective (the cycle in AGENT.md), then exits. The framework — not the harness — owns the loop, the locking, the checkpointing, and the control-flag gating.

### 3. The loop driver

`lib/run.sh` is portable and scheduler-independent:

| Invocation | Behavior |
|-----------|----------|
| `run.sh once` | One guarded cycle: check control flag → check/refresh LOCK → git checkpoint → invoke executor → release LOCK. |
| `run.sh loop` | Repeat `once` until the control flag ≠ `enabled`. The loop only reads the flag; the *agent* sets `control: project_completed` when it judges SUCCESS_CRITERIA met (or `failed` on unrecoverable failure), which ends the loop. This is the "long cycle, start to finish." |
| cron entry | Calls `run.sh once`; identical guards. |

Because the loop lives in the framework, it behaves identically whether the user has cron, a bare terminal, or OpenClaw. All the safety machinery (LOCK, checkpoint, stale-lock recovery, control-flag checks) runs in `run.sh` regardless of executor.

### 4. Two on-ramps — one tiny CLI

A single POSIX-sh `ae` command (no node/npm dependency → maximally portable):

| Command | Behavior |
|---------|----------|
| `ae init` | Greenfield. User supplies a one-paragraph goal. Seeds `config.yml` and `STATE.md` with a "Phase 0: bootstrap" objective. The agent's first cycles author `docs/ARCHITECTURE.md`, `docs/PLAN.md`, `TODO.md`, then begin building. |
| `ae adopt` | Existing repo. Auto-detects the stack, fills `config.yml` gates, seeds `STATE.md` from a repo + TODO scan. |
| `ae run` | Alias for `lib/run.sh once`. |
| `ae loop` | Alias for `lib/run.sh loop`. |
| `ae status` | Prints control state, last worklog entry, build status, lock state. |
| `ae enable` / `ae pause` / `ae stop` | Flip the control flag in `config.yml`. |

`setup.sh` is replaced/absorbed by `ae init` and `ae adopt`.

### 5. Stack-agnostic quality gates

`config.yml`:

```yaml
gates:
  build:     "npm run build"     # auto-filled by init/adopt; blank = skip (logged)
  lint:      "npm run lint"
  typecheck: "npx tsc --noEmit"
  test:      "npm test"
```

`lib/quality-gate.sh` runs whatever is configured; a blank value is skipped and logged. Auto-detection on `init`/`adopt`:

| Detected file | Gates |
|---------------|-------|
| `package.json` | npm scripts + `tsc` if TS present |
| `Cargo.toml` | `cargo build` / `cargo clippy` / `cargo test` |
| `go.mod` | `go build ./...` / `go vet` / `go test ./...` |
| `pyproject.toml` | `ruff` / `mypy` / `pytest` |

`AGENT.md` references "the gates in `config.yml`," never literal commands.

### 6. Control state moves into config

`CONTROL_FLAGS.md` becomes a `control:` key in `config.yml` (`enabled | paused | stop_requested | project_completed | failed`), edited by `ae enable|pause|stop` or by hand. Semantics are unchanged from `AUTONOMOUS_CONTROL.md`; they are documented in `AGENT.md`. Runtime artifacts (`LOCK`, `CHECKPOINT`, `execution.log`) remain files in `.autoeng/` and are git-ignored.

---

## Data Flow

```
ae loop / cron
   │
   ▼
lib/run.sh  ──►  read config.yml (control?, executor, gates)
   │                 │
   │                 ├─ control ≠ enabled ─► log + exit
   │                 ▼
   ├─ LOCK check (stale-lock recovery)
   ├─ git checkpoint (lib/checkpoint.sh)
   ▼
invoke executor (preset → harness command, any model)
   │
   ▼
agent reads CONSTITUTION.md + AGENT.md + STATE.md
   │
   ▼
one objective: plan → implement → lib/quality-gate.sh → self-review → commit
   │
   ├─ gates fail ─► FAILURE_RECOVERY (rollback to checkpoint) ─► update STATE/WORKLOG
   └─ gates pass ─► update STATE.md, WORKLOG.md, DECISIONS.md ─► git commit
   │
   ▼
release LOCK ─► run.sh loop: re-check control → next, or finish
```

## Error Handling

Unchanged in substance from today, relocated:

- **Git checkpoint before every cycle** — rollback via `git reset --hard <checkpoint>` is the primary recovery. (`lib/checkpoint.sh`, rules in `AGENT.md`.)
- **LOCK** prevents concurrent runs; stale-lock (≥30 min) auto-recovers. (`lib/run.sh`.)
- **Control flag** — human can pause/stop by editing `config.yml` or running `ae pause`.
- **Failure recovery** — 3 consecutive unrecoverable failures on a task → `control: failed`, execution suspends for human review.
- **No remote pushes** — agent commits locally only.

## Testing Strategy

- **`lib/*.sh`** — unit-test with a scratch git repo fixture: checkpoint creates a baseline commit; run.sh honors control flag, creates/releases LOCK, recovers stale LOCK; quality-gate runs configured commands and skips blanks.
- **Executor presets** — test command rendering (preset + model → expected command string) without invoking real models.
- **`ae init` / `ae adopt`** — run against throwaway fixture repos (a Node repo, a Go repo, an empty dir); assert `config.yml` gates and `STATE.md` seed are correct.
- **End-to-end smoke** — one real `run.sh once` against a trivial fixture project using a cheap model, asserting a commit lands and gates ran. Manual/optional in CI.

---

## Migration Path

Governance is preserved, not rewritten:

1. Author `CONSTITUTION.md` + `AGENT.md` by merging existing files section-by-section (content deduped, nothing dropped).
2. Extract every hardcoded path/command into `config.yml`; add auto-detection.
3. Write the `ae` CLI + `lib/` scripts (POSIX sh).
4. Write the `aider`, `claude-code`, `openclaw` preset adapters + `custom` escape hatch.
5. Rewrite `README.md`; add a short `MIGRATION.md` for existing `agent/` users.
6. (Optional) Keep the old 32-file set under `profiles/strict/` as a reference profile.

## Rejected Alternatives

- **Build a standalone runner** (own agent loop + tool-use + API adapters). Rejected: reinvents Claude Code / aider; large surface to build and maintain. (User confirmed harness-adapter approach.)
- **Keep all 32 files, add a runner layer on top.** Rejected: doesn't cut token cost or new-user complexity. (User confirmed consolidation.)
- **Index file the agent reads first, keeping per-concern files.** Rejected: agent still reads them all (no token saving) and the wall of files remains.

## Open Questions

- Config format: `config.yml` assumes a YAML parser is available. If we want *zero* dependencies, a `config.sh` (sourced env vars) is an alternative — decide during planning. Leaning YAML for readability, with a tiny pure-sh parser or `yq`-optional fallback.
- Exact stale-lock threshold and per-cycle timeout defaults — carry over current values (30 min lock, 15 min cycle) unless revisited.
