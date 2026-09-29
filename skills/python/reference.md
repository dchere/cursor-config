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
| **`profiling.sampling`** (Tachyon, 3.15+) | Default sampler: ~zero overhead; `attach` by PID; `--async-aware`, `--native` |
| **`profiling.tracing`** / **`cProfile`** | Exact call counts (3.15: `cProfile` is an alias; `profile` is deprecated → 3.17) |
| **Pyinstrument** | Statistical snapshots on **<3.15** or when already in the project |
| **Linux `perf` / eBPF** | Hardware/kernel events; system-wide. **3.15+** CPython ships frame pointers by default (PEP 831) and exports them via `sysconfig` so extensions inherit the chain. Do not rebuild CPython on 3.15+ unless a custom build is already the task. Opt out with `--without-frame-pointers` only when profiling is out of scope and throughput is measured. |

**3.15 sampling modes** (pick one bottleneck): `--mode wall` (elapsed, default), `cpu` (active CPU), `gil` (lock hold), `exception` (in-flight errors). Outputs: `--flamegraph`, `--heatmap`, `--gecko` (Firefox Profiler), `--collapsed`, `--pstats`. Differential flame graphs only when comparing two recordings of the same workload.

Do not recommend Tachyon on 3.14-or-older runtimes.

### Attribute access

Python 3.11+: `vars(obj)`, reading `__dict__`, `'attr' in obj.__dict__`, or `copy.copy(obj)` on an instance deopts specialized `LOAD_ATTR` to a generic lookup (up to ~3× slower after). Do not do this on hot-path objects. Diagnostic dumps belong in one-off scripts, not request loops. Do not add `__slots__` without a profile.

Do not hang metadata on live objects as dynamic attributes (`obj._meta = …`) — collisions, `__slots__`, and `vars()` leaks. For object→data maps that must not keep objects alive, use `WeakKeyDictionary`. `@functools.cache` holds **strong** refs to arguments (leak risk on unbounded unique keys).

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

When **actually targeting free-threaded CPython** (`python3.14t` / 3.15+ GIL-less; not "we might someday"):

- **PyMutex** for short critical sections — do not assume the GIL serializes everything.
- **Biased / deferred refcounting** (QSBR): owner-thread fast path; foreign threads use atomics. C extensions that assume GIL-protected refcounts need an audit.
- C extensions must set `Py_mod_gil = Py_MOD_GIL_NOT_USED`. An un-flagged import **re-enables the GIL process-wide**.
- **CPython JIT**: Steering Council moratorium pending a formal PEP. Do not enable JIT in production unless the project's runtime already does. Any JIT recommendation must address maintenance, free-threading compatibility, and measurable success metrics.
- **`asyncio.all_tasks()`**: from a non-loop thread, eager tasks can be missing (creation race). Query from the loop thread, or track tasks you spawn.
- Do not cite unverifiable core-scaling numbers; measure the actual workload.

**Python 3.16+:** `yield from` inside async generators is valid (PEP 828); `StopAsyncIteration.value` carries the subgenerator result. Do not use on 3.15-or-older.

## Live diagnostics (gated)

One-off debugging of a running process — not production request paths:

- Hung process: `python -m profiling.sampling dump --async-aware <pid>` (3.15+)
- In-memory instances: `gc.get_objects()` filtered with `isinstance` — do not leave in hot paths (also trips `__dict__` deopt if you poke attributes via `__dict__`)

## AST transforms (gated)

Use the **`ast`** module to parse/rewrite/compile Python only when the task is a **code transform** (auto-tracing spans around function bodies, annotation syntax backports). Do not use AST rewriting for ordinary features.

## Environment tooling

**uv** — new projects, or existing repos that already use it:

```bash
uv venv
uv lock && uv sync
uv run pytest
```

Existing pip repos: keep `pip` / `.venv` unless migration is explicitly requested. Do not mix `uv` and `pip` in the same project.

Publishing: do not upload new files to an existing PyPI version after the 14-day window; prefer attestations when the project already publishes them. Hardware-specific wheels (GPU / ISA): follow existing installer support for wheel variants — do not invent variant filenames.

## Observability (Loguru)

When the project uses Loguru:

```python
from loguru import logger

logger.bind(request_id=req_id).info("processed", count=n)
```

Prefer JSON in production; `print()` only for CLI user-facing output.

Root-logger and lazy-interpolation rules: **`python`** Observability section (stdlib). Loguru uses bound context, not `%s` args.

## Serialization

- Never `pickle.load` / `pickle.loads` on untrusted bytes (RCE).
- Prefer **msgspec** for fast typed binary/JSON codecs, or JSON/`pydantic` at existing boundaries.
- Do not wrap attacker-controlled strings in `__raw_json__` / `RawJSON` or concatenate them into JSON (injection). Recognize `__json__` only if the runtime already implements that protocol; do not add it unprompted.
- Follow the project's current serializer; do not add msgspec unprompted.

## Data workflows (gated)

- **Marimo**: when the user wants git-friendly notebooks (clean `.py`, top-to-bottom, automatic deps). Do not migrate Jupyter unprompted.
- **Great Tables**: when producing publication-quality tables from pandas/Polars (currencies, dates, sparklines) in a script. Do not add it for ordinary DataFrame prints.
- **Pointblank**: tabular checks (`rows_distinct`, missing-value reports) only if the project already uses it or the user asks. Do not add it unprompted.
- **Polars streaming on multi-socket machines**: work-stealing can cross NUMA nodes — pin/limit threads if profiling shows cross-node stalls. Only when the workload is already Polars streaming at that scale.

## Django (gated)

Only if the project already uses Django. Do not introduce Django.

- Race-free updates: `F()` expressions, not read-modify-write in Python.
- Tests: `setUpTestData` for class-scoped fixtures (once per class).
- Django 6.x: async ORM/cache/auth/sessions/signals are in-tree. 6.1: prefer `on_delete=models.DB_CASCADE` over Python-side cascades; `fetch_peers` when the PR introduces N+1 related access. 6.0 Tasks: only if the project has no worker stack yet — do not migrate Celery unprompted.
- **django-crawl**: optional route crawl (broken links, unhandled exceptions, CSP) only if already in the test suite or the user asks.

## Config (gated)

**Hydra** (`@hydra.main`, config groups, `--multirun`): only if the project already uses it or the user asks. Do not migrate `pydantic`/JSON config to Hydra unprompted.

## Explicit failures (Rust-inspired)

```python
def find_user(user_id: int) -> User | None:
    ...
```

## Cross-language: Rust via PyO3

**Gate:** profile first; Python/NumPy is the default until proven insufficient.

- Extract CPU-critical inner loops to Rust via **PyO3** (wheels via **Maturin** if the project already uses it)
- Fuse passes; pass **batches** (frames, full JSON), not per-row micro-calls (Amdahl / FFI cost)
- Benchmark before committing; keep the Python boundary thin
- Third integration mode: native process hosting Python sub-interpreters (e.g. Granian) — only if the project already deploys that way

## Cython (CPU-bound Python)

**Gate:** same as PyO3 — profile first; prefer pure Python until proven insufficient.

- **Cython 3.0+ pure Python mode**: annotate existing Python; keeps lint/type tools usable while compiling hot paths
- Use when Rust/PyO3 is too heavy but inner loops still dominate after profiling

## APL-inspired style (optional)

Not a dependency — patterns that reduce branching in numeric/data code:

- Data-driven conditionals: `count += (age > 17)` instead of nested `if` chains where readable
- Prefer `sum`, `any`, `all`, and `functools.reduce` over manual accumulation loops

## Testing extras (gated)

Use only if already a dependency or the user asks. Do not add these unprompted.

- **pytest-httpx**: mock `httpx` at transport (no VCR required).
- **vcrpy**: record once, replay in CI with `record_mode="none"`.
- **syrupy**: snapshot complex JSON when the project already snapshots.
- **freezegun**: put `@freeze_time` on the test function (not a distutils-bound wrapper).
- **pytest-randomly**: shuffle order to catch shared-state leaks.

**Characterization / differential:** before a legacy rewrite, lock current I/O and exceptions. Run old and new behind one adapter; strip dynamic IDs and timestamps before comparing.

**Agent products** (tool tests without calling a model; mocked tool I/O for the loop; scheduled E2E evals): **`developer-workflow`**.

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

**Serving / LLMOps (gated)** — only when the product routes, serves, or ships models:

- **Gateway**: semantic version → weight location; hot-swap in memory (avoid frozen paths / "model rot").
- **Registry**: single source of truth. Bind weights to **provenance** (training code version, dataset hash, hyperparameters) so regressions can be traced. Prompt registry for template versions. Use **MLflow** (or the project's existing tracker) — do not introduce MLflow if there is no MLOps stack.
- **Edge** (gated): when shipping weights to devices, a **manifest** (lockfile for artifacts) should drive targeted **delta** downloads — not full recopies on every update.
- Multi-step model tasks: an evaluation harness (correctness, coverage, format), not informal spot checks. Prompting tactics (including CoT) are product choices, not architecture requirements.
- **Per-user OAuth**: never a shared bot token for user actions. Store encrypted user tokens keyed by a server-side id; inject at the tool boundary. The model must not see raw tokens.
- **Flight recorder** (if the product already traces): span per tool step (`trace_id`, `agent`, `tool`, duration, tokens, cost, status). Do not add TimescaleDB unprompted — use the project's existing store.
- Provider **fallback** only if the product already has multiple providers. Compact long histories (summarize + trim tool output); persist turns as JSONL if the product already audits sessions. Long-term recall: retrieve from the product's existing vector or SQL store — do not add a vector DB unprompted.

## Linux sandbox (gated)

Only when the task is hardening a Linux agent/tool process **and** the user asks or the project already sandboxes. Do not add Landlock to ordinary apps.

**Landlock LSM** (unprivileged self-restriction): `PR_SET_NO_NEW_PRIVS` first; then create ruleset → add path rules (`O_PATH`) → `landlock_restrict_self`. Rules only narrow. Exec inside the sandbox needs read+execute for the binary, interpreter, and libs (`/usr`, `/lib`). Containers: **`system-architecture`**.

## Anti-patterns

- Monolithic 500+ line modules mixing SQL, parsing, and CLI
- Stub modules duplicating real implementations
- Temporary `fix_*.py` scripts left after refactor
- Premature `__slots__`, PyO3, Cython, or 3.14 concurrency without profiling/version fit
- `pickle` for untrusted or cross-trust data
- `os.path.commonprefix()` for filesystem/URL containment (use `os.path.commonpath()`)
- Reading `__dict__` on hot-path instances (3.11+ attribute deopt)
- Mutable DB/HTTP/cache clients at module global
- Patching a dependency at definition (`requests.get`) when the SUT imported a local name
