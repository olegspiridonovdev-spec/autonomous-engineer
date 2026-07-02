# Autonomous Engineer

A lightweight, dependency-free autonomous-engineering loop that drops into any repo and drives any coding agent.

## What it is

`autonomous-engineer` is a single folder (`.autoeng/`) you copy into a project. It repeatedly invokes a coding-agent CLI of your choice to plan and implement one task at a time, while a small shell driver — outside the model — owns safety: git checkpoints, gate verification, and rollback. There's no server, no database, and no language runtime required by the framework itself.

## Quickstart

```bash
sh install.sh /path/to/your/project                      # 1. copy .autoeng/ in
$EDITOR /path/to/your/project/.autoeng/config.sh          # 2. set EXECUTOR + CONTROL=enabled
cd /path/to/your/project && sh .autoeng/run.sh adopt && sh .autoeng/run.sh loop   # 3. detect stack + run
```

Nothing to install on `PATH` — everything is called by path (`sh .autoeng/run.sh ...`).

## How it works

Each cycle is split across a hard trust boundary: `run.sh` is a plain shell script that never trusts model output, and the executor (your coding agent) does the actual engineering work.

| `run.sh` does (outside the model) | The agent does (inside `$EXECUTOR`) |
|---|---|
| Check `CONTROL` is `enabled` | Read `.autoeng/AGENT.md` for the operating manual |
| Acquire `LOCK` (stale locks auto-recover) | Plan exactly one task |
| Create a git checkpoint | Implement it |
| Invoke `$EXECUTOR` | Run the quality gates itself |
| Re-run `GATE_BUILD` / `GATE_LINT` / `GATE_TEST` independently | Commit the result |
| On executor error or gate failure: `git reset --hard` + `git clean -fd`, set `CONTROL=failed` | |
| On success: land any remaining validated work, release `LOCK` | |
| Repeat (`loop`) while `CONTROL=enabled` | |

The agent never has to be trusted to gate its own work — `run.sh` re-checks everything before letting a cycle stand.

## Configuring the executor (any agent)

`EXECUTOR` in `.autoeng/config.sh` is the only adapter. It's a plain command string, invoked from the project root, that should read `.autoeng/AGENT.md`, perform exactly one engineering objective, then exit. Any coding-agent CLI works. From `.autoeng/config.sh`:

```bash
#   aider     EXECUTOR="aider --model deepseek/deepseek-chat --yes --message-file .autoeng/AGENT.md"
#   claude    EXECUTOR="claude -p 'Follow .autoeng/AGENT.md and execute one autonomous cycle.'"
#   openclaw  EXECUTOR="openclaw run --message 'Follow .autoeng/AGENT.md, one cycle.'"
```

aider in particular already speaks Claude, DeepSeek, OpenAI, and Ollama out of the box, so swapping models is just a flag change — no framework changes needed.

## The files

`.autoeng/` contains exactly six files:

| File | Purpose |
|---|---|
| `AGENT.md` | Operating manual — the agent reads this every cycle |
| `STATE.md` | Working memory — status, next task, task queue, blockers |
| `WORKLOG.md` | Append-only journal, one entry per cycle |
| `config.sh` | The only file you edit — `EXECUTOR`, gates, `CONTROL`, tuning |
| `run.sh` | The single driver — `run`, `loop`, `adopt`, `status`, `pause`, `stop` |
| `.gitignore` | Ignores runtime artifacts (`LOCK`, `CHECKPOINT`, `execution.log`) |

## Greenfield vs existing

- **Existing repo**: `sh .autoeng/run.sh adopt` detects your stack (`package.json` → npm, `Cargo.toml` → cargo, `go.mod` → go, `pyproject.toml` → ruff/pytest), fills in `GATE_BUILD`/`GATE_LINT`/`GATE_TEST`, and seeds `STATE.md`.
- **New project**: skip `adopt`. Set the mission in `AGENT.md` §2 (what the project is, who it's for, what "done" looks like), and seed a "Phase 0: bootstrap" task in `STATE.md`'s task queue.

## Safety

- **Git checkpoint per cycle** — every cycle starts from a committed baseline.
- **Independent gate re-run** — `run.sh` re-runs `GATE_BUILD`/`GATE_LINT`/`GATE_TEST` itself; it doesn't take the executor's word for it.
- **Rollback on failure** — executor errors or gate failures trigger `git reset --hard` + `git clean -fd` back to the checkpoint, and `CONTROL` is set to `failed`.
- **LOCK** — prevents concurrent runs; a lock older than `LOCK_STALE_MIN` is treated as crashed and auto-recovered.
- **`CONTROL` flag** — pause or stop at any time (`sh .autoeng/run.sh pause` / `stop`), checked before every cycle.
- **No remote pushes** — the framework only commits locally, never pushes.
- **Validated work is landed** — on a passing cycle, any remaining uncommitted changes are committed so nothing is lost.

## Requirements

- Git
- A POSIX shell
- Any coding-agent CLI you point `EXECUTOR` at

The framework itself needs no language runtime — the quality gates run whatever your project already uses (npm, cargo, go, pytest, etc.).
