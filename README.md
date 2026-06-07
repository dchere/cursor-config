# cursor-config

Personal Cursor agents and skills, symlinked into `~/.cursor/` for use across all projects.

## Layout

```
agents/          # Role subagents (developer, reviewer, architect)
skills/          # Knowledge packs (workflows, Python, curation)
install.sh       # Symlink skills/ and agents/ into ~/.cursor/
```

## Install

```bash
cd ~/projects/cursor-config
./install.sh
```

Restart Cursor or open a new agent chat after installing.

## Usage

| Invoke | When |
|--------|------|
| `Use the developer agent to …` | Implement features, fix bugs |
| `Use the reviewer agent on …` | Review diffs or PRs |
| `Use the architect agent for …` | Design, boundaries, tradeoffs |
| `Use curate-cursor-knowledge: …` | Integrate new standards into skills/agents |

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
