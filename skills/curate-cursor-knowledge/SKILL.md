---
name: curate-cursor-knowledge
description: >-
  Integrates user input into cursor-config skills or agents with routing, dedup,
  and portability checks. Use when persisting standards, lessons, or docs into
  ~/projects/cursor-config skills/agents.
disable-model-invocation: true
---

# Curate Cursor Knowledge

Use when the user provides **concentrated input** to preserve across projects.

**Repo:** `~/projects/cursor-config/` (symlinked from `~/.cursor/skills` and `~/.cursor/agents`).

**Never edit** `~/.cursor/skills-cursor/`.

## Workflow

### 0. Parse input

- Identify sections and implied roles (Architect, Developer, Reviewer).
- List candidate target files before editing.

### 1. Route content (required)

| Content type | Primary home | Secondary |
|--------------|--------------|-----------|
| SOLID, boundaries, concurrency *choice*, inheritance tests, sagas, outbox, observers, Builder, durable workflows, retry bounds, diagrams, SSE/morphing, plugin REST probes, WSGI/ASGI split, Timescale/Neo4j batching | `system-architecture` | `python` (ABC/MRO) |
| Python perf, typing, SQLite, tooling, serialization, logging, mocking, CPython internals (scope/`UnboundLocalError`, `WeakKeyDictionary`), ABC/`super()`/`__mro__`, 3.15 language/profiler | `python` / `reference.md` | — |
| Review checks, severity format, CSRF GET-must-be-safe, SCA reachability | `code-review` | link to `python` |
| How to implement, AI collaboration, integration tests, forensic debug, AX, dialogue-then-build | `developer-workflow` | `idea-sparring` (dialogue only) |
| User-facing reply shape (action-first, numbered steps, no preamble) | `developer-workflow` Output style | role Output sections (order only; never a separate skill) |
| LLM serving gateway, registry provenance, edge manifests | `python/reference.md` | `developer-workflow` (pointer only) |
| Agent-product MCP, workflow-vs-loop, tool-boundary security, HITL, bounded agent loops | `developer-workflow` | `python/reference.md` (OAuth, flight recorder) |
| Landlock / OS sandbox | `python/reference.md` | `system-architecture` (containers) |
| Agent behavior, skill invocation | `agents/dev`, `cr`, `brain`, `critic`, `tester`, `dima` | — |

A duplicate of a topic that already has a home is not a new skill.

### 1b. No home yet

When a skill, an agent, a language, a technology, an architecture decision, or a practice has no section in the files that were read, do not omit it and do not create a file or a section for it on this pass.

Read the routing table, **developer-workflow** Order, Who may change what, and the agent files. Propose, and do not edit yet:

- **Main idea** — the rule or role the source wants
- **Store** — the new skill, agent, or section it would live in
- **Pros** — what the current files cannot say
- **Cons** — the existing role or section that already covers part of it
- **Fit** — the file it would sit beside, or that no file covers it

The user decides. On apply, add that file or section. A new language uses the `python/` layout, `SKILL.md` plus an optional `reference.md`, only after that apply. On refusal, the curation report lists it as declined, with the reason they gave. "No suitable home" is not a reason to omit it and not a reason to store it.

Content that already has a row in the routing table still merges under **3**. A conflict with text already in that home is surfaced and not overwritten.

### 2. Read current files

Read all target files in `cursor-config` before merging.

### 3. Merge

- Compress report prose to **actionable bullets** — do not paste verbatim.
- **One canonical home** per concept; elsewhere use a one-line cross-link only.
- Keep each `SKILL.md` under **500 lines**; depth goes in `reference.md`.
- Update YAML `description` with role triggers, not tool laundry lists.

### 3b. Qualifiers (required)

Add **when** guards for:

- Performance (`__slots__`, algorithmic changes)
- Rust / PyO3
- Python 3.14 concurrency features / free-threading internals
- CPython rebuilds (frame pointers, JIT)
- New tooling (uv, Loguru, Datastar, Marimo, Great Tables, Arcjet, MLflow, Temporal, msgspec, OTel, Landlock, Cosign, Timescale, Neo4j) — always: *"if project already uses X, follow X; do not introduce unprompted"*

### 3c. Portability (required)

- No project-specific names (`spejder`, repo paths) in global skills.
- OS-specific notes (e.g. macOS `python3`) go in `reference.md`, not main `SKILL.md`.
- Project-only rules → project `.cursor/rules/` or project docs, not `cursor-config`.

### 3d. Dedup pass (required)

Before finishing, scan for repeated concepts (Pydantic, uv, agentic AI, O(1) lookups) across files. Keep one canonical section; remove duplicates.

### 4. Sync agents

If skill boundaries or skill names change, update **dev**, **cr**, **brain** "When invoked" skill lists if affected.

### 5. Curation report (required output)

```markdown
## Curation report
- **Files changed:** ...
- **Canonical homes:** concept → file
- **Proposed** (no home yet, awaiting a decision): main idea, where it would be stored, pros, cons, fit
- **Declined:** what the user refused, and the reason they gave
- **Omitted** (and why): ... A missing home is not an omission reason, and it is not a reason to create a file.
- **Duplicates removed:** ...
- **Agents updated:** yes/no
- **Line counts:** SKILL.md before → after (if significant)
```

### 6. Commit reminder

```bash
cd ~/projects/cursor-config && git diff && git add -A && git commit -m "..."
```

## Merge rules

- Do not duplicate Cursor **User Rules** verbatim.
- On conflict with existing skill text, surface it in the report — do not silently overwrite.
- A skill, agent, language, technology, architecture decision, or practice with no section yet is a proposal under **1b**. Do not drop it, and do not create its file, while looking for an existing place to edit.
- Do not add review checklist items that cannot be verified from a typical diff alone.
- For a new language the user has accepted, copy the `python/` layout: `SKILL.md` plus an optional `reference.md`.

## Example invocations

- "Use curate-cursor-knowledge: add rule X to python skill"
- "Integrate this checklist into code-review"
- "Create a java skill from this document"
