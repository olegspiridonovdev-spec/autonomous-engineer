# Success Criteria â€” {{PROJECT_NAME}}

> **Defines when the project is complete.** When all criteria are met, the autonomous engineer triggers FINAL_SHUTDOWN.md.

---

## Completion Criteria

### Phase 1 â€” MVP (Client-Side Multi-Model Chat Assessment)

- [ ] Project scaffolded with Vite + React + TypeScript
- [ ] Tailwind CSS, Zustand, Recharts installed and configured
- [ ] `.env` configured with VITE_OPENAI_API_KEY, VITE_ANTHROPIC_API_KEY, VITE_GOOGLE_API_KEY
- [ ] TypeScript types defined for all data models ({{COMPONENT_NAME}}, {{COMPONENT_NAME}}, {{COMPONENT_NAME}}, session)
- [ ] API clients implemented for OpenAI, Anthropic, Google Gemini
- [ ] Unified LLMClient interface with AbortController (60s) and retry (429/5xx)
- [ ] Prompt texts embedded from docs/prompts/ into src/lib/prompts/
- [ ] {{COMPONENT_NAME}} engine: conversation loop, JSON parsing, fallback chain
- [ ] Context window management: rolling summary after 25K tokens
- [ ] State management: Zustand stores (useSession, useAssessment)
- [ ] localStorage persistence with session resume (ResumePrompt)
- [ ] Chat UI: ChatView, MessageBubble, ChatInput, CoverageBar, LoadingState
- [ ] Scoring engine: 3 parallel {{COMPONENT_NAME}}s with fallback (3â†’2â†’1)
- [ ] Token budget management for {{COMPONENT_NAME}}s (truncate if > 20K tokens)
- [ ] {{COMPONENT_NAME}} engine with retry (cached {{COMPONENT_NAME}} outputs, 3 retries, raw fallback)
- [ ] Report UI: ReportView (10 sections), RadarChart (6-axis), AgreementMatrix, TranscriptView
- [ ] Copy report as markdown
- [ ] Mobile-responsive design
- [ ] Error recovery UI (retry buttons)
- [ ] Clean Tailwind styling
- [ ] End-to-end test: open â†’ chat 18 turns â†’ scoring â†’ report â†’ verification checklist passes

### Phase 2 â€” Backend & Adaptive AI

- [ ] Hono backend on Cloudflare Workers (API proxy)
- [ ] API keys moved server-side
- [ ] Supabase: auth + session storage
- [ ] Session history (multiple assessments per user)
- [ ] Real-time difficulty adjustment
- [ ] Dynamic probing and category balancing
- [ ] Anti-deception v2: targeted verification, inconsistency detection
- [ ] Calibration study: 20-50 participants, validated test scores
- [ ] LLM-vs-test correlations computed (target râ‰¥.50, cognitive râ‰¥.60)
- [ ] Validity report published

### Phase 3 â€” Professional Reports

- [ ] 10-section consensus report
- [ ] 6-axis radar with confidence bands
- [ ] Agreement visualization (green/yellow/red)
- [ ] Career recommendations
- [ ] Development suggestions
- [ ] Methodology transparency section
- [ ] Server-side PDF generation
- [ ] Shareable link with privacy controls

### Phase 4 â€” Polish & Scale

- [ ] Conversation styles (formal, friendly, clinical)
- [ ] Multi-language support
- [ ] Pause/resume with AI context restoration
- [ ] Per-turn ensemble scoring (optional real-time)
- [ ] Response timing analysis
- [ ] Continuous calibration (auto-improve from new data)
- [ ] Cloudflare Pages deployment
- [ ] Analytics dashboard
- [ ] API for third-party integration

---

## Quality Criteria

- [ ] Build passes (`npm run build`)
- [ ] Lint passes (`npm run lint`)
- [ ] Typecheck passes (`npx tsc --noEmit`)
- [ ] All tests pass (`npm test`)
- [ ] No Critical or High severity tech debt in TECH_DEBT.md
- [ ] No active blockers in BLOCKERS.md
- [ ] Documentation complete and up-to-date
- [ ] README.md accurate
- [ ] ARCHITECTURE.md reflects actual implementation
- [ ] PLAN.md all phases checked off

---

## Rule

**All criteria must be checked.** Partial completion is not completion. The autonomous engineer verifies every criterion before triggering FINAL_SHUTDOWN.md.

If any criterion cannot be met (e.g., calibration study requires human recruitment), the criterion is marked as "Blocked â€” requires human action" and the project cannot be marked as PROJECT_COMPLETED until resolved.