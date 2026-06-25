---
name: install-spec-kit
description: Install or update spec-kit (github/spec-kit) in the current project. Use when asked to install spec-kit, set up spec-driven development, update/upgrade spec-kit, or run specify init. Installs the specify CLI via uv and initializes slash commands for the project.
---

Installs or upgrades [spec-kit](https://github.com/github/spec-kit) (spec-driven development toolkit) in the current project. The driver fetches the latest release tag from GitHub, installs or upgrades the `specify` CLI via `uv tool`, backs up any customized constitution, then runs `specify init --here --force` to deploy all slash commands and templates.

## Prerequisites

- **uv** — Python package manager. Install if missing:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```
- **Python 3.11+** — bundled automatically by uv
- **Git** — required by spec-kit's git extension
- **gh CLI** (optional but recommended) — used to fetch the latest release tag; falls back to `curl` if absent

## Run (agent path)

Run the driver from the project root:

```bash
bash .claude/skills/install-spec-kit/driver.sh
```

Optional: pass an integration name to override the auto-detected one:

```bash
bash .claude/skills/install-spec-kit/driver.sh claude
bash .claude/skills/install-spec-kit/driver.sh copilot
bash .claude/skills/install-spec-kit/driver.sh gemini
```

The driver:
1. Resolves the latest release tag via `gh api` or `curl`
2. Auto-detects the integration from `.specify/integration.json` (defaults to `claude`)
3. Installs `specify-cli` if not present, or runs `specify self upgrade` if outdated
4. Backs up `.specify/memory/constitution.md` before init
5. Runs `specify init --here --force --integration <integration> --ignore-agent-tools`
6. Restores the constitution backup (preserving any customizations)

## After install: constitution setup

Once the driver completes, handle the constitution in one of two ways:

### Detect state

```bash
grep -q '\[PROJECT_NAME\]' .specify/memory/constitution.md && echo "fresh" || echo "customized"
```

---

### The required principles

These are the minimum principles that MUST be present in every project constitution. Reference them in both cases below.

> I. **Makefile as the single entry point** — Every script, task, build, test, and service lifecycle action MUST be invoked through `make`. No direct calls to language runtimes, package managers, or shell scripts from outside the Makefile. The Makefile is the contract between the developer and the project.
>
> II. **Docker for every service, no exceptions** — All services, runtimes, and tools run inside Docker containers. No language or runtime (Node, Python, Go, etc.) is installed locally. `docker-compose` is explicitly forbidden to maximize portability; use plain `docker run` or `docker build` via Makefile targets instead.
>
> III. **Deploy to Railway via MCP** — All deployments target Railway. When asked to deploy, use the Railway MCP server (`mcp__railway__*` tools) unless the user explicitly specifies a different target. Never deploy manually or through other providers by default.
>
> IV. **`.env` files for all configurable values** — Backend projects and test suites MUST read configuration from `.env` files. No hardcoded URLs, credentials, ports, or environment-specific values in source code. Provide a `.env.example` committed to the repo; the actual `.env` is gitignored.
>
> V. **Always implement tests: e2e (frontend) + contract (backend)** — Frontend features require end-to-end tests; backend services require contract tests. Both test suites are written in Python, run inside Docker, and invoked through Makefile targets. The test runner starts the app with `make` (which uses Docker), then validates behavior from the outside.
>
> VI. **Folder structure by concern** — When the project includes a frontend, backend, or both, each lives in a dedicated root-level folder named `frontend/`, `backend/`, or both. A separate `test/` folder at the root contains all contract and e2e test code. No mixing of app code and test code.
>
> VII. **Ports as Makefile parameters with safe defaults** — All service ports MUST be configurable via Makefile parameters (e.g., `make run PORT=3001`) to avoid conflicts when running multiple projects. Define sensible defaults in the Makefile but never hardcode ports in Docker run commands or source code.
>
> VIII. **GitHub via `gh` CLI — repository management** — All GitHub operations (creating repos, opening PRs, managing issues, reviewing, merging) MUST be performed using the `gh` CLI. Never use the GitHub web UI or `git` remote commands for operations that `gh` covers. Create the repo with `gh repo create`, open PRs with `gh pr create`, and manage issues with `gh issue create/list/close`.
>
> IX. **Branch-per-feature workflow** — Every unit of work lives on its own branch created with `gh` or the speckit git extension. Branch names follow the pattern `<number>-<short-description>` (e.g. `001-user-auth`). `main` is always deployable; direct commits to `main` are forbidden. Branches are merged via PR only, reviewed and approved before merge.
>
> X. **PRs as the integration gate** — All merges into `main` happen through a Pull Request opened with `gh pr create`. The PR description must reference the related issue or spec. Squash-merge is preferred to keep history linear. Delete the branch after merge with `gh pr merge --squash --delete-branch`.
>
> XI. **Issues for every tracked unit of work** — Features, bugs, and tasks are tracked as GitHub Issues. Open issues with `gh issue create` before starting work. Close them automatically by referencing `Closes #<n>` in the PR description. Never start a branch without a linked issue.
>
> XII. **Seeds for all data management** — Database structure, base data, and test data are managed exclusively through seed scripts, never through manual SQL or ad-hoc migrations run by hand. Seeds are organized in three layers: (1) `schema` — creates or evolves the data structures; (2) `base` — inserts the minimum required data for the app to function (catalogs, admin users, config records); (3) `test` — inserts realistic test data for development and QA. Seeds run automatically on every deploy as part of the startup sequence via a Makefile target (e.g. `make seed`). Every seed script MUST read the `APP_ENV` (or equivalent) environment variable and act accordingly: `schema` and `base` seeds run in all environments; `test` seeds run ONLY when `APP_ENV` is `development` or `test` — never in `production` or `staging`. Seeds MUST be idempotent: safe to run multiple times without duplicating or corrupting data (use upsert, `INSERT OR IGNORE`, or equivalent). Never seed production with test data.

---

### Case A — `fresh` (template placeholders still present)

The constitution has never been filled in. Before creating it, **present the seven principles to the user** in a clear, readable summary and ask for confirmation:

> "Voy a crear la constitución del proyecto con los siguientes principios base. Puedes aceptarlos, modificar alguno, o agregar principios adicionales antes de que los escriba:
>
> 1. **Makefile como punto de entrada único** — Todo se ejecuta con `make`.
> 2. **Docker para todo, sin docker-compose** — Sin instalaciones locales de lenguajes.
> 3. **Deploy en Railway via MCP** — Usar `mcp__railway__*` salvo que indiques lo contrario.
> 4. **`.env` para toda configuración** — Nunca hardcodear valores; `.env.example` commiteado.
> 5. **Tests e2e (frontend) + contrato (backend) en Python** — Ejecutados con Docker y Make.
> 6. **Carpetas separadas: `frontend/`, `backend/`, `test/`** — Una por concern en el root.
> 7. **Puertos como parámetros de Make** — Con defaults, pero siempre configurables.
> 8. **GitHub via `gh` CLI** — Repositorios, PRs e issues siempre con `gh`; nunca desde la UI web.
> 9. **Branch por feature** — Patrón `<número>-<descripción>`, `main` siempre deployable, sin commits directos.
> 10. **PRs como puerta de integración** — Todo merge a `main` por PR; squash-merge y borrar branch tras merge.
> 11. **Issues para toda unidad de trabajo** — Abrir issue antes de empezar; cerrar automáticamente con `Closes #n` en el PR.
> 12. **Seeds para toda gestión de datos** — Estructura, datos base y datos de prueba se crean via seeds en 3 capas: `schema`, `base` y `test`. Corren automáticamente en cada deploy (`make seed`). Los seeds de `test` solo se ejecutan si `APP_ENV` es `development` o `test`, nunca en `production`. Siempre idempotentes.
>
> ¿Los acepta tal como están, o desea modificar o agregar algo?"

**Wait for the user's response.** Incorporate any changes or additions they specify.

Then invoke `/speckit-constitution` with the confirmed (and possibly modified) principles plus the inferred project name from the current directory or any manifest (`package.json`, `pyproject.toml`, `go.mod`).

---

### Case B — `customized` (constitution already has content)

Read the existing constitution and validate that **each of the seven required principles** is addressed. Exact wording need not match, but the constraint must be present and unambiguous.

Build a list of gaps — principles that are missing or too vague to enforce.

**Present the findings to the user before making any changes:**

> "Revisé la constitución existente. [Si hay gaps:] Los siguientes principios requeridos no están cubiertos o están incompletos:
>
> - **[Principio X]**: [descripción breve de qué falta]
> - …
>
> Voy a agregarlos como enmiendas. ¿Los acepta tal como están, o desea ajustar algo antes?"
>
> [Si no hay gaps:] "La constitución ya cubre todos los principios requeridos. No es necesario hacer cambios."

**Wait for the user's response.** If they approve (with or without modifications), invoke `/speckit-constitution` passing only the gaps as amendments, incorporating any adjustments the user specified. If there are no gaps, skip.

---

After a successful run, these slash commands are available in the project:

| Command | Purpose |
|---|---|
| `/speckit-constitution` | Establish project principles |
| `/speckit-specify` | Create a feature specification |
| `/speckit-plan` | Generate an implementation plan |
| `/speckit-tasks` | Break plan into actionable tasks |
| `/speckit-implement` | Execute the implementation |

Optional enhancement commands: `/speckit-clarify`, `/speckit-analyze`, `/speckit-checklist`

## What gets installed

- `.claude/skills/speckit-*/SKILL.md` — spec-kit slash commands for Claude Code
- `.specify/scripts/bash/` — helper shell scripts
- `.specify/templates/` — spec, plan, tasks, checklist templates
- `.specify/memory/constitution.md` — project principles (only on first install)
- `.specify/extensions/git/` and `.specify/extensions/agent-context/` — bundled extensions
- `CLAUDE.md` — agent context file

Your `specs/` directory and all source code are never touched.

## Gotchas

- **Constitution overwrite** — `specify init --here --force` overwrites `.specify/memory/constitution.md` in older spec-kit versions. The driver backs it up before init and restores it after. As of v0.9.5 spec-kit itself preserves existing constitutions, but the backup is kept as a safety net.
- **Deprecation notice** — spec-kit 0.9.5 prints a deprecation notice about inline agent-context updates being disabled in v0.12.0. This is informational; the install still succeeds.
- **Integration detection** — the driver reads `.specify/integration.json` to detect which coding agent you use. If you switch agents later, pass the new integration name as an argument: `bash .claude/skills/install-spec-kit/driver.sh gemini`.
- **`gh` vs `curl`** — the driver prefers `gh api` for fetching the latest release tag (respects `GITHUB_TOKEN` auth for private network environments). If `gh` is unavailable it falls back to unauthenticated `curl` against the public GitHub API.
- **First install in empty dir** — spec-kit also runs `git init` and commits the scaffolding. Pass `--no-git` inside the driver if you manage version control differently (edit the `specify init` line in driver.sh).

## Troubleshooting

**`command not found: uv`** — install uv first:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env   # or restart shell
```

**`command not found: specify` after install** — uv installs to `~/.local/bin`; ensure it's in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Slash commands not appearing in Claude Code** — restart Claude Code after running the driver (command files are loaded at startup).

**Already at latest but want to re-run init** — the driver is idempotent; running it again is safe.
