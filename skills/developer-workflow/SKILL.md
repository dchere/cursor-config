---
name: developer-workflow
description: >-
  Software development workflow for implementing features and fixes, including
  AI-assisted development, integration testing, forensic debugging, and
  action-first user-facing output. Use when coding, refactoring, when the dev
  agent is active, or when shaping replies for any agent.
---

# Developer Workflow

## Principles

- **Minimal scope**: smallest correct diff; no unrelated changes.
- **Match conventions**: read surrounding code before editing; reuse existing abstractions.
- **No over-engineering**: no premature abstraction, helpers, or error handling for unlikely cases.
- **Comments**: only for non-obvious business logic or deep technical details.
- **Tests**: add only when they cover meaningful behavior; skip trivial assertions.
- **Cleanup**: remove temporary scripts (`fix_*.py`, scaffolding) when done.

## Before coding

1. Read project docs (README, AGENTS.md, module `.md` files if the project uses them).
2. Identify the smallest change that solves the request.
3. Detect language/stack from repo signals (`pyproject.toml`, `package.json`, etc.).
4. Apply the matching language skill (e.g. `python`) when present.
5. For multi-step work, track steps on a checklist (one in progress). Do not narrate the full plan as prose to the user.

## Agentic development (canonical)

- Act as an **editor of systems**: integrate and verify AI output; reject drive-by refactors.
- Treat AI as a **junior developer**: provide clear goals, constraints, and patterns in prompts.
- **Clean architecture is AI hygiene**: agents mirror existing code; messy structure gets amplified.
- **Review generated completions**: treat IDE/model suggestions as untrusted — they may introduce insecure defaults (e.g. `http` instead of `https`). Verify before keeping them.
- **Stateful agent graphs** (e.g. **LangGraph**): use when building multi-step AI workflows with guardrails — not for ordinary feature coding unless the task is agent design. Follow the project's SDK (LangGraph `interrupt()` HITL, Anthropic/OpenAI agent SDKs) if already in use; do not add a second orchestrator.

## Implementation loop

Failing tests are a flashlight for unclear or missing requirements — do not weaken assertions to get green.

1. Define the goal, constraints, and project conventions that apply.
2. Note expected I/O examples and bad edge cases before coding.
3. Read relevant files and call sites.
4. Implement in small increments (smallest correct diff).
5. If the project uses module memory (companion `.md`, `AGENTS.md`, or `.cursor/rules/`): update mapped docs in the **same change** when behavior, CLI, config, or flows change.
6. Add or extend tests — **prefer integration tests** when the change crosses service, DB, queue, or API boundaries; skip trivial assertions.
7. Run linter/tests — use **`python3`** or **`.venv/bin/python`**, not bare `python` on macOS. Fix from error traces; iterate until green. Do not stop at first compile.

After AI-generated changes: run tests/linters; consider a **cr** agent pass. Do not let AI introduce repo-wide style drift — follow project conventions and skills.

## Tests

- Integration tests are the highest-leverage check: localized unit tests often pass while the system fails end-to-end from mismatched assumptions at boundaries.
- When changing a boundary, exercise the real seam as the project already does — do not mock away the thing under test.
- Language-specific mocking (e.g. patch where the name is used) and **Hypothesis**: see **`python`**. Do not add Hypothesis unprompted.
- **Legacy rewrite:** characterization tests first; differential compare through one adapter — **`python/reference.md`**.
- **Agent products:** unit-test tools without an LLM; mock tool I/O to test the loop; E2E evals on a schedule. Do not call paid models from unit tests.

## Forensic debugging

When a run fails and a successful baseline exists, **`diff` logs or artifacts** from the good run against the failing one before guessing. Isolate environment or data-specific deltas; do not shotgun-change code.

Live process (Python 3.15+): `python -m profiling.sampling dump --async-aware <pid>`. In-memory instances: `gc.get_objects()` — diagnostic only; details **`python/reference.md`**.

## LLM product engineering (gated)

Only when the task is building LLM/agent products — not ordinary features.

- Model serving gateway and prompt/model registries: **`python/reference.md`** LLM section (do not duplicate here).
- **Workflow vs agent:** hardcoded steps with LLM in a slot vs a perceive–reason–act loop until stop. Do not turn a simple pipeline into an autonomous loop.
- **MCP:** tool docstrings *are* the prompt. CLI tools are cheaper in tokens; MCP schemas cost context and buy validation/audit. Do not add MCP to ordinary apps. Transport: stdio or the project's existing HTTP/SSE.
- **Tool boundary:** validate and normalize args in code (enums, `.strip()`). Do not rely on the system prompt for security. When the product already screens input, reject malformed or policy-violating prompts with deterministic checks **before** paid API calls.
- **HITL:** destructive tool calls need an explicit approve step (`interrupt()` or equivalent). Matches Output style safety overrides.
- **Bounded loops:** cap tool/LLM iterations (`range(max_iterations)`). Return tool exceptions to the model as observations; do not crash the loop.
- **Agent Experience (AX)**: when building tools for other coding agents, ship `llms.txt`, MCP servers for queryable data, and installable skills. Do not add these to ordinary apps.
- Session compaction, JSONL audit, per-user OAuth, model fallback: **`python/reference.md`**.
- **PR-review products** (not Cursor CR): retrieve callers with repo search, not the hunk alone; drop ungrounded findings. Fan-out specialists are **`system-architecture`** Multi-agent products — do **not** change our sequential **cr** / **pipeline**.

## Frontend (gated)

Follow **`system-architecture`** realtime/hypermedia decisions (SSE vs WebSockets, DOM morphing). If implementing hypermedia/SSE and the user wants to avoid an SPA, consider **Datastar**. Follow the existing frontend stack otherwise; do not introduce Datastar unprompted.

FastAPI + an existing TypeScript client: Pydantic/OpenAPI is the source of truth; generate `api-types.ts` (`openapi-typescript` or `@hey-api/openapi-ts`). Do not add a TS client or Datastar unprompted.

Mixed short HTTP + SSE/WebSockets: process split is **`system-architecture`** Process topology — do not split a working unified ASGI app unprompted.

## In-app security (gated)

- Bot / signup-spam / prompt-injection layers (e.g. **Arcjet**): only if the project uses them or the user asks.
- Keep PII detection **in-process** (e.g. WASM sandbox) so sensitive data does not leave the environment.
- Linux process sandbox (Landlock): **`python/reference.md`** — only if asked or already used.

## GitHub Actions (gated)

Only when the change edits `.github/workflows/`:

- Pin third-party actions to a 40-character commit SHA, not a floating tag.
- If the project already uses **zizmor** or **actionlint**, keep them. Do not add them unprompted.
- When editing `.github/dependabot.yml`: set an update cooldown (e.g. 7 days). Do not add Dependabot to a repo that lacks it.
- If the org already has an Actions **allowlist**, do not add off-list actions.

Keep existing SAST/SCA/signing/admission tools (Semgrep, Bandit, Gitleaks, Checkov, Trivy, Cosign, Kyverno, Falco, ZAP). Do not introduce that full matrix unprompted.

## Output style

Canonical user-facing delivery for every agent (always on). Role skills keep their required sections; change order and wrapping here, not the content. Source of the shape: [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) (MIT). Do not add a separate skill or `/i-have-adhd` toggle.

Shape, not diagnosis. Working memory is small; starting is the hard step; vague time ("a bit") does not register; buried wins do not register.

**Scope gate — apply before every other bullet.** If the user asked for analysis, review, suggestions, explanation, or discussion only (and did not ask to implement, apply, fix, or edit): do not change files, do not run the implementation loop, do not hand the reader a patch to paste. The answer is the finding. First line = recommendation, verdict, or top finding. Closer = one decision ("pick B" / "say apply it"), not an edit command. Autonomy below does not apply to this case. Invoking the **pipeline** agent counts as asking to implement unless the user also used an opt-out keyword (`plan only`, `analysis only`, `review only`, …).

- **First line = the answer the reader can act on.** Implement/fix: a command, path, or snippet. Analysis/review/discussion: the recommendation, verdict, or top finding — not "open the file and replace…".
- **Number multi-step work.** One bounded action per step; no step contains "and then" twice. Fewest steps that still work. Cap lists at 5; split must vs later if longer. Analysis: numbered trade-offs or findings, not an implementation checklist unless they asked how to apply it.
- **Restate state every turn** (e.g. "step 3 of 5 done: schema updated"). Do not ask the reader to remember prior turns. If using a task/plan tool: one item per step, one in progress; the checklist restates — do not also narrate the plan as prose.
- **Visible win:** say what now works, in concrete terms. Partial success: name what passed *and* what failed. Time estimates in concrete units (15 minutes, an afternoon). Analysis: the win is a decision the reader can make, not a merged diff.
- **One closer:** if work remains, one action the reader can do in under two minutes. Finish the first issue before offering a second ("Separately: … Want me to handle that?"). Analysis closer: one choice, or "say apply it" — do not start applying.
- **Errors:** location, cause, fix. No "uh oh" / "there seems to be". Analysis: state cause and recommended fix; do not apply the fix.
- **No preamble, recap, or pleasantries.** Forbidden openers: "Great question," "Let me…", "I'll…", "Sure!", "Looking at your…". Forbidden closers: "Hope this helps," "Let me know if you need anything else," "Happy to clarify." Prefer diffs over reprinting whole files. Omit comments obvious from the logic. Internal reasoning stays internal.
- **Do not invent work.** Direct answers ("what is 17×6") get the answer, not a workflow. "Thanks" gets a brief ack, not numbered steps. Honor explicit output contracts ("return only the code"). Do not turn an analysis request into an implementation plan the reader must execute.
- **Autonomy:** only when the task includes doing the work (implement, fix, apply, edit). Then do agent-owned work (edits, tests, verification); do not push avoidable steps back to the user. Point time estimates at whoever actually runs the step.
- **Substance:** brevity must not strip required detail. Plans keep rollback and verification. "Walk me through" / "explain" → full answer with skim headers, still no preamble or closer, still no unsolicited edits.
- **Safety overrides:** confirm before destructive actions; name the exact risk; prefer a read-only preview (`git clean -nd`, dry-run) over executing. One short clarifying question beats guessing. After three failed debug turns: name the assumption that might be wrong; ask one diagnostic question. If a rule would delete the answer ("what are my options"), the task wins: 2–4 ranked options, recommendation first. Harness system prompt outranks this section; keep the shape.

**Pre-send:** delete an opener that announces what you will do; a closer that recaps or asks "anything else?"; any "by the way" sidebar; empty hedges ("perhaps," "might") unless they carry real uncertainty; idioms ("circle back") — use the literal action. Then: if the reader sees only the first line and the last line, they know (a) what to do next and (b) what just happened. For analysis-only, (a) is a decision, not an edit.

Example — implement/fix:

```
Run `npm install jsonwebtoken@latest`, then edit `src/auth.ts:42`.

1. Open `src/auth.ts`
2. Replace `verifyToken` (lines 42–58) with the snippet below
3. Run `npm test -- auth.spec.ts`

Next: paste the first failing line if any test fails.
```

Example — analysis/suggestions only:

```
Recommend keeping the session cookie; drop the second refresh token.

1. Cookie already covers idle timeout
2. A second token doubles logout bugs without a new threat
3. Remaining risk: XSS — HttpOnly is required

Next: say "apply it" if you want the change, or pick the refresh-token option.
```

## Module size

If a file exceeds ~300 lines, consider splitting by responsibility and documenting modules (when the project uses per-module `.md` memory files).

## Commits

Do not commit unless the user explicitly asks. When asked, write a concise message focused on **why**, not a changelog of **what**.
