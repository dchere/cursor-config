---
name: system-architecture
description: >-
  System design guidance: SOLID, inheritance vs composition (reversibility/LSP),
  Polylith monorepos, sagas and durable workflows, plugin REST contracts,
  realtime/SSE, process topology (WSGI vs ASGI), LLM fleet boundaries, and
  cross-language integration. Use when designing modules, services, monorepos,
  or when the brain agent is active.
---

# System Architecture

## Goals

- Clarify problem and constraints before proposing structure.
- Present tradeoffs, not a single "best" answer without context.
- Prefer simple designs that can evolve; avoid premature microservices.

## Workflow

1. Restate requirements and constraints (statefulness, throughput, security boundaries, concurrency, scale).
2. Map current or proposed components and data flow.
3. Identify boundaries (what owns what; what must not leak).
4. Pick patterns from the table below only when the trigger matches — do not apply the whole catalog.
5. Propose 1–2 viable options with pros/cons (memory, latency, complexity, failure modes).
6. Recommend one option with rationale; verify isolation, dual-write, retry bounds, and observability against what the project already runs.

| Trigger | Pattern | Home |
|---------|---------|------|
| Dual-write DB + queue | Transactional outbox | this skill |
| Collateral side effects on one state change | Observer / EDA (events = facts, commands = requests) | this skill |
| Multi-step construction + validation → immutable result | Builder (do not wrap every dataclass) | this skill |
| Untrusted process / no-root FS restrict | Landlock | `python/reference.md` |
| CPU-bound threads on 3.14t+ | Free-threaded CPython | `python/reference.md` |
| Proven CPU inner loop, batched payloads | PyO3 / Cython (no per-row FFI) | `python/reference.md` |

## Output structure

Delivery wrapping: **developer-workflow** Output style. Thinking order stays the Workflow above; user-facing order is:

1. **Recommendation** — chosen approach and why (first line: the decision)
2. **Options** — 2–4 with one-line trade-offs
3. **Context** — problem, constraints, assumptions
4. **Boundaries** — modules/services, interfaces, data ownership
5. **Risks** — failure mode → mitigation; migration path if refactoring
6. **Tasks** — when an ADR is accepted. Shape: **developer-workflow**.
7. **Documentation** — ADR id and path. Module notes link to it. **developer-workflow**.

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
- **OCP via ABCs/protocols**: a pluggable provider with no shared implementation uses a **Protocol**. An **ABC** is for a contract that shares concrete methods. Python MRO / `super()`: **`python`**.
- **Registry over if/elif**: decorator `@register`, a `Registry` with duplicate-key errors, or `__init_subclass__` auto-registration — **`python`**. Do not grow a central dispatch chain.
- Repository/data layer isolated from business rules
- **Invariants in the domain**: security and business constraints live in the entity or service that owns the state. A controller or UI may call that check. It must not be the only copy. A second entry point must not bypass it. A value object that exists to reject an illegal value is immutable. An owned resource is read and written with its owner, not by id alone.
- Thin entry points delegating to workflows
- Typed configuration, not ad-hoc dicts
- No I/O in constructors — **`python`** Scoping
- **Builder** (gated): only when construction is multi-step with a terminal `build()` that validates and returns an immutable object. Factory methods may hand out pre-filled builders. Do not introduce a builder for a simple dataclass.

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

## Async shared state (gated)

When many waiters must observe **every** transition (not only the latest): do not use a single `asyncio.Event` / `Condition` (waiters miss values under load). Use a per-consumer queue (ValueWatcher). Ordinary "wait until ready" still uses Event.

## Distributed consistency (gated)

Only when the design **already** spans multiple services or databases — do not introduce microservices in order to apply these.

- **Saga**: prefer an **orchestrated** saga (central state machine) over distributed locks and over choreography unless the project already uses event choreography. Every forward step needs an **idempotent compensating transaction**.
- **Compensations**: must be **idempotent** and run in **reverse dependency order** (children, then parents) so orphaned data is deleted without leaving dangling parents.
- **Durable workflows**: for long-running processes, use a primitives-based orchestrator (**Temporal** or the project's existing equivalent) that records **event history** so workers can reconstruct state after crashes or partitions. Ordinary request/response paths do not need this.
- **Reliability**: define recovery **bounds**, not “no failures” — retry policies with backoff and jitter (and a max attempts / DLQ). Do not invent a new orchestrator just to add retries.
- **Outbox** (same DB, queue later): do not `INSERT` then publish in two uncorrelated writes. Write the event row in the **same transaction** as the business row; a relay worker publishes and marks sent. Multiple relays: `SELECT … FOR UPDATE SKIP LOCKED`. Consumers must be **idempotent** (unique constraint or equivalent).
- **Observers**: events are facts ("happened"); commands are requests ("do this"). One domain event, many handlers; each handler in its own `try/except` so one failure does not skip the rest. Publishers stay unaware of subscribers.

## Plugin / extension boundaries (gated)

Only when the design registers **external** plugins or model nodes — do not add a plugin platform to apply this.

- Contract is a **shared schema** (e.g. Pydantic) over HTTP, not in-process dynamic imports or an extra task queue for the handshake.
- On register: **probe** the contract (examples: `/ready`, `/catalog`) and reject if the payload does not parse.
- Periodically re-probe (existing scheduler — do not add Celery Beat unprompted). On failure: deactivate; on recovery: re-activate.
- Create / update / delete go through an ownership/authz check.

## Process topology (gated)

Only when the app mixes short HTTP with long-lived streams (SSE / WebSockets) **and** the deploy is not already a committed single ASGI service.

- Keep request/response on the existing WSGI (or equivalent) workers.
- Offload long-lived connections to a dedicated **ASGI** process or sidecar. Do not split a working unified ASGI app unprompted. Do not cite unverifiable memory-savings numbers.

## Data access (gated)

On a **measured** slow query path: inspect the query plan and indexes **before** adding async, threads, or extra services. ORM cascades and N+1: **`python/reference.md`** Django section — only if the project uses Django.

- **Timescale** (only if already in the stack): hypertables + time-bounded queries so chunks can be excluded; continuous aggregates over trigger-maintained full-table summaries. Do not add Timescale unprompted.
- **Neo4j / Cypher** (only if already in the stack): batch writes with `UNWIND`, not one statement per row. Do not add Neo4j unprompted.

## Realtime / hypermedia (gated)

Only when designing a web UI and the stack is not already a committed SPA.

- Prefer **SSE** over WebSockets when push is server→client only (plain HTTP). Use WebSockets (or the project's existing channel) when the client must send a bidirectional stream.
- Prefer **DOM morphing** (preserve focus and scroll) over full subtree swaps.
- Hypermedia implementation (e.g. Datastar): **`developer-workflow`** — do not introduce unprompted; do not cite unverifiable payload-reduction claims.
- FastAPI + a separate TypeScript client (already in the stack): **Pydantic is the source of truth**; generate TS from OpenAPI — **`developer-workflow`**. Do not add a TS client to apply this.

## Observability (gated)

- Production `perf` / eBPF / flame graphs: **`python/reference.md`** profiling (3.15+ ships frame pointers; do not rebuild CPython unless observability on an older custom build is in scope).
- Logging interpolation and root-logger rules: **`python`** Observability. Specify the standard here; do not restate the API.
- Traces / metrics / logs: use the project's existing OpenTelemetry (or equivalent) pipeline. Do not add OTel, Tempo, or Jaeger unprompted.

## Multi-agent products (gated)

Only when the *product* is a multi-agent system — not how Cursor CR reviews PRs (stay sequential; do not spawn extra reviewer agents).

1. **Orchestrator + specialists** — manager delegates; isolates specialists. Our **pipeline** agent is this pattern (brain → dev → cr).
2. **Sequential refine** — planner → implementer → reviewer.
3. **Fan-out / fan-in** — independent specialists then merge. Product reviews only; not our CR.
4. **Debate** — opposing views then a synthesizer. Idea-stage: **Dima**.

## Container deploy (gated)

Only when the change is a Dockerfile / Kubernetes / compose deploy.

- Read-only root filesystem, drop unused capabilities, non-root user — if the project already containerizes. Do not invent a cluster to apply this.
- When editing a Dockerfile: install dependencies before the source that changes often. A later stage copies only what the process runs, so build tools stay out of the runtime image. Do not bake model weights into the image. Load them from the registry the project already uses. Do not add MLflow, a CUDA base image, or Compose profiles unprompted.

## AI-assisted architecture

- The user decides architecture and security boundaries. The agent may draft syntax, boilerplate, and CRUD.
- Structure quality affects AI output quality — design for clarity before scaling AI use.
- For developer-side AI workflow (prompts, review passes, AX): see **`developer-workflow`**.
- Model serving gateway, registry **provenance**, and edge weight manifests: **`python/reference.md`** LLM section — only when the product serves or ships models.
- Multi-step LLM features: require an **evaluation harness** (correctness, coverage, format), not informal spot checks. Do not mandate Chain-of-Thought as an architecture.
- Per-user identity for agent tools: **`python/reference.md`**. Do not use a shared bot token for user-scoped actions.

## Monorepo layout

When managing a large Python monorepo, consider **Polylith**: reusable **bricks** (components) and **bases** (entry assemblies) with explicit dependency rules. Prefer this over ad-hoc package sprawl when many services share domain code. When several apps share a UI kit, put tokens under primitives under layouts. Do not add Turborepo unprompted.

## Cross-language integration

**Gate:** profile Python first; consider Rust/PyO3 or Cython only for proven CPU bottlenecks.

- Thin language boundary; explicit error/ownership contracts
- Batch across the FFI (full buffers / JSON), not per-row micro-calls — **`python/reference.md`**
- Rust mindset: ownership at boundaries; `Result`-like returns (`User | None`) for expected failures
- See `python/reference.md` for PyO3, Cython, and profiling gates

## Boundaries

- Do not implement code unless the user asks.
- Leave room for project conventions.
- Apply language skills (e.g. `python`) for stack-specific details.
