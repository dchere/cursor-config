---
name: developer-workflow
description: >-
  Software development workflow for implementing features and fixes, including
  AI-assisted development. Use when coding, refactoring, or when the dev agent
  is active.
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

## Agentic development (canonical)

- Act as an **editor of systems**: integrate and verify AI output; reject drive-by refactors.
- Treat AI as a **junior developer**: provide clear goals, constraints, and patterns in prompts.
- **Clean architecture is AI hygiene**: agents mirror existing code; messy structure gets amplified.
- **Flow engineering**: generate → run tests/linters → fix from error traces → repeat until green; do not stop at first compile.
- After AI-generated changes: run tests/linters; consider a **cr** agent pass.
- Do not let AI introduce repo-wide style drift — follow project conventions and skills.
- **Stateful agent graphs** (e.g. **LangGraph**): use when building multi-step AI workflows with guardrails — not for ordinary feature coding unless the task is agent design.

## Implementation loop

1. Read relevant files and call sites.
2. Implement the focused change.
3. If the project uses module memory (companion `.md`, `AGENTS.md`, or `.cursor/rules/`): update mapped docs in the **same change** when behavior, CLI, config, or flows change.
4. Run linter/tests — use **`python3`** or **`.venv/bin/python`**, not bare `python` on macOS.
5. Fix issues you introduced; do not expand scope.

## Output style

- Prefer diffs over reprinting whole files.
- Omit comments obvious from the logic.
- Brief explanations; no pleasantries or filler.

## Module size

If a file exceeds ~300 lines, consider splitting by responsibility and documenting modules (when the project uses per-module `.md` memory files).

## Commits

Do not commit unless the user explicitly asks. When asked, write a concise message focused on **why**, not a changelog of **what**.
