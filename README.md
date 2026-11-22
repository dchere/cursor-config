# cursor-config

Personal Cursor agents and skills, symlinked into `~/.cursor/` for use across all projects.

## Layout

```
agents/          # Role subagents (pipeline, brain, dev, cr, dima)
skills/          # Knowledge packs (workflows, Python, curation)
install.sh       # Symlink skills/ and agents/ into ~/.cursor/
```

## Install

```bash
cd ~/projects/cursor-config
./install.sh
```

Restart Cursor or open a new agent chat after installing.

**Agent IDs** (YAML `name` field) are lowercase: `pipeline`, `dev`, `cr`, `brain`, `dima`. You can invoke `CR` or `Dima` in chat; Cursor matches by name and description.

## Usage

| Invoke | Reads |
|--------|--------|
| `Use the pipeline agent to …` | **developer-workflow** — Dima, ADR, critic, your `yes`, tester, test check, tasks, plan check, dev, cr |
| `Use the tester agent on …` | scenario tests for an accepted ADR. No production code |
| `Use the critic agent on …` | a proposed ADR, a test check, a plan check, or a bug class. No code |
| `Use the dev agent to …` | `developer-workflow` (outcome test, then code; stop on a use-case conflict), `python` |
| `Use the CR agent on …` | `code-review` (meaningful tests, AI/bugfix lenses, domain-gated suggestions), `python` (for `.py`) |
| `Use the brain agent for …` | `system-architecture` (inheritance tests, sagas/reliability, SSE, LLM fleet), `python` / `python/reference.md` |
| `Use Dima to …` / `Use the Dima agent …` | `idea-sparring` (discussion only — no plan or code) |
| `Use curate-cursor-knowledge: …` | routes, dedups, curation report |

**Pipeline** follows **developer-workflow** and stops where that file says to stop. It shows the full final CR report. `skip dialog` skips Dima only.

A clash with an existing use-case test stops for you. Agents do not pick the winner.

## Updating knowledge

Skills do **not** auto-update from chat. When you have concentrated input to preserve:

1. Open a chat and invoke `curate-cursor-knowledge` with your input and target skill.
2. Review the diff in this repo.
3. Commit and push when satisfied.

## GitHub (optional)

```bash
git remote add origin git@github.com:YOU/cursor-config.git
git push -u origin main
```

## Do not edit

`~/.cursor/skills-cursor/` — Cursor-managed built-ins. Edit only this repo.
