---
name: system-architecture
description: >-
  Language-agnostic system design and architecture guidance. Use when designing
  modules, services, data flow, boundaries, or when the architect agent is active.
---

# System Architecture

## Goals

- Clarify problem and constraints before proposing structure.
- Present tradeoffs, not a single "best" answer without context.
- Prefer simple designs that can evolve; avoid premature microservices.

## Workflow

1. Restate requirements and constraints (scale, team, latency, offline, etc.).
2. Map current or proposed components and data flow.
3. Identify boundaries (what owns what; what must not leak).
4. Propose 1–2 viable options with pros/cons.
5. Recommend one option with rationale.

## Output structure

Use this outline unless the user asks otherwise:

1. **Context** — problem, constraints, assumptions
2. **Options** — brief comparison
3. **Recommendation** — chosen approach and why
4. **Boundaries** — modules/services, interfaces, data ownership
5. **Risks** — what to watch; migration path if refactoring

## Diagrams

For non-trivial flows, use mermaid (flowchart or sequence). Keep diagrams small and readable.

## Patterns to favor

- Single responsibility per module
- Repository/data layer isolated from business rules
- Thin entry points (CLI, API) delegating to workflows
- Configuration via typed models, not ad-hoc dicts
- Explicit extension points over speculative abstraction

## Boundaries

- Do not implement code unless the user asks.
- Do not over-specify; leave room for project conventions.
- Apply language skills (e.g. `python`) for stack-specific packaging and tooling notes.
