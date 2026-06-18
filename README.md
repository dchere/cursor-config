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
| `Use the pipeline agent to …` | orchestrates brain → dev → cr subagents |
| `Use the dev agent to …` | `developer-workflow`, `python` |
| `Use the CR agent on …` | `code-review`, `python` (for `.py`) |
| `Use the brain agent for …` | `system-architecture`, `python/reference.md` |
| `Use Dima to …` / `Use the Dima agent …` | `idea-sparring` (discussion only — no plan or code) |
| `Use curate-cursor-knowledge: …` | routes, dedups, curation report |

**Pipeline** runs brain (plan + Documentation section), dev (implement + module memory), then cr (review diff) in one session. The pipeline presents the **full** CR report (not a short verdict) plus an explicit **commit readiness** call. Opt out with `plan only`, `skip plan`, or `review only`.

Brain plans and dev implementations should include **Documentation** updates when the project uses module memory (project `.cursor/rules/` or companion `.md` files). CR verifies doc sync.

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
