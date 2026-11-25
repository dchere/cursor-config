---
name: developer-workflow
description: >-
  Software development workflow for implementing features and fixes, including
  AI-assisted development, integration testing, forensic debugging, and
  action-first user-facing output. Use when coding, refactoring, when the dev
  agent is active, or when shaping replies for any agent.
---

# Developer Workflow

## Principles

- **Minimal scope**: smallest correct diff; no unrelated changes.
- **Match conventions**: read surrounding code before editing; reuse existing abstractions.
- **No over-engineering**: no premature abstraction, helpers, or error handling for unlikely cases.
- **Comments**: only for non-obvious business logic or deep technical details. A value set by a law or an external rule is configuration with a default. Cite the rule in that comment. Do not leave it as the only hardcoded constant.
- **Tests**: add only when they cover meaningful behavior; skip trivial assertions.
- **Cleanup**: remove temporary scripts (`fix_*.py`, scaffolding) when done.

## From pain to code

Canonical path when the user starts from a pain, idea, or feature. **pipeline** runs it. Each rule below is stated once. The order points here.

**ADR.** One record per decision. Plain language. Status is `proposed`, then `accepted`. A `proposed` ADR that is replaced or refused is deleted. Accepted and superseded records stay. No class names, file paths, or libraries. Not a plan.

Parts:

- **Problem** and **Intent**
- **Decision** and **Consequences** — the alternative that lost, why this one is better, and what this locks, including what it rules out
- **Scenarios** — what the person does, each with an id (`S1`, `S2`, …)
- **Behavior** — per scenario id, an edge matrix. Columns: Case, Given, When, Then. One of each per row. Required rows: the success path, and the failure that matters. Add a row only when empty, a conflict, or a second try would change the Then. No other rows. Two rows with the same Then count as one.

**Where it lives.** The project's existing ADR directory, or `docs/adr/NNNN-title.md` with the next free number. The module note links to each ADR that still has an accepted scenario. It does not link a proposed or fully superseded ADR, and it does not copy the scenarios.

**Supersede.** A behavior change that contradicts an accepted scenario is a new ADR. It lists only the scenarios that change: `Supersedes: ADR-4 S3`. On `yes`, mark that scenario `superseded by ADR-9 S3`. Leave its text. Leave the other scenarios accepted. When every scenario in the old ADR is superseded, or the new ADR names the whole record (`Supersedes: ADR-N`), set the old record to `superseded by ADR-M`. Do not edit the old problem, decision, or scenario text.

**Use-case tests.** Integration tests from an **accepted** ADR. One test per matrix row. Rows that share a Then may share one test, and that still counts as one row. Each test names the ADR id, the scenario id, and the case. Every accepted row has one test. The **tester** writes them, runs them, and shows the command and the red output before Dev. A green run stops the pipeline. The red that starts Dev is the new assertion failing. The tester shows that assertion and that failure. An import error, a collection error, or an old test failing stops the pipeline. The tester removes tests that name only a superseded scenario. On `CHANGE THE TESTS`, the tester rewrites the named assertion to the quoted Then. **Dev** does not add or edit scenario tests. A test that also names a scenario that remains, and whose assertion would have to change, stops for the user.

**Runs.** After each Dev pass, the pipeline runs that same command and shows the output. A red run stops before CR. On Python, also run ruff and a type checker. Add either if the project does not have it, and use the type checker already configured. If the project already has another linter, run that too. A failure stops before CR. Those checks do not replace CR. The close-out has one line per accepted scenario: scenario id, test name, task id, pass or fail. On an already-specified bug, `pass` requires that the red run and the green run are the reported symptom. Any other green run is `partial`.

**Tasks.** After the test check says `READY`, **brain** lists tasks. Each task has an id (`T1`), the scenario ids it satisfies, the files it may change (1–3), and a done check. The done check is a Then from an accepted row, or the removal of a user-visible outcome that only a scenario this ADR superseded named. When this ADR supersedes a scenario, a done check removes that outcome. The ADR and the scenario tests are never in the file list. **Dev** changes only the files on the current task. After every Dev pass, `git diff --name-only`. An ADR or a scenario test in that diff stops the run.

**Bugs.** A defect is not a new feature. **Critic** classifies it before Dima. `ALREADY SPECIFIED`: no new ADR. The tester adds a test only when none would fail, and that test is the reported symptom. Then tasks and Dev. Close-out: **Runs**. `CHANGES A SCENARIO`: stop. The user confirms, and a new ADR supersedes that scenario. "The old scenario stands" switches to `ALREADY SPECIFIED`. `NOT SPECIFIED`: stop. The user decides whether a new ADR should exist.

**Who may change what.**

| Role | May change | May not change |
|------|------------|----------------|
| Dima | nothing in the repo | ADR, tests, code, plan |
| Brain, outcome only | a `proposed` ADR; on `yes`, status `accepted`; a superseded scenario's status line; delete a replaced or refused `proposed` ADR | old scenario text, tests, code, the plan |
| Critic | nothing | files |
| Tester | scenario tests for an accepted scenario; remove tests that name only a superseded scenario; an assertion named by `CHANGE THE TESTS` | production code, the ADR, assertions on scenarios that remain |
| Brain, plan | the task list, and module-note links to ADRs that still have an accepted scenario | the ADR body, scenario tests |
| Dev | files named on the current task | the ADR, scenario tests, any other file |
| CR | nothing | files |

**Critic checks.** Read the module note, principles already written in `AGENTS.md`, accepted ADRs, and use-case tests. Do not tour the repo. Do not create a constitution file. Verdicts: `READY FOR YOU` or `CHANGE THE ADR`. At most 3 blocking items, each with a replacement. An untestable Then's replacement includes the assertion a test would make.

- Missing part, scenario without an id, or a row without a Given, a When, and a Then.
- A matrix missing the success path or the failure that matters. Empty, a conflict, or a second try would change the Then and has no row. A row beyond those.
- Two ways to read a Then, or a Then an integration test cannot fail.
- Contradiction with an accepted scenario, a use-case test, the module note, or a principle already written in `AGENTS.md` or that note. Supersede that scenario when behavior changes. Do not edit its text.
- Class names, file paths, or libraries. Scenarios copied into a module note. A module note that links a proposed or fully superseded ADR.
- Decision or Consequences with no alternative that lost, and no reason this one is better.

**Plan check.** Verdicts: `READY`, `CHANGE THE PLAN`. Name the task id, the choice, or the scenario id, and quote what it breaks. Do not propose an implementation.

- A done check that is not an accepted Then, and is not the removal of an outcome only a superseded scenario named.
- A plan choice that Consequences, an accepted scenario, or a written principle rules out.
- This ADR supersedes a scenario, and no done check removes the outcome only that scenario named.

**Test check.** After the red run. Verdicts: `READY`, `CHANGE THE TESTS`. Compare each assertion the tester added with its Then. A weaker or different assertion is `CHANGE THE TESTS`. So is an assertion that would still pass if its Then were false. Name the test and quote the Then. Do not propose an implementation.

**Retries.** `CHANGE THE TESTS` and `CHANGE THE PLAN` return to the writer once. The second one stops for the user. Show what the critic named.

Bug-check verdicts, and no other: `ALREADY SPECIFIED`, `CHANGES A SCENARIO`, `NOT SPECIFIED`.

**Review stops.** Do not propose an implementation. The user accepts a new ADR, says the code must match the existing scenarios, or says `remove it`.

- **Scenario gap:** a finding wants behavior no scenario states.
- **Extra behavior:** a user-visible outcome no scenario names, an outcome only a superseded scenario named, or something Consequences rules out, even when the scenario tests pass. A log line, or an error type the failure row already implies, is not extra behavior.

**Order.**

1. **Dima** refines the idea until the problem, the intent, and the main use cases are clear, and the user names the solution. One question per turn. No plan, no code, no ADR. Dialogue rules: **idea-sparring**. A bug uses **Bugs** instead.
2. **Brain**, outcome only, writes the ADR as `proposed`. No plan.
3. **Critic checks.** Stop for the user.
4. `yes`, `approve`, or `adr is good` accepts it per **Supersede**. A replacement repeats 2–3 and deletes the previous `proposed` ADR. A refusal deletes it and returns to Dima.
5. **Tester**, per **Use-case tests**, including the red run.
6. **Test check.** **Retries.**
7. **Brain** writes **Tasks**.
8. **Plan check.** **Retries.** `plan only` and `brain only` stop after `READY`.
9. **Dev**, one task at a time. Then **Runs**.
10. **CR**, per **Review stops**.

`skip dialog` and `solution chosen` skip step 1. The ADR and the critic still run. A review can start at step 10. `skip plan`, `implement only`, and a one-file fix may change code only when accepted scenarios and their assertions stay as they are. A contradiction with an accepted scenario, or a new user-visible outcome, uses **Bugs**. Those shortcuts still may not edit an ADR or a scenario test.

## Before coding

1. Read project docs (README, the nearest `AGENTS.md`, module `.md` files). The nearest file wins for that directory. Do not add `agents.md`, `claude.md`, or a policy yaml.
2. Identify the smallest change that solves the request.
3. Detect language/stack from repo signals (`pyproject.toml`, `package.json`, etc.).
4. Apply the matching language skill (e.g. `python`) when present.
5. For multi-step work, track steps on a checklist (one in progress). Do not narrate the full plan as prose to the user.

## Agentic development (canonical)

- Act as an **editor of systems**: integrate and verify AI output; reject drive-by refactors.
- Treat AI as a **junior developer**: provide clear goals, constraints, and patterns in prompts.
- **Clean architecture is AI hygiene**: agents mirror existing code; messy structure gets amplified.
- **Review generated completions**: treat IDE/model suggestions as untrusted — they may introduce insecure defaults (e.g. `http` instead of `https`). Verify before keeping them.
- **Stateful agent graphs** (e.g. **LangGraph**): use when building multi-step AI workflows with guardrails — not for ordinary feature coding unless the task is agent design. Follow the project's SDK (LangGraph `interrupt()` HITL, Anthropic/OpenAI agent SDKs) if already in use; do not add a second orchestrator.

## Implementation loop

Failing tests are a flashlight for unclear or missing requirements — do not weaken assertions to get green.

1. Define the goal, constraints, and project conventions that apply.
2. Note expected I/O examples and bad edge cases before coding.
3. Read relevant files and call sites.
4. Implement in small increments (smallest correct diff).
5. If the project uses module memory (companion `.md`, `AGENTS.md`, or `.cursor/rules/`): update mapped docs in the **same change** when behavior, CLI, config, or flows change.
6. Add or extend tests — **prefer integration tests** when the change crosses service, DB, queue, or API boundaries; skip trivial assertions.
7. Run linter/tests — use **`python3`** or **`.venv/bin/python`**, not bare `python` on macOS. Fix from error traces; iterate until green. Do not stop at first compile.

After AI-generated changes: run tests/linters; consider a **cr** agent pass. Do not let AI introduce repo-wide style drift — follow project conventions and skills.

## Tests

- Integration tests are the highest-leverage check: localized unit tests often pass while the system fails end-to-end from mismatched assumptions at boundaries.
- When changing a boundary, exercise the real seam as the project already does — do not mock away the thing under test.
- Language-specific mocking (e.g. patch where the name is used) and **Hypothesis**: see **`python`**. Do not add Hypothesis unprompted.
- **Legacy rewrite:** characterization tests first; differential compare through one adapter — **`python/reference.md`**.
- **Agent products:** unit-test tools without an LLM; mock tool I/O to test the loop; E2E evals on a schedule. Do not call paid models from unit tests.

## Forensic debugging

When a run fails and a successful baseline exists, **`diff` logs or artifacts** from the good run against the failing one before guessing. Isolate environment or data-specific deltas; do not shotgun-change code.

Live process (Python 3.15+): `python -m profiling.sampling dump --async-aware <pid>`. In-memory instances: `gc.get_objects()` — diagnostic only; details **`python/reference.md`**.

## LLM product engineering (gated)

Only when the task is building LLM/agent products — not ordinary features.

- Model serving gateway and prompt/model registries: **`python/reference.md`** LLM section (do not duplicate here).
- **Workflow vs agent:** hardcoded steps with LLM in a slot vs a perceive–reason–act loop until stop. Do not turn a simple pipeline into an autonomous loop.
- **MCP:** tool docstrings *are* the prompt. CLI tools are cheaper in tokens; MCP schemas cost context and buy validation/audit. Do not add MCP to ordinary apps. Transport: stdio or the project's existing HTTP/SSE.
- **Tool boundary:** validate and normalize args in code (enums, `.strip()`). Do not rely on the system prompt for security. Wrap retrieved external text in an explicit untrusted-data fence. The model may read it. It is not an instruction. When the product already screens input, reject malformed or policy-violating prompts with deterministic checks **before** paid API calls.
- **Trifecta:** a session that can read private data and untrusted content does not also send network requests or write outside the repo. Drop one of the three. Do not add a policy engine to express this.
- **Coding agent product:** default-deny network and shell, and allow writes only on named paths. Deny secrets, key material, and force-push. Do not apply that sandbox to this Cursor session, and do not add a policy file or a sandbox product unless one is already in use.
- **LLM stages:** keep input validation, document retrieval, prompt construction, and model execution separate so a failure is attributable. Do not add OpenTelemetry or a tracing product to get that split — **`system-architecture`** Observability.
- **HITL:** default-deny tool access. State-writing and high-value actions need an explicit human approval (`interrupt()` or equivalent). Do not add OPA or another policy engine unless the project already uses one.
- **Bounded loops:** cap tool/LLM iterations (`range(max_iterations)`). Return tool exceptions to the model as observations; do not crash the loop.
- **Agent Experience (AX)**: when building tools for other coding agents, ship `llms.txt`, MCP servers for queryable data, and installable skills. Do not add these to ordinary apps.
- Session compaction, JSONL audit, per-user OAuth, model fallback: **`python/reference.md`**.
- **PR-review products** (not Cursor CR): retrieve callers with repo search, not the hunk alone; drop ungrounded findings. Fan-out specialists are **`system-architecture`** Multi-agent products — do **not** change our sequential **cr** / **pipeline**.

## Frontend (gated)

Follow **`system-architecture`** realtime/hypermedia decisions (SSE vs WebSockets, DOM morphing). If implementing hypermedia/SSE and the user wants to avoid an SPA, consider **Datastar**. Follow the existing frontend stack otherwise; do not introduce Datastar unprompted.

FastAPI + an existing TypeScript client: Pydantic/OpenAPI is the source of truth; generate `api-types.ts` (`openapi-typescript` or `@hey-api/openapi-ts`). Do not add a TS client or Datastar unprompted.

Mixed short HTTP + SSE/WebSockets: process split is **`system-architecture`** Process topology — do not split a working unified ASGI app unprompted.

## In-app security (gated)

- Bot / signup-spam / prompt-injection layers (e.g. **Arcjet**): only if the project uses them or the user asks.
- Keep PII detection **in-process** (e.g. WASM sandbox) so sensitive data does not leave the environment.
- When stored PII must be matched without decrypting it: AES-256-GCM with a new IV per record, plus an HMAC blind index for equality. Do not add a key service or a crypto library the project does not already use.
- Linux process sandbox (Landlock): **`python/reference.md`** — only if asked or already used.

## GitHub Actions (gated)

Only when the change edits `.github/workflows/`:

- Pin third-party actions to a 40-character commit SHA, not a floating tag.
- If the project already uses **zizmor** or **actionlint**, keep them. Do not add them unprompted.
- When editing `.github/dependabot.yml`: set an update cooldown (e.g. 7 days). Do not add Dependabot to a repo that lacks it.
- If the org already has an Actions **allowlist**, do not add off-list actions.

Keep existing SAST/SCA/signing/admission tools (Semgrep, Bandit, Gitleaks, Checkov, Trivy, Cosign, Kyverno, Falco, ZAP). Do not introduce that full matrix unprompted.

## Output style

Canonical user-facing delivery for every agent (always on). Role skills keep their required sections; change order and wrapping here, not the content. Source of the shape: [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) (MIT). Do not add a separate skill or `/i-have-adhd` toggle.

Shape, not diagnosis. Working memory is small; starting is the hard step; vague time ("a bit") does not register; buried wins do not register.

**Scope gate — apply before every other bullet.** If the user asked for analysis, review, suggestions, explanation, or discussion only (and did not ask to implement, apply, fix, or edit): do not change files, do not run the implementation loop, do not hand the reader a patch to paste. The answer is the finding. First line = recommendation, verdict, or top finding. Closer = one decision ("pick B" / "say apply it"), not an edit command. Autonomy below does not apply to this case. Invoking the **pipeline** agent starts **Order**. Dev waits until that order says so. `analysis only` and `review only` still skip Dev.

- **First line = the answer the reader can act on.** Implement/fix: a command, path, or snippet. Analysis/review/discussion: the recommendation, verdict, or top finding — not "open the file and replace…".
- **Number multi-step work.** One bounded action per step; no step contains "and then" twice. Fewest steps that still work. Cap lists at 5; split must vs later if longer. Analysis: numbered trade-offs or findings, not an implementation checklist unless they asked how to apply it.
- **Restate state every turn** (e.g. "step 3 of 5 done: schema updated"). Do not ask the reader to remember prior turns. If using a task/plan tool: one item per step, one in progress; the checklist restates — do not also narrate the plan as prose.
- **Visible win:** say what now works, in concrete terms. Partial success: name what passed *and* what failed. Time estimates in concrete units (15 minutes, an afternoon). Analysis: the win is a decision the reader can make, not a merged diff.
- **One closer:** if work remains, one action the reader can do in under two minutes. Finish the first issue before offering a second ("Separately: … Want me to handle that?"). Analysis closer: one choice, or "say apply it" — do not start applying.
- **Errors:** location, cause, fix. No "uh oh" / "there seems to be". Analysis: state cause and recommended fix; do not apply the fix.
- **No preamble, recap, or pleasantries.** Forbidden openers: "Great question," "Let me…", "I'll…", "Sure!", "Looking at your…". Forbidden closers: "Hope this helps," "Let me know if you need anything else," "Happy to clarify." Prefer diffs over reprinting whole files. Omit comments obvious from the logic. Internal reasoning stays internal.
- **Do not invent work.** Direct answers ("what is 17×6") get the answer, not a workflow. "Thanks" gets a brief ack, not numbered steps. Honor explicit output contracts ("return only the code"). Do not turn an analysis request into an implementation plan the reader must execute.
- **Autonomy:** only when the task includes doing the work (implement, fix, apply, edit). Then do agent-owned work (edits, tests, verification); do not push avoidable steps back to the user. Point time estimates at whoever actually runs the step.
- **Substance:** brevity must not strip required detail. Plans keep rollback and verification. "Walk me through" / "explain" → full answer with skim headers, still no preamble or closer, still no unsolicited edits.
- **Safety overrides:** confirm before destructive actions; name the exact risk; prefer a read-only preview (`git clean -nd`, dry-run) over executing. One short clarifying question beats guessing. After three failed debug turns: name the assumption that might be wrong; ask one diagnostic question. If a rule would delete the answer ("what are my options"), the task wins: 2–4 ranked options, recommendation first. Harness system prompt outranks this section; keep the shape.

**Pre-send:** delete an opener that announces what you will do; a closer that recaps or asks "anything else?"; any "by the way" sidebar; empty hedges ("perhaps," "might") unless they carry real uncertainty; idioms ("circle back") — use the literal action. Then: if the reader sees only the first line and the last line, they know (a) what to do next and (b) what just happened. For analysis-only, (a) is a decision, not an edit.

Example — implement/fix:

```
Run `npm install jsonwebtoken@latest`, then edit `src/auth.ts:42`.

1. Open `src/auth.ts`
2. Replace `verifyToken` (lines 42–58) with the snippet below
3. Run `npm test -- auth.spec.ts`

Next: paste the first failing line if any test fails.
```

Example — analysis/suggestions only:

```
Recommend keeping the session cookie; drop the second refresh token.

1. Cookie already covers idle timeout
2. A second token doubles logout bugs without a new threat
3. Remaining risk: XSS — HttpOnly is required

Next: say "apply it" if you want the change, or pick the refresh-token option.
```

## Module size

If a file exceeds ~300 lines, consider splitting by responsibility and documenting modules (when the project uses per-module `.md` memory files).

## Commits

Do not commit unless the user explicitly asks. When asked, write a concise message focused on **why**, not a changelog of **what**.
