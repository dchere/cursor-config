---
name: developer-workflow
description: >-
  Language-agnostic software development workflow for implementing features and
  fixes. Use when writing code, implementing tasks, refactoring, or when the
  developer agent is active.
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

## Implementation loop

1. Read relevant files and call sites.
2. Implement the focused change.
3. Run linter/tests if the project has them.
4. Fix issues you introduced; do not expand scope.

## Output style

- Prefer diffs over reprinting whole files.
- Omit comments obvious from the logic.
- Brief explanations; no pleasantries or filler.

## Module size

If a file exceeds ~300 lines, consider splitting by responsibility and documenting modules (when the project uses per-module `.md` memory files).

## Commits

Do not commit unless the user explicitly asks. When asked, write a concise message focused on **why**, not a changelog of **what**.
