---
name: python
description: >-
  Python standards for layout, typing, testing, profiling, tooling, and data
  boundaries. Use when writing or reviewing Python code, packages, pytest,
  or pyproject.toml.
---

# Python

## Project layout

- Prefer `pyproject.toml` for tool config; use `requirements.txt` or `pyproject` dependencies as the project already does.
- Use a virtualenv (`.venv` or `venv`); do not install packages globally.
- Package code in a named module/package; avoid dumping logic in repo-root scripts unless the project already does.

## Interpreter and venv

- Use **`python3`** or **`.venv/bin/python`** — bare `python` is often missing (especially on macOS). See [reference.md](reference.md#terminal-and-interpreter).
- If imports fail, confirm the venv interpreter before installing deps.

## Style and linting

- Use **Ruff** for lint/format when configured.
- Line length: follow `pyproject.toml` (often 100).
- Prefer explicit imports; group stdlib, third-party, local.
- Do not add `# pylint: disable=...` broadly; refactor instead.

## Typing and validation

- Add type hints on public functions and non-trivial internals.
- Use `Optional`, `list`, `dict` (or `from __future__ import annotations` per project).
- Use **Pydantic** `BaseModel` for config and for **external input** (API, CSV, user files) at boundaries.

## Error handling

- Catch specific exceptions; avoid bare `except:` and silent swallow.
- Prefer explicit optional returns (`User | None`) for expected missing data; reserve exceptions for exceptional paths.
- Fail fast at startup for missing config or invalid paths when appropriate.

## Testing

- Use **pytest** when the project has tests.
- Write tests for behavior that can regress; skip trivial "does import work" tests.
- Prefer pure functions and isolated DB/API boundaries for testability.
- **E2E browser tests**: use **Playwright** only when the project already does; its codegen can bootstrap scripts — do not introduce Playwright without being asked.

## Dependencies and tooling

- Pin or constrain versions as the project does.
- **New projects**: consider `uv` for env management. **Existing repos**: follow `pip`/`requirements.txt` — do not migrate without being asked.
- Heavy ML/runtime deps stay optional when possible. Tooling details: [reference.md](reference.md#environment-tooling).

## Performance (only when relevant)

Apply this section **after profiling or a known hot path** — not by default on every change.

- Prefer **O(1)** membership via `set` / `dict` over list scans in hot loops.
- Profile before optimizing: `cProfile` (deterministic), **Pyinstrument** (low-overhead sampling), or Linux **`perf`** (3.12+) for system-wide view — see [reference.md](reference.md#profiling).
- **`__slots__`**, PyO3, Cython, concurrency rewrites: see [reference.md](reference.md) — require evidence, not speculation.

## Observability

- Avoid `print()` in production/service paths; use structured logging.
- Use **Loguru** only when the project already does; otherwise stdlib `logging`. Details: [reference.md](reference.md#observability-loguru).

## SQLite

- Enable **WAL** and busy timeout for concurrent access.
- Prefer **STRICT** tables on new schemas. Keep SQL in a repository layer — [reference.md](reference.md#repository-pattern-sqlite).

## Structure

- Keep modules under ~300 lines; split by responsibility.
- Optional: companion `.md` per module for architectural memory (when the project adopts it).
- Thin CLI: argparse only, delegate to `workflows/` or service layer.

## Additional detail

See [reference.md](reference.md) for macOS terminal notes, concurrency (3.14+), memory/GC, Rust/PyO3, and CLI layout.
