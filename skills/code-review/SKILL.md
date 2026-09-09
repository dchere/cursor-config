---
name: code-review
description: >-
  Code review checklist and severity-based feedback format for PRs and diffs,
  including AI-generated code, meaningful tests, and Python security/style
  flags. Use when reviewing pull requests, diffs, or when the cr agent is active.
---

# Code Review

## Workflow

1. Read the diff or changed files first; focus on modified code.
2. Apply the matching language skill when reviewing language-specific code.
3. Judge **test meaningfulness**, not only that tests exist or are green.
4. Provide actionable feedback; do not rewrite code unless asked.

## Checklist

- **Correctness**: logic, edge cases, error paths
- **Security**: injection, secrets, auth, unsafe defaults, `pickle` on untrusted data, cleartext `http://` client URLs
- **Maintainability**: naming, duplication, function size, coupling, SRP violations, composition vs deep inheritance
- **Performance**: obvious hot-path complexity, N+1 queries — only flag patterns verifiable from the diff (e.g. nested loops + DB calls, `x in list` inside loops on growing collections)
- **Tests**: meaningful coverage for changed behavior; integration coverage when a boundary (API, DB, queue) changed; mocks that actually intercept
- **Scope**: no unrelated drive-by refactors
- **Docs**: when the project uses module memory (`.cursor/rules/`, `AGENTS.md`, companion `.md`), verify mapped files match the diff — flag stale or missing updates as **Suggestion**

## Language-specific review

For **Python** (`.py`): apply the `python` skill for validation, methods, logging, SQLite, serialization, and performance gates — do not duplicate that checklist here.

Flag from the diff when visible:

- Deep inheritance where composition (or `@property`) would simplify
- Unvalidated external input reaching business logic
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

Do **not** require:

- Rewriting `Annotated[...]` to proposed `@` metadata shorthand
- `__slots__`, PyO3, Cython, frame-pointer CPython builds, or 3.14 concurrency without evidence in the PR
- Migrating the repo to **uv**, **Datastar**, **Marimo**, **Temporal**, **Arcjet**, or an LLM **Gateway** unless the PR already targets that stack

When a PR claims performance improvements, expect profiler output (`cProfile`, Pyinstrument, or benchmarks) — not hand-wavy Big-O claims alone. Optional scaling tests on critical paths are a **Suggestion**, not a merge blocker.

## Domain-gated suggestions (never merge blockers)

Only when the PR’s domain matches; keep severity at **Suggestion** or **Nice to have**; link skills instead of inventing requirements:

| If the PR … | Suggest (gated) | Canonical |
|-------------|-----------------|-----------|
| Adds long-running / multi-step distributed work | Compensating steps; durable event history if already orchestrating | `system-architecture` |
| Serves / routes LLM models | Gateway + prompt/model registry instead of frozen paths / hardcoded prompts | `python/reference.md` |
| Builds tools for other coding agents | `llms.txt`, MCP, installable skills (AX) | `developer-workflow` |
| Adds bot/signup/PII protection | In-process / WASM-local analysis; project security SDK if already used | `developer-workflow` |
| Adds Jupyter for data workflows | Marimo only if git-friendly notebooks are in scope | `python/reference.md` |
| Adds realtime UI on a Python app | Datastar only if hypermedia/SSE is already preferred | `developer-workflow` |

## AI-generated and bugfix lenses

- **AI-generated diffs**: look for missing edge cases, weak or absent runnable tests, and boundary coverage gaps relative to the `developer-workflow` implementation loop. Do not demand a ritual write-up of the seven steps — demand the evidence (rules/constraints reflected in tests and increments).
- **Bugfix PRs** without clear root cause: recommend **`diff`ing logs/artifacts** from a successful baseline vs the failing run (**Suggestion** / **Nice to have**) — see `developer-workflow` forensic debugging. Do not block merge solely for missing a log diff.

## Severity labels

- **Critical**: must fix before merge (bugs, security, broken behavior)
- **Suggestion**: should improve (clarity, design, missing tests)
- **Nice to have**: optional polish

## Feedback format

For each issue:

1. Location (file / function)
2. What is wrong or risky
3. Concrete fix suggestion

End with a brief summary: overall assessment and merge recommendation if appropriate.

## Boundaries

- Do not implement fixes unless the user asks.
- Do not nitpick style already enforced by project linters.
- Praise good patterns briefly when relevant.
