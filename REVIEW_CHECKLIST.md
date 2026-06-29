# Review Checklist â€” {{PROJECT_NAME}}

> **Mandatory code review checklist.** Every category must explicitly pass before a task is approved. This checklist runs during Phase 7 (Refactor) and is verified at the Quality Gate.

---

## Architecture

- [ ] **Pattern compliance** â€” implementation follows patterns defined in ARCHITECTURE.md
- [ ] **File placement** â€” files are in the correct directories per MVP file structure
- [ ] **Interface alignment** â€” TypeScript interfaces match data models in ARCHITECTURE.md
- [ ] **Dependency direction** â€” no circular dependencies, no layer violations (UI â†’ lib â†’ types, never reversed)
- [ ] **Separation of concerns** â€” {{COMPONENT_NAME}} logic â‰  {{COMPONENT_NAME}} logic â‰  {{COMPONENT_NAME}} logic â‰  UI logic
- [ ] **No undocumented deviations** â€” any deviation from ARCHITECTURE.md has a DECISIONS.md entry

**Verdict**: â˜ Pass â˜ Fail

---

## Naming

- [ ] **Consistency** â€” naming follows existing codebase conventions
- [ ] **Clarity** â€” names accurately describe what the thing does
- [ ] **No abbreviations** â€” except widely understood ones (API, URL, ID, UI)
- [ ] **Boolean naming** â€” booleans prefixed with `is`, `has`, `should`, `can`
- [ ] **Event naming** â€” event handlers prefixed with `on`, event emitters prefixed with `emit`
- [ ] **No misleading names** â€” `getUserData` actually gets user data, not just user names

**Verdict**: â˜ Pass â˜ Fail

---

## Readability

- [ ] **Self-documenting code** â€” code can be understood without reading comments
- [ ] **Comments explain WHY, not WHAT** â€” comments add context, not restate code
- [ ] **Function length** â€” no function exceeds 50 lines (consider splitting if it does)
- [ ] **File length** â€” no file exceeds 300 lines (flag in TECH_DEBT.md if it does)
- [ ] **No deeply nested code** â€” max 3 levels of nesting (use early returns, extracted functions)
- [ ] **Consistent style** â€” formatting matches existing codebase (enforced by lint)

**Verdict**: â˜ Pass â˜ Fail

---

## Complexity

- [ ] **Cyclomatic complexity** â€” no function has > 10 branches (if/else/switch/&&/||)
- [ ] **Parameter count** â€” no function has > 5 parameters (use an options object if needed)
- [ ] **No clever tricks** â€” code is boring and obvious, not clever
- [ ] **No premature optimization** â€” optimization only with a measured bottleneck
- [ ] **Linear flow** â€” logic flows top-to-bottom, not jumping around

**Verdict**: â˜ Pass â˜ Fail

---

## Duplication

- [ ] **No copy-pasted blocks** â€” shared logic is extracted into functions
- [ ] **No similar functions** â€” if two functions differ only slightly, unify with a parameter
- [ ] **No duplicate types** â€” if two types describe the same shape, use one
- [ ] **No duplicate constants** â€” magic numbers/strings are defined once
- [ ] **DRY check** â€” would a change require editing multiple places? If yes, refactor

**Verdict**: â˜ Pass â˜ Fail

---

## Security

- [ ] **No secrets in code** â€” API keys, passwords, tokens are never hardcoded
- [ ] **No secrets in git** â€” `.env` is in `.gitignore`, no keys in committed files
- [ ] **Input validation** â€” user input is validated before use
- [ ] **No innerHTML** â€” React handles DOM; no raw HTML injection
- [ ] **No eval** â€” no `eval()`, no `Function()`, no `setTimeout(string)`
- [ ] **Prompt injection defense** â€” user messages are treated as data, not instructions to the LLM
- [ ] **localStorage safety** â€” no sensitive data stored in localStorage without awareness

**Verdict**: â˜ Pass â˜ Fail

---

## Performance

- [ ] **No unnecessary re-renders** â€” React components use memoization where appropriate
- [ ] **No N+1 API calls** â€” batched or parallelized where possible (e.g., 3 {{COMPONENT_NAME}}s via Promise.all)
- [ ] **No blocking operations** â€” long-running work is async
- [ ] **No memory leaks** â€” useEffect cleanup, event listener removal, AbortController usage
- [ ] **No unbounded growth** â€” arrays/maps don't grow without limit (context window management)
- [ ] **Reasonable bundle size** â€” no unnecessarily large imports (tree-shake where possible)

**Verdict**: â˜ Pass â˜ Fail

---

## Error Handling

- [ ] **Every API call has error handling** â€” try/catch or .catch(), never unhandled rejection
- [ ] **Errors are surfaced to UI** â€” user sees a message, not a blank screen
- [ ] **Errors are logged** â€” console.error or equivalent (no silent failures)
- [ ] **Retry logic** â€” 429/5xx retried once with backoff
- [ ] **Timeout handling** â€” AbortController with 60s timeout on all LLM calls
- [ ] **Graceful degradation** â€” 3â†’2â†’1 {{COMPONENT_NAME}} fallback, {{COMPONENT_NAME}} raw output fallback
- [ ] **No empty catch blocks** â€” `catch (e) {}` is never acceptable; at minimum log the error

**Verdict**: â˜ Pass â˜ Fail

---

## Logging

- [ ] **No console.log in production** â€” use a logger or remove before finishing
- [ ] **Logs are meaningful** â€” no "here", "test", "asdf" log messages
- [ ] **Errors logged with context** â€” not just `console.error(e)` but `console.error('{{COMPONENT_NAME}} API call failed:', e)`
- [ ] **No sensitive data logged** â€” API keys, full transcripts, user PII never logged

**Verdict**: â˜ Pass â˜ Fail

---

## API Consistency

- [ ] **LLMClient interface** â€” all providers implement the same interface
- [ ] **Request format** â€” matches API contract in ARCHITECTURE.md
- [ ] **Response parsing** â€” correct field extraction per provider (choices[0].message.content vs content[0].text vs candidates[0].content.parts[0].text)
- [ ] **Error handling** â€” consistent error types across providers
- [ ] **Model names** â€” correct model identifiers per provider
- [ ] **No hardcoded URLs** â€” API base URLs are configurable or use SDK defaults

**Verdict**: â˜ Pass â˜ Fail

---

## Data Validation

- [ ] **LLM response validation** â€” parsed JSON is validated before use
- [ ] **{{COMPONENT_NAME}} output validation** â€” required fields present (signals, coverage, nextAction)
- [ ] **{{COMPONENT_NAME}} output validation** â€” required fields present (dimensionScores, signals, confidence)
- [ ] **{{COMPONENT_NAME}} output validation** â€” required fields present (consensusScores, narratives, divergences)
- [ ] **Type narrowing** â€” unknown API responses are narrowed to expected types
- [ ] **Fallback on invalid data** â€” if LLM returns garbage, fall back to repair/synthesize path

**Verdict**: â˜ Pass â˜ Fail

---

## Testing

- [ ] **Unit tests for new functions** â€” every new pure function has tests
- [ ] **Component tests for new components** â€” every new React component has render tests
- [ ] **Error path tests** â€” not just happy path; test failures, edge cases, invalid input
- [ ] **Mocked API calls** â€” no real API calls in tests
- [ ] **Test naming** â€” test descriptions explain the scenario ("returns empty array on null input")
- [ ] **No skipped tests** â€” no `.skip` without a documented reason
- [ ] **Test independence** â€” tests don't depend on execution order or shared mutable state

**Verdict**: â˜ Pass â˜ Fail

---

## Documentation

- [ ] **JSDoc on exported functions** â€” public API has documentation
- [ ] **Component comments** â€” complex components have a brief description
- [ ] **Updated existing docs** â€” ARCHITECTURE.md, PLAN.md, README.md updated if behavior changed
- [ ] **No stale comments** â€” comments don't reference old code or removed features
- [ ] **TODO comments documented** â€” every `// TODO` has a corresponding TECH_DEBT.md entry

**Verdict**: â˜ Pass â˜ Fail

---

## Maintainability

- [ ] **Could a new contributor understand this code?** â€” without excessive context
- [ ] **Is the code testable?** â€” dependencies are injectable, functions are pure where possible
- [ ] **Is the code extensible?** â€” new providers, new dimensions, new question types can be added without rewriting
- [ ] **Is the code debuggable?** â€” errors are traceable, state is observable
- [ ] **Is the code observable?** â€” can you tell what happened by looking at logs + state

**Verdict**: â˜ Pass â˜ Fail

---

## Final Approval

| Category | Verdict |
|----------|---------|
| Architecture | â˜ Pass â˜ Fail |
| Naming | â˜ Pass â˜ Fail |
| Readability | â˜ Pass â˜ Fail |
| Complexity | â˜ Pass â˜ Fail |
| Duplication | â˜ Pass â˜ Fail |
| Security | â˜ Pass â˜ Fail |
| Performance | â˜ Pass â˜ Fail |
| Error Handling | â˜ Pass â˜ Fail |
| Logging | â˜ Pass â˜ Fail |
| API Consistency | â˜ Pass â˜ Fail |
| Data Validation | â˜ Pass â˜ Fail |
| Testing | â˜ Pass â˜ Fail |
| Documentation | â˜ Pass â˜ Fail |
| Maintainability | â˜ Pass â˜ Fail |

**All categories must Pass to approve. Any Fail â†’ return to Phase 12 (Fix Failures).**