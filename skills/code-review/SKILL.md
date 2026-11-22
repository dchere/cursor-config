---
name: code-review
description: >-
  Code review checklist and severity-based feedback format for PRs and diffs,
  including AI-generated code, evidence-grounded findings, Python security/style
  flags, and supply-chain/auth checks. Use when reviewing pull requests, diffs,
  or when the cr agent is active.
---

# Code Review

## Workflow

1. Read the diff or changed files first; focus on modified code.
2. Apply the matching language skill when reviewing language-specific code.
3. Judge **test meaningfulness**, not only that tests exist or are green.
4. Provide actionable feedback; do not rewrite code unless asked.

## Before posting a finding

Match review depth to the PR (auth/CI → security; loops/ORM → perf; behavior change → tests). Do **not** spawn extra reviewer agents.

1. **Ground:** open the caller and import of the changed symbol; do not comment from the hunk alone.
2. **Cluster:** if changed files share a call path or import, review the interaction, not each file in isolation.
3. **Falsify:** try to invalidate using existing guards, framework defaults, or missing evidence. If it fails this gate, drop it or mark **Nice to have**.

## Checklist

- **Correctness**: logic, edge cases, error paths
- **Security**: injection, secrets, auth, unsafe defaults, `pickle` on untrusted data, cleartext `http://` client URLs
- **Maintainability**: naming, duplication, function size, coupling, SRP violations, composition vs deep inheritance
- **Performance**: obvious hot-path complexity, N+1 queries — only flag patterns verifiable from the diff (e.g. nested loops + DB calls, `x in list` inside loops on growing collections)
- **Tests**: meaningful coverage for changed behavior; a new outcome has a test that states it; integration coverage when a boundary (API, DB, queue) changed; mocks that actually intercept. An existing use-case test edited so new behavior passes is **Critical** unless the user chose that new outcome.
- **Scope**: no unrelated drive-by refactors
- **Docs**: ADR and scenario-test rules are **developer-workflow**. A **Scenario gap** or **Extra behavior** is not a Suggestion to implement. A stale code map is **Suggestion**.

## Language-specific review

For **Python** (`.py`): apply the `python` skill for validation, methods, logging, SQLite, serialization, and performance gates — do not duplicate that checklist here.

Flag from the diff when visible:

- Deep inheritance where composition (or `@property`) would simplify
- `os.path.commonprefix()` used as a path/URL containment check (**Critical** if it gates authz; otherwise **Suggestion** — use `os.path.commonpath()`)
- Newly added third-party GitHub Action `uses:` without a 40-character commit SHA (**Critical**); floating tags on workflows the PR already touches (**Suggestion**)
- `.github/dependabot.yml` added or edited with no update cooldown (**Suggestion** — e.g. 7 days; do not add Dependabot to a repo that lacks it)
- Unvalidated external input reaching business logic
- `GET` (or other safe-method) handlers that mutate state (**Critical** — CSRF via image/link; mutations belong on POST/PUT/PATCH/DELETE)
- OAuth authorization-code flow missing PKCE (`code_challenge`) or CSRF `state`, or long-lived refresh tokens stored in the browser / localStorage (**Critical** — only if the PR implements OAuth)
- Session-cookie auth without a CSRF token or `SameSite=Lax`/`Strict` (**Suggestion** — only if the PR implements cookie sessions)
- Assignment to a name later in the same function after an earlier read, or use after an `if` assignment with no `else`/default (**Suggestion** — `UnboundLocalError`; **`python`** Scoping)
- `__init__` that performs I/O or network (**Suggestion** — **`python`** Scoping)
- `global` used to mutate module state (**Suggestion** — **`python`** Scoping)
- `@functools.cache` / `lru_cache` on unbounded unique object keys (**Suggestion** — strong refs; **`python/reference.md`**)
- `INSERT` then publish to a queue as two uncorrelated writes (**Suggestion** — only if the PR implements that flow; **`system-architecture`** outbox)
- Service worker / Web Push added without `worker-src` / `connect-src` in CSP (**Suggestion**)
- Attacker-controlled strings passed to `__raw_json__`, `RawJSON`, or concatenated into JSON (**Critical** — bypasses structural escaping)
- `vars(obj)`, `obj.__dict__`, `'x' in obj.__dict__`, or `copy.copy(obj)` on instances in a hot path (**Suggestion** — 3.11+ attribute deopt; do not demand `__slots__` without a profile)
- `asyncio.all_tasks()` called from a non-loop thread (**Suggestion** — free-threading omits eager tasks)
- `asyncio.Event` / `Condition` used as a multi-waiter value bus (**Suggestion** — `system-architecture` async shared state)
- `Mock()` on an `async def` (use `AsyncMock`) (**Suggestion**)
- Session-scoped async pytest fixtures without a matching event-loop scope (**Suggestion**)
- `lazy from x import *` (**Critical** if targeting 3.15+ — invalid)
- List membership checks inside loops on growing collections
- `pickle` load/dumps on untrusted or cross-trust data (**Critical**)
- Cleartext `http://` for network clients that should be `https://` (**Critical** if it is a real client URL)
- Library code reconfiguring the root logger, or eager log formatting via f-strings / `.format()` inside `logging` calls (**Suggestion**)
- `unittest.mock.patch` at the definition site (`requests.get`) when the SUT imported a local name (**Suggestion**)
- `@staticmethod` that uses neither `self` nor `cls` — prefer a module-level function unless class namespace is intentional (**Suggestion**)
- `@classmethod` used for ordinary instance behavior (**Suggestion**)
- Boundary (API/DB/queue) change with only unit tests and no integration coverage (**Suggestion**)
- Multi-step distributed write without a compensating/rollback path, or compensations that are not idempotent / not reverse-order (**Suggestion** — only if the PR is implementing that flow)
- Hardcoded production prompts scattered in call sites on an LLM-serving change (**Suggestion** — prefer config/registry; see `python/reference.md`)
- New coding-agent / developer-tool surface with no `llms.txt` or MCP affordance (**Nice to have** — AX only)
- Mutable DB/HTTP/cache clients at module global on a request path (**Suggestion**)
- Agent tool that logs or prompts raw OAuth/API tokens, or a shared bot token for per-user actions (**Critical** — only if the PR implements agent tools)
- Agent tool whose only security is a system-prompt instruction (no code validation at the boundary) (**Suggestion** — agent-product PRs)
- New C extension on a free-threaded runtime without `Py_MOD_GIL_NOT_USED` (**Suggestion** — GIL re-enabled process-wide)

Do **not** require:

- Rewriting `Annotated[...]` to proposed `@` metadata shorthand
- `__slots__`, PyO3, Cython, frame-pointer CPython builds, or 3.14 concurrency without evidence in the PR
- Migrating the repo to **uv**, **Datastar**, **Marimo**, **Temporal**, **Arcjet**, **Hydra**, **Hypothesis**, or an LLM **Gateway** unless the PR already targets that stack
- `profiling.sampling`, `lazy import`, or `frozendict` unless `requires-python` / CI already includes 3.15+
- Frozen display syntax (`f{…}`), `from module export`, `__json__` protocols, zizmor, rapidlog, turbohtml, django-crawl, or replacing Celery with Django Tasks
- Spawning ephemeral reviewer sub-agents, specialist fan-out, confidence scores, a HITL queue, or an AST pipeline as a merge gate (Cursor CR stays sequential)
- Landlock, Cosign, Kyverno, Falco, OTel, Semgrep, Trivy, Syft, actionlint, or the rest of a DevSecOps matrix unless the PR already uses that tool

When a PR claims performance improvements, expect profiler output (`profiling.sampling` on 3.15+, else `cProfile` / Pyinstrument, or benchmarks) — not hand-wavy Big-O claims alone. Optional scaling tests on critical paths are a **Suggestion**, not a merge blocker.

## Domain-gated suggestions (never merge blockers)

Only when the PR’s domain matches; keep severity at **Suggestion** or **Nice to have**; link skills instead of inventing requirements:

| If the PR … | Suggest (gated) | Canonical |
|-------------|-----------------|-----------|
| Adds long-running / multi-step distributed work | Compensating steps; durable event history if already orchestrating | `system-architecture` |
| Dual-writes a DB row and a queue message | Same-transaction outbox; `SKIP LOCKED` if multiple relays; idempotent consumer | `system-architecture` |
| Writes time-series into existing Timescale | Hypertables + time-bounded queries; continuous aggregates | `system-architecture` |
| Writes many Cypher rows into existing Neo4j | `UNWIND` batch, not one statement per row | `system-architecture` |
| Surfaces SCA/CVE counts | Reachability before treating as Critical | `code-review` |
| Adds cookie-session auth | CSRF token + `SameSite`; GET stays read-only | `code-review` |
| Serves / routes LLM models | Gateway + prompt/model registry instead of frozen paths / hardcoded prompts | `python/reference.md` |
| Builds tools for other coding agents | `llms.txt`, MCP, installable skills (AX) | `developer-workflow` |
| Adds bot/signup/PII protection | In-process / WASM-local analysis; project security SDK if already used | `developer-workflow` |
| Adds Jupyter for data workflows | Marimo only if git-friendly notebooks are in scope | `python/reference.md` |
| Adds realtime UI on a Python app | Datastar only if hypermedia/SSE is already preferred | `developer-workflow` |
| Touches Django ORM updates / test fixtures | `F()` for races; `setUpTestData` for class fixtures; Django 6.1: `DB_CASCADE` / `fetch_peers` if the PR does Python-side cascades or N+1 | `python/reference.md` |
| FastAPI + existing TS client | OpenAPI-generated types | `developer-workflow` |
| Edits GitHub Actions workflows | Pin new third-party actions to commit SHA | `developer-workflow` |
| Edits Dependabot config | Update cooldown (e.g. 7 days) | `developer-workflow` |
| Implements OAuth/OIDC | PKCE + `state`; refresh tokens server-side | `code-review` flags above |
| Adds Web Push / service worker | CSP `worker-src` and `connect-src` | `code-review` flags above |
| Publishes to an existing PyPI version | No new files after the 14-day window | `python/reference.md` |
| Adds a parser/serializer and Hypothesis is already a dep | Property-based tests for that boundary | `python` |
| Registers external plugins / model nodes | Shared HTTP schema; probe on register; reject unparseable payloads | `system-architecture` |
| “Fixes” a slow query by adding async/threads | Query plan and indexes first | `system-architecture` |
| Adds SSE/WebSockets to a WSGI-only deploy | ASGI sidecar — only if not already unified ASGI | `system-architecture` |
| Adds agent tools that call user APIs | Per-user OAuth; no shared bot token; no tokens in the prompt | `python/reference.md` |
| Adds a Dockerfile / K8s manifest | Non-root, read-only root, cap-drop if the project already hardens this way | `system-architecture` |
| Rewrites legacy behavior | Characterization tests before the swap | `python` |

## AI-generated and bugfix lenses

- **AI-generated diffs**: look for missing edge cases, weak or absent runnable tests, and boundary coverage gaps relative to the `developer-workflow` implementation loop. Do not demand a ritual write-up of the seven steps — demand the evidence (rules/constraints reflected in tests and increments).
- **Compound / cross-file findings**: follow **Before posting** (ground, cluster, falsify). Cite the concrete path. If it cannot be falsified from repo files, drop it or mark **Nice to have**.
- **Bugfix PRs** without clear root cause: recommend **`diff`ing logs/artifacts** from a successful baseline vs the failing run (**Suggestion** / **Nice to have**) — see `developer-workflow` forensic debugging. Do not block merge solely for missing a log diff.

## Severity labels

- **Critical**: must fix before merge (bugs, security, broken behavior)
- **Suggestion**: should improve (clarity, design, missing tests)
- **Nice to have**: optional polish

## Feedback format

Delivery wrapping: **developer-workflow** Output style. Lead with the highest-severity finding, or "no Critical — ready to merge" if none.

For each issue:

1. Location (file / function)
2. What is wrong or risky
3. Concrete fix suggestion

Show at most 5 findings in the lead list; further items go under Later / Nice to have.

End with overall assessment, merge recommendation if appropriate, and one next action (first Critical to fix, or commit).

## Boundaries

- Do not implement fixes unless the user asks.
- Do not nitpick style already enforced by project linters.
- Praise good patterns briefly when relevant.
