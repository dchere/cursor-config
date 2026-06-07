---
name: curate-cursor-knowledge
description: >-
  Integrates concentrated user input into cursor-config skills or agents in
  ~/projects/cursor-config. Use when the user provides standards, preferences,
  or lessons to persist, or asks to update, extend, or create skills/agents.
disable-model-invocation: true
---

# Curate Cursor Knowledge

Use this skill when the user gives **concentrated input** to preserve across projects.

## Repo location

All edits go to **`~/projects/cursor-config/`** (symlinked from `~/.cursor/skills` and `~/.cursor/agents`).

Never edit `~/.cursor/skills-cursor/`.

## Workflow

1. **Clarify target** (if ambiguous):
   - Extend existing skill (`python`, `code-review`, …)
   - Update agent prompt (`developer`, `reviewer`, `architect`)
   - Create new skill directory

2. **Read** current file(s) in `cursor-config`.

3. **Merge** the input:
   - Add bullets or sections; dedupe overlapping rules
   - Keep portable knowledge in global skills; project-specific detail belongs in project `.cursor/rules/` or project docs
   - Keep each `SKILL.md` under **500 lines**; move depth to `reference.md`

4. **Update frontmatter** `description` with new trigger terms if scope expanded.

5. **Summarize** what changed and show relevant diffs.

6. **Remind user** to review and commit in `cursor-config`:
   ```bash
   cd ~/projects/cursor-config && git diff && git add -A && git commit -m "..."
   ```

## Merge rules

- Prefer **actionable** bullets over prose.
- Do not duplicate Cursor **User Rules** verbatim; reference principles once.
- When input conflicts with existing skill text, ask which wins or propose a merged wording.
- For new languages, copy the `python/` layout: `SKILL.md` + optional `reference.md`.

## Example invocations

- "Use curate-cursor-knowledge: add rule X to python skill"
- "Integrate this review checklist into code-review"
- "Create a java skill from this document"
