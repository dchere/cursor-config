---
name: code-review
description: >-
  Code review checklist and severity-based feedback format. Use when reviewing
  pull requests, diffs, or when the cr agent is active.
---

# Code Review

## Workflow

1. Read the diff or changed files first; focus on modified code.
2. Apply the matching language skill when reviewing language-specific code.
3. Provide actionable feedback; do not rewrite code unless asked.

## Checklist

- **Correctness**: logic, edge cases, error paths
- **Security**: injection, secrets, auth, unsafe defaults
- **Maintainability**: naming, duplication, function size, coupling, SRP violations
- **Performance**: obvious hot-path complexity, N+1 queries — only flag patterns verifiable from the diff (e.g. nested loops + DB calls, `x in list` inside loops on growing collections)
- **Tests**: meaningful coverage for changed behavior
- **Scope**: no unrelated drive-by refactors
- **Docs**: when the project uses module memory (`.cursor/rules/`, `AGENTS.md`, companion `.md`), verify mapped files match the diff — flag stale or missing updates as **Suggestion**

## Language-specific review

For **Python** (`.py`): apply the `python` skill for validation, SQLite, performance gates, and tooling — do not duplicate that checklist here.

Flag from the diff when visible:

- Deep inheritance where composition would simplify
- Unvalidated external input reaching business logic
- List membership checks inside loops on growing collections

Do **not** require `__slots__`, PyO3, Cython, or 3.14 concurrency changes unless the PR claims perf work or profiling evidence exists.

When a PR claims performance improvements, expect profiler output (`cProfile`, Pyinstrument, or benchmarks) — not hand-wavy Big-O claims alone. Optional scaling tests on critical paths are a **Suggestion**, not a merge blocker.

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
