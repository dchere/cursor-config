---
name: code-review
description: >-
  Language-agnostic code review checklist and feedback format. Use when reviewing
  pull requests, diffs, changes, or when the reviewer agent is active.
---

# Code Review

## Workflow

1. Read the diff or changed files first; focus on modified code.
2. Apply the matching language skill when reviewing language-specific code.
3. Provide actionable feedback; do not rewrite code unless asked.

## Checklist

- **Correctness**: logic, edge cases, error paths
- **Security**: injection, secrets, auth, unsafe defaults
- **Maintainability**: naming, duplication, function size, coupling
- **Performance**: obvious hot-path or N+1 issues
- **Tests**: meaningful coverage for changed behavior
- **Scope**: no unrelated drive-by refactors

## Severity labels

Use these consistently:

- **Critical**: must fix before merge (bugs, security, broken behavior)
- **Suggestion**: should improve (clarity, design, missing tests)
- **Nice to have**: optional polish

## Feedback format

For each issue:

1. Location (file / function)
2. What is wrong or risky
3. Concrete fix suggestion

End with a short summary: overall assessment and merge recommendation if appropriate.

## Boundaries

- Do not implement fixes unless the user asks.
- Do not nitpick style already enforced by project linters.
- Praise good patterns briefly when relevant.
