---
name: system-architecture
description: >-
  System design guidance: SOLID, inheritance vs composition (reversibility/LSP),
  Polylith monorepos, sagas and durable workflows, realtime/SSE, LLM fleet
  boundaries, and cross-language integration. Use when designing modules,
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

- Use mermaid; keep diagrams small. Prefer several focused views over one “master” diagram that mixes every dependency.
- Prefer **sequence diagrams** for back-and-forth between resources (services, queues, DBs).
- Do not treat architecture diagrams generated from source as accurate — they hallucinate and over-abstract; review every edge.
- **Fan traps**: identity is lost when many producers collapse onto one broker topic. Restore paths with **resource-specific topics** (or routing keys), not a single shared channel.

## Patterns to favor

- **SRP**: one reason to change per module (e.g. separate file I/O from compression logic)
- **Composition over inheritance**: prefer "has-a" over "is-a"; swap **policies** at runtime instead of subclass trees (avoids **class explosion** when roles × policies multiply). Python: `@property` for derived/validated public attributes — see **`python`**.
- **Reversibility test**: if both "A is a B" and "B is an A" can be argued, inheritance is invalid — compose instead.
- **LSP**: if a subtype must ignore, no-op, or disable a base method, the hierarchy is wrong.
- **OCP via ABCs/protocols**: ABCs for formal implementation contracts; Protocols when structural typing is enough. Python MRO / `super()`: **`python`**.
- Repository/data layer isolated from business rules
- Thin entry points delegating to workflows
- Typed configuration, not ad-hoc dicts

## SOLID (quick reference)

| Principle | Practical check |
|-----------|-----------------|
| **SRP** | One reason to change per module/class |
| **OCP** | Extend via new types, not edits to stable core |
| **LSP** | Subtypes interchangeable without surprises; must not ignore or disable base methods |
| **ISP** | Small, focused interfaces |
| **DIP** | Abstractions at boundaries (DB, LLM, APIs) |

## Concurrency decision

Record explicitly:

1. **Workload** — I/O-bound vs CPU-bound vs mixed
2. **Runtime** — Python version deployed (3.14+ features require verification)
3. **Choice** — asyncio / threading / multiprocessing / subinterpreters
4. **Rationale** — why not the alternatives

Details for Python: `python/reference.md` concurrency section.

## Distributed consistency (gated)

Only when the design **already** spans multiple services or databases — do not introduce microservices in order to apply these.

- **Saga**: prefer an **orchestrated** saga (central state machine / one workflow definition) over choreography unless the project already uses event choreography. Every forward step needs a **compensating transaction**.
- **Compensations**: must be **idempotent** and run in **reverse dependency order** (children, then parents) so orphaned data is deleted without leaving dangling parents.
- **Durable workflows**: for long-running processes, use a primitives-based orchestrator (**Temporal** or the project's existing equivalent) that records **event history** so workers can reconstruct state after crashes or partitions. Ordinary request/response paths do not need this.
- **Reliability**: define recovery **bounds**, not “no failures” — retry policies with backoff and jitter (and a max attempts / DLQ). Do not invent a new orchestrator just to add retries.

## Realtime / hypermedia (gated)

Only when designing a web UI and the stack is not already a committed SPA.

- Prefer **SSE** over WebSockets when push is server→client only (plain HTTP). Use WebSockets (or the project's existing channel) when the client must send a bidirectional stream.
- Prefer **DOM morphing** (preserve focus and scroll) over full subtree swaps.
- Hypermedia implementation (e.g. Datastar): **`developer-workflow`** — do not introduce unprompted; do not cite unverifiable payload-reduction claims.

## Observability (gated)

- Production `perf` / eBPF / flame graphs: CPython **frame pointers** — `python/reference.md`. Do not rebuild CPython unless observability is in scope.
- Logging interpolation and root-logger rules: **`python`** Observability. Specify the standard here; do not restate the API.

## AI-assisted architecture

- Structure quality affects AI output quality — design for clarity before scaling AI use.
- For developer-side AI workflow (prompts, review passes, AX): see **`developer-workflow`**.
- Model serving gateway, registry **provenance**, and edge weight manifests: **`python/reference.md`** LLM section — only when the product serves or ships models.

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
