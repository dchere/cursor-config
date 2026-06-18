---
name: system-architecture
description: >-
  System design guidance: SOLID, Polylith monorepos, boundaries, concurrency
  tradeoffs, and cross-language integration. Use when designing modules,
  services, monorepos, or when the brain agent is active.
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

1. **Context** — problem, constraints, assumptions
2. **Options** — brief comparison
3. **Recommendation** — chosen approach and why
4. **Boundaries** — modules/services, interfaces, data ownership
5. **Risks** — migration path if refactoring
6. **Documentation** — exact companion `.md` files to update when behavior or boundaries change (from project rules if present)

## Diagrams

For non-trivial flows, use mermaid. Keep diagrams small.

## Patterns to favor

- **SRP**: one reason to change per module (e.g. separate file I/O from compression logic)
- **Composition over inheritance**: prefer "has-a" over "is-a"; swap component policies at runtime instead of deep subclass trees
- **OCP via ABCs/protocols**: fixed interfaces; extend with new types, not edits to stable core
- Repository/data layer isolated from business rules
- Thin entry points delegating to workflows
- Typed configuration, not ad-hoc dicts
- **OCP / LSP**: extend via protocols/ABCs; subtypes honor contracts

## SOLID (quick reference)

| Principle | Practical check |
|-----------|-----------------|
| **SRP** | One reason to change per module/class |
| **OCP** | Extend via new types, not edits to stable core |
| **LSP** | Subtypes interchangeable without surprises |
| **ISP** | Small, focused interfaces |
| **DIP** | Abstractions at boundaries (DB, LLM, APIs) |

## Concurrency decision

Record explicitly:

1. **Workload** — I/O-bound vs CPU-bound vs mixed
2. **Runtime** — Python version deployed (3.14+ features require verification)
3. **Choice** — asyncio / threading / multiprocessing / subinterpreters
4. **Rationale** — why not the alternatives

Details for Python: `python/reference.md` concurrency section.

## AI-assisted architecture

- Structure quality affects AI output quality — design for clarity before scaling AI use.
- For developer-side AI workflow (prompts, review passes): see **`developer-workflow`** agentic section.

## Monorepo layout

When managing a large Python monorepo, consider **Polylith**: reusable **bricks** (components) and **bases** (entry assemblies) with explicit dependency rules. Prefer this over ad-hoc package sprawl when many services share domain code.

## Cross-language integration

**Gate:** profile Python first; consider Rust/PyO3 or Cython only for proven CPU bottlenecks.

- Thin language boundary; explicit error/ownership contracts
- Rust mindset: ownership at boundaries; `Result`-like returns (`User | None`) for expected failures
- See `python/reference.md` for PyO3, Cython, and profiling gates

## Boundaries

- Do not implement code unless the user asks.
- Leave room for project conventions.
- Apply language skills (e.g. `python`) for stack-specific details.
