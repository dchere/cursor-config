---
name: python
description: >-
  Python development standards for layout, style, typing, testing, and tooling.
  Use when writing or reviewing Python code, pyproject.toml, requirements.txt,
  pytest, or Python packages.
---

# Python

## Project layout

- Prefer `pyproject.toml` for tool config; use `requirements.txt` or `pyproject` dependencies as the project already does.
- Use a virtualenv (`.venv` or `venv`); do not install packages globally.
- Package code in a named module/package; avoid dumping logic in repo-root scripts unless the project already does.

## Style and linting

- Use **Ruff** for lint/format when configured.
- Line length: follow `pyproject.toml` (often 100).
- Prefer explicit imports; group stdlib, third-party, local.
- Do not add `# pylint: disable=...` broadly; refactor instead (project-specific modules may enforce this strictly).

## Typing

- Add type hints on public functions and non-trivial internals.
- Use `Optional`, `list`, `dict` (or `from __future__ import annotations` per project).
- Prefer **Pydantic** `BaseModel` for config and validated data structures.

## Error handling

- Catch specific exceptions; avoid bare `except:` and silent swallow.
- Fail fast at startup for missing config or invalid paths when appropriate.
- Use clear error messages; raise `SystemExit(1)` in CLI entry points when needed.

## Testing

- Use **pytest** when the project has tests.
- Write tests for behavior that can regress; skip trivial "does import work" tests.
- Prefer pure functions and isolated DB/API boundaries for testability.

## Dependencies

- Pin or constrain versions in requirements/pyproject as the project does.
- Heavy ML/runtime deps (torch, llama-cpp, etc.) stay optional when possible.

## Structure

- Keep modules under ~300 lines; split by responsibility.
- Optional pattern: companion `.md` per module for architectural memory (when the project adopts it).
- Thin CLI: argparse only, delegate to `workflows/` or service layer.

## Additional detail

See [reference.md](reference.md) for patterns (repository layer, config loading, SQLite).
