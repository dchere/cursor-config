---
name: developer-workflow
description: >-
  Software development workflow for implementing features and fixes, including
  AI-assisted development, integration testing, and forensic debugging. Use when
  coding, refactoring, or when the dev agent is active.
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
5. For multi-step work, state intermediate reasoning (goal, constraints, seams, failure paths) before editing.

## Agentic development (canonical)

- Act as an **editor of systems**: integrate and verify AI output; reject drive-by refactors.
- Treat AI as a **junior developer**: provide clear goals, constraints, and patterns in prompts.
- **Clean architecture is AI hygiene**: agents mirror existing code; messy structure gets amplified.
- **Review generated completions**: treat IDE/model suggestions as untrusted — they may introduce insecure defaults (e.g. `http` instead of `https`). Verify before keeping them.
- **Stateful agent graphs** (e.g. **LangGraph**): use when building multi-step AI workflows with guardrails — not for ordinary feature coding unless the task is agent design.

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
- Language-specific mocking (e.g. patch where the name is used): see **`python`**.

## Forensic debugging

When a run fails and a successful baseline exists, **`diff` logs or artifacts** from the good run against the failing one before guessing. Isolate environment or data-specific deltas; do not shotgun-change code.

## LLM product engineering (gated)

Only when the task is building LLM/agent products — not ordinary features.

- Model serving gateway and prompt/model registries: **`python/reference.md`** LLM section (do not duplicate here).
- **Agent Experience (AX)**: when building tools for other coding agents, ship `llms.txt`, MCP servers for queryable data, and installable skills. Do not add these to ordinary apps.

## Frontend (gated)

Follow **`system-architecture`** realtime/hypermedia decisions (SSE vs WebSockets, DOM morphing). If implementing hypermedia/SSE and the user wants to avoid an SPA, consider **Datastar**. Follow the existing frontend stack otherwise; do not introduce Datastar unprompted.

## In-app security (gated)

- Bot / signup-spam / prompt-injection layers (e.g. **Arcjet**): only if the project uses them or the user asks.
- Keep PII detection **in-process** (e.g. WASM sandbox) so sensitive data does not leave the environment.

## Output style

- Prefer diffs over reprinting whole files.
- Omit comments obvious from the logic.
- Brief explanations; no pleasantries or filler.

## Module size

If a file exceeds ~300 lines, consider splitting by responsibility and documenting modules (when the project uses per-module `.md` memory files).

## Commits

Do not commit unless the user explicitly asks. When asked, write a concise message focused on **why**, not a changelog of **what**.
