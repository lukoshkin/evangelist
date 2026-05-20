---
description: Run ruff + mypy on the files changed this session and fix errors your changes introduced — auto-detects how to invoke each tool and caches the project setup in memory
---

Lint and type-check the files changed this session, then fix every error your
changes introduced. Identify those files with `git diff --name-only` (staged and
unstaged) plus any untracked files you created — not from memory, which drifts.
Scope the checks to the changed Python files (or their enclosing `src/` dir).
If no Python files changed, say so and stop.

## 1. Reuse a cached setup

Before probing anything, look in this project's memory for a `code-checks-setup`
note. If it exists, follow its recorded invocations directly and skip section 2.
The note is authoritative — re-probe only if a recorded command fails because
the environment changed (service renamed, ruff config moved, etc.), and update
the note afterward.

## 2. Determine invocations

ruff and mypy run differently — resolve each before running anything.

### ruff (lint + format)

ruff needs no project dependencies, so it runs in an ephemeral env via `uvx`.
The only thing to verify is that ruff is configured as a *tool* — a `[tool.ruff]`
section in `pyproject.toml`, or a standalone `ruff.toml` / `.ruff.toml` — rather
than relying on ruff being installed as a project dependency.

- **Properly configured:** run
  ```bash
  uvx ruff check --fix <changed-files>
  uvx ruff format <changed-files>
  ```
- **Improperly set up** (ruff pinned only as a project/dev dependency, no
  `[tool.ruff]` and no `ruff.toml`): either
  - add a minimal `[tool.ruff]` section to `pyproject.toml` so `uvx ruff` works,
    then run as above; or
  - if the project is Dockerized, run ruff inside the container the same way as
    mypy below.

  Pick whichever matches the project's conventions, and say which you chose.

Never point ruff at the repo root — that drags in `node_modules/`, build
artifacts, and vendored code.

### mypy (type check)

mypy resolves the project's installed dependencies and type stubs, so it must
run where those exist — never in an ephemeral env.

- **Dockerized project** (a `docker-compose.yml` / `compose.yaml` defines an app
  service): mypy runs in the container.
  1. Check the stack with `docker compose ps`.
  2. If the relevant service is **not running**, stop and ask the user to bring
     the stack up (`docker compose up -d`). Do not start it yourself. Resume
     once they confirm.
  3. Run mypy with no `uv`/`uvx` prefix — the container already has the env:
     ```bash
     docker compose exec -T <service> mypy <changed-files>
     ```
- **Non-Dockerized project:** run mypy on the host against the project's env —
  `uv run mypy <changed-files>`, or the project's documented invocation.

## 3. Run and fix

Run both tools on the changed files. Fix every error attributable to your
changes. Leave pre-existing errors on lines you did not touch alone unless they
block the check — flag those instead of fixing them.

## 4. Cache the setup

Once the invocations are confirmed working, write (or update) a `project`-type
memory named `code-checks-setup` so the next call skips section 2. Record:

- the ruff invocation, and whether `pyproject.toml` needed correcting;
- whether the project is Dockerized, the service name, and the mypy invocation —
  or the host invocation when it is not.

Add its index line to `MEMORY.md`. If the note already exists and the setup is
unchanged, leave it as is.
