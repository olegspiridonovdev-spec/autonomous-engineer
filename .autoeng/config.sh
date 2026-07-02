# .autoeng/config.sh — the only file you must edit. Sourced by run.sh.

# --- Executor: the command that runs ONE cycle -------------------------------
# It is invoked from the project root, reads .autoeng/AGENT.md, performs exactly
# one engineering objective, then exits. Any coding agent works — this string is
# the only adapter. Examples:
#   aider     EXECUTOR="aider --model deepseek/deepseek-chat --yes --message-file .autoeng/AGENT.md"
#   claude    EXECUTOR="claude -p 'Follow .autoeng/AGENT.md and execute one autonomous cycle.'"
#   openclaw  EXECUTOR="openclaw run --message 'Follow .autoeng/AGENT.md, one cycle.'"
EXECUTOR=""

# --- Quality gates: blank = skipped (and logged). Auto-filled by `run.sh adopt`.
GATE_BUILD=""
GATE_LINT=""
GATE_TEST=""

# --- Control: enabled | paused | stop_requested | project_completed | failed
CONTROL="paused"

# --- Tuning ------------------------------------------------------------------
LOCK_STALE_MIN=30      # a LOCK older than this (minutes) is treated as crashed and recovered
CYCLE_TIMEOUT_MIN=15   # advisory per-cycle wall-clock budget (documented in AGENT.md)
