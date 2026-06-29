# Execution Checklist â€” {{PROJECT_NAME}} Autonomous Engineer

> **This checklist is verified before finishing every execution (Phase 20).** Every item must be checked. No item is skipped. If any item fails, go back and fix it before finishing.

---

## Pre-Finish Checklist

Run through this checklist at the end of every execution cycle, after Phase 18 (Append WORKLOG) and before Phase 20 (Finish Execution):

### Code Quality

- [ ] **Build passes** â€” `npm run build` completes with exit code 0
- [ ] **Lint passes** â€” `npm run lint` completes with exit code 0 (or no lint configured yet)
- [ ] **Typecheck passes** â€” `npx tsc --noEmit` completes with exit code 0
- [ ] **Tests pass** â€” `npm test` completes with exit code 0 (or no tests configured yet)

### Documentation

- [ ] **Documentation updated** â€” all docs reflect current code state:
  - `docs/ARCHITECTURE.md` â€” if architecture changed
  - `docs/PLAN.md` â€” if plan/timeline changed
  - `README.md` â€” if features or setup changed
  - `docs/prompts/*` â€” if prompts changed
  - `docs/SCIENTIFIC_FOUNDATION.md` â€” if scoring rubrics changed

### Agent Files

- [ ] **TODO updated** â€” completed items checked off, partial items annotated, next item is clear
- [ ] **PROJECT_STATUS updated** â€” completion %, features, issues, build/test status all reflect this run
- [ ] **NEXT_TASK updated** â€” file overwritten with exactly one next task, fully specified
- [ ] **WORKLOG appended** â€” new entry with timestamp, objectives, tasks, bugs, tests, docs, remaining work

### Git

- [ ] **Changes committed** â€” `git add -A && git commit` with descriptive message (if build passes)
- [ ] **No secrets committed** â€” `.env` is in `.gitignore`, no API keys in committed files
- [ ] **No broken code committed** â€” if build/tests fail, do not commit

### Consistency

- [ ] **No unfinished code without TODO markers** â€” all stubs and placeholders have `// TODO` comments
- [ ] **No `as any` or `@ts-ignore` without justification** â€” search for these and verify each has a comment
- [ ] **No new dependencies without DECISIONS.md entry** â€” check `package.json` for additions
- [ ] **No architecture violations** â€” implementation matches `docs/ARCHITECTURE.md`

---

## Failure Protocol

If any checklist item fails:

1. **Code quality failure** (build/lint/typecheck/tests): Go back to Phase 12 (Fix Failures). Max 3 retry rounds.
2. **Documentation failure**: Go back to Phase 14 (Update Documentation). Fix immediately.
3. **Agent files failure**: Go back to the relevant phase (15-18). Fix immediately.
4. **Git failure**: Do not commit. Log the issue in WORKLOG. Finish with "partial" status.
5. **Consistency failure**: Fix immediately if simple. If complex, document in WORKLOG and finish with "partial" status.

**No execution finishes with an unchecked checklist item.** If an item cannot be checked, it must be explicitly documented as a known issue in PROJECT_STATUS.md with a reason.