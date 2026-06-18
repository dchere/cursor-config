# Python Reference

## Terminal and interpreter

On macOS, **`python` is often unavailable** — use `python3` or the project venv:

```bash
source .venv/bin/activate
python -m pytest ...

# without activating:
.venv/bin/python -m yourpackage.cli --help
.venv/bin/pip install -r requirements.txt
```

Do not use bare `python`/`pip`/`pytest` unless the venv is active.

## Config loading

```python
from pydantic import BaseModel, Field

class AppConfig(BaseModel):
    default_db: str = "./app.db"
    include_keywords: list[str] = Field(default_factory=list)

    @classmethod
    def load(cls, path: str | None = None) -> "AppConfig":
        ...
```

- Merge defaults from bundled JSON with user overrides.
- Expose `load` / `save` helpers; avoid scattered `dict.get()` for config.

## Repository pattern (SQLite)

- All SQL in a `db/` package; business logic never executes raw SQL inline.
- WAL and busy timeout for concurrent access:
  ```sql
  PRAGMA journal_mode=WAL;
  PRAGMA busy_timeout=5000;
  ```
- Prefer **STRICT** tables for new schemas.
- Migrations: explicit schema in `ensure_db()` or migration scripts.

## Performance and memory

**Gate:** recommend optimizations below only with profiling, benchmarks, or a documented hot path.

### Profiling

| Tool | Use when |
|------|----------|
| **`cProfile`** | Exact call counts and cumulative time; local dev |
| **Pyinstrument** | Statistical snapshots; lower overhead; production-like runs |
| **Linux `perf`** | Python 3.12+; hardware/kernel events; system-wide bottlenecks |

Run a profiler before recommending `__slots__`, PyO3, Cython, or concurrency rewrites.

### Algorithmic complexity

- Hot paths: `set` / `dict` for O(1) lookups; avoid `x in list` on large or frequent checks.
- Critical paths: optional scaling tests (input size vs time) to catch regressions.

### `__slots__`

For data-heavy classes with **many instances** and measured memory pressure:

```python
class Point:
    __slots__ = ("x", "y")

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y
```

Tradeoff: no dynamic attributes; plan subclass `__slots__` carefully.

### Garbage collection (Python 3.14+)

Incremental GC reduces stop-the-world pauses — relevant when upgrading runtime for latency-sensitive servers.

## Concurrency (Python 3.14+)

**Gate:** only recommend if deployment targets Python 3.14+ (check `pyproject.toml`, CI, runtime).

| Approach | When to consider |
|----------|------------------|
| **Free-threaded Python** (GIL optional) | CPU-bound threading without multiprocessing overhead |
| **Parallel subinterpreters (PEP 734)** | Isolated states; lower overhead than processes for some tasks |
| **asyncio** | I/O-bound concurrency |
| **multiprocessing** | CPU-bound when threads/subinterpreters are unsuitable |

Many projects still run 3.9–3.12 — do not assume 3.14 features.

## Environment tooling

**uv** (new projects only):

```bash
uv venv
uv pip install -r requirements.txt
uv run pytest
```

Existing repos: keep `pip` / `.venv` unless migration is explicitly requested.

## Observability (Loguru)

When the project uses Loguru:

```python
from loguru import logger

logger.bind(request_id=req_id).info("processed", count=n)
```

Prefer JSON in production; `print()` only for CLI user-facing output.

## Explicit failures (Rust-inspired)

```python
def find_user(user_id: int) -> User | None:
    ...
```

## Cross-language: Rust via PyO3

**Gate:** profile first; Python/NumPy is the default until proven insufficient.

- Extract CPU-critical inner loops to Rust via **PyO3**
- Fuse passes; benchmark before committing
- Keep the Python boundary thin

## Cython (CPU-bound Python)

**Gate:** same as PyO3 — profile first; prefer pure Python until proven insufficient.

- **Cython 3.0+ pure Python mode**: annotate existing Python; keeps lint/type tools usable while compiling hot paths
- Use when Rust/PyO3 is too heavy but inner loops still dominate after profiling

## APL-inspired style (optional)

Not a dependency — patterns that reduce branching in numeric/data code:

- Data-driven conditionals: `count += (age > 17)` instead of nested `if` chains where readable
- Prefer `sum`, `any`, `all`, and `functools.reduce` over manual accumulation loops

## CLI architecture

```
cli.py          # argparse only, dispatches to workflows
workflows/      # orchestration
jobs/ or domain/  # business rules
db/             # persistence
managers/       # cross-cutting orchestration
```

## LLM optional paths

- Graceful fallback when local model path missing.
- Thin wrapper (`LocalLLM`); workflows depend on interface, not backend.
- Local stacks (Ollama, llama.cpp): prefer tool calling to ground responses in project code.

## Anti-patterns

- Monolithic 500+ line modules mixing SQL, parsing, and CLI
- Stub modules duplicating real implementations
- Temporary `fix_*.py` scripts left after refactor
- Premature `__slots__`, PyO3, Cython, or 3.14 concurrency without profiling/version fit
