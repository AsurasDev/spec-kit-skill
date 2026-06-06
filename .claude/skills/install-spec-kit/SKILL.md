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
