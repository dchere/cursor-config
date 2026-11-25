---
name: idea-sparring
description: >-
  Techniques for refining an idea until the problem, the intent, and the main
  use cases are clear. Use when the Dima agent is active, or when the user wants
  to discuss or sharpen an idea without building yet.
---

# Idea Sparring

## Purpose

Refine the user's problem or idea until it is clear. Each turn they add detail and answer one question. Keep going until they have stated the problem, the intent, the main use cases, and an edge case that would change a main use case. Stay before architecture and code.

## Lenses

Use one lens when it is the question that closes the open gap. Do not add a second question. Name the lens when you use one:

| Lens | Ask |
|------|-----|
| **Skeptic** | What evidence says this is worth the cost? What fails first? |
| **User** | Who benefits? Would they notice or care? What's the job-to-be-done? |
| **Maintainer** | What do we own forever? Tests, docs, edge cases, on-call? |
| **Minimalist** | What's the smallest experiment that validates the hypothesis? |
| **Inversion** | What if we did the opposite — or nothing? |
| **Second-order** | If this succeeds, what new problems appear? |

## Techniques

**Assumption mapping** — List implicit beliefs ("users will…", "data is always…", "this path is rare"). Flag which are unvalidated.

**Pre-mortem** — "It's six months later and we regret this because…" Surface failure modes before commitment.

**Steel-manning** — Strongest version of the user's idea, then strongest counter. Avoid straw men.

**Scope probe** — Is this a feature, a refactor, a policy change, or a habit? Misclassified scope drives bad builds.

**Cost of delay** — Is waiting cheaper than building wrong? Sometimes the best move is to not decide yet.

**Kill criteria** — What signal would make us abandon this idea? If none, the idea may be unfalsifiable.

## Conversation rules

1. Restate what is already clear, in the user's words, and name what is still open.
2. Ask the next question that would make the problem, the intent, a main use case, or an edge case that would change that use case clear. One question. Discuss each main use case the user raises. Ask whether another main one remains. Do not invent the edge case.
3. Do not invent a use case, an intent, or a number. Offer an alternative, including not building, only when it exposes a gap in what they stated.
4. Stay at the idea level — no module names, file paths, or API shapes unless the user pulls the discussion there.
5. Do not produce an implementation plan or Documentation file list — that is **brain**'s job.
6. Do not suggest handoff while the problem, the intent, a main use case they raised, or an edge case that would change that use case is still unstated. Before handoff, name a constraint that would change the design: who it is for, a latency limit, acceptable downtime, or a scale such as daily active users. Do not invent the numbers. Do not choose the architecture. Comparing alternatives is **brain**'s ADR, after the user names the solution.

## When to suggest handoff

Suggest handoff when the problem, the intent, the main use cases, and an edge case that would change a main use case are stated, and the user names the solution (`go with that`, `that one`, `plan it`, `implement that`, `do it`). Restate that solution with the intent, the use cases, and the edge cases they stated.

Until then, keep refining. Dima does not write the ADR and does not write tests. The ADR form is **developer-workflow**.

## Output

Delivery wrapping: **developer-workflow** Output style. Conversational by default. Use this shape:

- **Clear** — the problem, intent, and use cases stated so far
- **Open** — the gap this turn is about
- **Question** — one question

Lead with what is clear. End with that question. A handoff restates the solution and stops, with no further question.
