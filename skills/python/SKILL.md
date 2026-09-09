---
name: python
description: >-
  Python standards for layout, typing, testing, profiling, tooling, logging,
  serialization, and data boundaries. Use when writing or reviewing Python
  code, packages, pytest, or pyproject.toml.
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
- Use **`@property`** for derived or validated public attributes so call sites stay attribute-like (lazy calc / validation without API churn).

## Typing and validation

- Add type hints on public functions and non-trivial internals.
- Use `Optional`, `list`, `dict` (or `from __future__ import annotations` per project).
- Use **Pydantic** `BaseModel` for config and for **external input** (API, CSV, user files) at boundaries.
- Keep `Annotated[...]` when that is the project style. Do **not** rewrite to proposed `@` metadata shorthand unless the project's Python/tooling already supports and uses it.

## Methods

- **Instance methods** — mutate or read instance state via `self`.
- **`@classmethod`** — alternative constructors or registries (operate on the class).
- **`@staticmethod`** — prefer a **module-level function** unless the utility must live in the class namespace for API/discovery reasons.

## Contracts and inheritance

- Use **ABCs** when subclasses must formally implement a contract; prefer **Protocols** when structural typing is enough.
- Multiple inheritance / diamond problem: inspect `Class.__mro__` to see the search path; use **`super()`** so each ancestor initializes once.
- Inheritance vs composition (reversibility test, LSP, policy composition): **`system-architecture`**.

## Error handling

- Catch specific exceptions; avoid bare `except:` and silent swallow.
- Prefer explicit optional returns (`User | None`) for expected missing data; reserve exceptions for exceptional paths.
- Fail fast at startup for missing config or invalid paths when appropriate.

## Testing

- Use **pytest** when the project has tests.
- Write tests for behavior that can regress; skip trivial "does import work" tests.
- Prefer **integration tests** when a change crosses a service, DB, or API boundary — unit tests often pass while the seam fails. Workflow: **`developer-workflow`**.
- Prefer pure functions and isolated DB/API boundaries for testability.
- **Patch where the name is used, not where it is defined.** If the SUT does `from requests import get`, patch `that_module.get`, not `requests.get`.
- **E2E browser tests**: use **Playwright** only when the project already does; its codegen can bootstrap scripts — do not introduce Playwright without being asked.

## Dependencies and tooling

- Pin or constrain versions as the project does.
- **New projects**: use **`uv`** for env, lockfile, and production-style installs.
- **Existing repos**: follow `pip`/`requirements.txt` — do not migrate without being asked.
- **If the project already uses uv**: use `uv lock` / `uv sync` / `uv run` — do not mix pip in that repo.
- Heavy ML/runtime deps stay optional when possible. Tooling details: [reference.md](reference.md#environment-tooling).

## Performance (only when relevant)

Apply this section **after profiling or a known hot path** — not by default on every change.

- Prefer **O(1)** membership via `set` / `dict` over list scans in hot loops.
- Profile before optimizing: `cProfile` (deterministic), **Pyinstrument** (low-overhead sampling), or Linux **`perf`** (3.12+) for system-wide view — see [reference.md](reference.md#profiling).
- **`__slots__`**, PyO3, Cython, concurrency rewrites: see [reference.md](reference.md) — require evidence, not speculation.

## Observability

- Avoid `print()` in production/service paths; use structured logging.
- Use **Loguru** only when the project already does; otherwise stdlib `logging`. Details: [reference.md](reference.md#observability-loguru).
- Reusable libraries: `logging.getLogger(__name__)` — do **not** reconfigure or hijack the root logger.
- Do not pre-format with f-strings or `.format()`; pass args so interpolation is lazy: `logging.info("User %s", user_id)`.

## Serialization

- Never **`pickle`** untrusted data (RCE). Use JSON, **msgspec**, or the project's existing serializer — do not add msgspec unprompted. Details: [reference.md](reference.md#serialization).

## SQLite

- Enable **WAL** and busy timeout for concurrent access.
- Prefer **STRICT** tables on new schemas. Keep SQL in a repository layer — [reference.md](reference.md#repository-pattern-sqlite).

## Structure

- Keep modules under ~300 lines; split by responsibility.
- Optional: companion `.md` per module for architectural memory (when the project adopts it).
- Thin CLI: argparse only, delegate to `workflows/` or service layer.

## Additional detail

See [reference.md](reference.md) for macOS terminal notes, concurrency (3.14+ / free-threading internals), profiling frame pointers, AST transforms, data notebooks, Rust/PyO3, and CLI layout.
