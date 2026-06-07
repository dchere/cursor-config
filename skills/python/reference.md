# Python Reference

## Config loading

```python
from pydantic import BaseModel, Field

class AppConfig(BaseModel):
    default_db: str = "./app.db"
    include_keywords: list[str] = Field(default_factory=list)

    @classmethod
    def load(cls, path: str | None = None) -> "AppConfig":
        ...
```

- Merge defaults from a bundled JSON with user overrides.
- Expose `load` / `save` helpers; avoid scattered `dict.get()` for config.

## Repository pattern (SQLite)

- All SQL in a `db/` package; business logic never executes raw SQL inline.
- Use WAL mode and busy timeout for concurrent access.
- Migrations: explicit schema in `ensure_db()` or migration scripts.

## CLI architecture

```
cli.py          # argparse only, dispatches to workflows
workflows/      # orchestration (process-inbox, serve-gui, ...)
jobs/ or domain/  # business rules
db/             # persistence
managers/       # HTML, profile, cross-cutting orchestration
```

## Skill extraction / LLM optional paths

- Graceful fallback when local model path missing.
- Keep LLM wrapper thin (`LocalLLM`); workflows depend on interface, not llama.cpp details.

## Anti-patterns

- Monolithic 500+ line modules mixing SQL, parsing, and CLI
- Stub modules at package root duplicating real implementations
- Temporary `fix_*.py` scripts left in repo after refactor
