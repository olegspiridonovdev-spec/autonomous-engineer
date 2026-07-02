# Migrating from the old `agent/` framework

The old 32-file `agent/` folder has been replaced by a six-file `.autoeng/` folder. This guide maps the old files to the new ones and walks through migrating an existing project.

## Why

The old framework spread state, rules, and control flags across ~20 markdown files plus a couple of shell scripts, assumed OpenClaw + cron, and had no independent verification of gate results. `.autoeng/` collapses all of that into one operating manual, one state file, one worklog, one config, and one driver script — and the driver (`run.sh`) re-runs quality gates itself rather than trusting the agent's report.

## File mapping

| Old (`agent/`) | New (`.autoeng/`) |
|---|---|
| `SYSTEM.md`, `AUTONOMOUS_ENGINEER.md`, `RUNBOOK.md`, `AUTONOMOUS_CONTROL.md`, `PLANNING_ENGINE.md`, `EXECUTION_CYCLE.md`, `EXECUTION_RULES.md`, `EXECUTION_TIMEOUT.md`, `TASK_SIZE_POLICY.md`, `QUALITY_GATE.md`, `REVIEW_CHECKLIST.md`, `SELF_REVIEW.md`, `CHECKLIST.md`, `FAILURE_RECOVERY.md`, `GIT_SAFETY.md`, `DIFF_PLANNING.md`, `TERMINATION_POLICY.md`, `SUCCESS_CRITERIA.md`, `FINAL_SHUTDOWN.md` | `AGENT.md` (single operating manual the agent reads each cycle) |
| `PROJECT_STATUS.md`, `NEXT_TASK.md`, `TASK_QUEUE.md`, `BLOCKERS.md`, `TECH_DEBT.md`, `RISK_REGISTER.md` | `STATE.md` (working memory, rewritten each cycle) |
| `WORKLOG.md`, `DECISIONS.md` | `WORKLOG.md` (append-only; tag architectural decisions with `[decision]` inline) |
| `CONTROL_FLAGS.md` (`ENABLED`/`PAUSED`/`STOP_REQUESTED`/`FAILED`) | `CONTROL` variable in `config.sh` (`enabled`/`paused`/`stop_requested`/`project_completed`/`failed`) |
| `CRON_SETUP.md` (OpenClaw cron config) | `sh .autoeng/run.sh loop`, or point cron at `sh .autoeng/run.sh run` for one guarded cycle per tick |
| `CHECKPOINT_MANAGER.sh` + `run.sh` | `run.sh` (checkpoint, lock, gate re-run, rollback, and loop all in one script) |

Quality gate commands that used to live in `QUALITY_GATE.md` now live as `GATE_BUILD`/`GATE_LINT`/`GATE_TEST` in `config.sh` — either set them by hand or run `sh .autoeng/run.sh adopt` to auto-detect them from your stack.

## Migration steps

1. Install the new framework alongside the old one:
   ```bash
   sh install.sh .
   ```
2. Auto-detect your stack and seed `STATE.md`:
   ```bash
   sh .autoeng/run.sh adopt
   ```
   This fills in `GATE_BUILD`/`GATE_LINT`/`GATE_TEST` based on `package.json`/`Cargo.toml`/`go.mod`/`pyproject.toml` and writes a fresh `STATE.md`.
3. Port your mission into `AGENT.md` §2 — carry over the intent from the old `AUTONOMOUS_ENGINEER.md` / `SUCCESS_CRITERIA.md` (what the project is, who it's for, what "done" looks like).
4. If you have an active task queue, blockers, or tech debt worth keeping, copy the relevant bullets from `PROJECT_STATUS.md` / `TASK_QUEUE.md` / `BLOCKERS.md` / `TECH_DEBT.md` / `RISK_REGISTER.md` into the corresponding sections of the new `STATE.md`.
5. Set `EXECUTOR` and `CONTROL="enabled"` in `.autoeng/config.sh`.
6. Delete the old `agent/` folder:
   ```bash
   rm -rf agent/
   ```
7. Start the loop:
   ```bash
   sh .autoeng/run.sh loop
   ```

## Notes

- If you had a cron job pointed at the old `agent/run.sh` or `agent/CHECKPOINT_MANAGER.sh`, repoint it at `.autoeng/run.sh run` (one guarded cycle per invocation) or replace it entirely with a long-running `.autoeng/run.sh loop`.
- The old framework assumed OpenClaw specifically. The new `EXECUTOR` is just a command string — OpenClaw still works as one example, but so does `aider`, `claude`, or any other coding-agent CLI (see the README's "Configuring the executor" section).
- `.autoeng/CHECKPOINT`, `.autoeng/LOCK`, and `.autoeng/execution.log` are runtime artifacts (already git-ignored) — no need to migrate anything from the old `CHECKPOINT` file.
