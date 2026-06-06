#!/usr/bin/env bash
# Install or upgrade spec-kit (github/spec-kit) in the current project.
# Usage: bash .claude/skills/install-spec-kit/driver.sh [integration]
#   integration  claude|copilot|gemini|codebuddy|pi  (default: auto-detected or claude)
set -euo pipefail

step() { echo "==> $*"; }

# Get latest release tag from GitHub
latest_tag() {
  if command -v gh &>/dev/null; then
    gh api repos/github/spec-kit/releases/latest --jq '.tag_name' 2>/dev/null && return
  fi
  curl -sf "https://api.github.com/repos/github/spec-kit/releases/latest" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])"
}

# Detect integration from existing project config, fallback to arg or 'claude'
project_integration() {
  local cfg=".specify/integration.json"
  if [ -f "$cfg" ]; then
    python3 -c "import json; d=json.load(open('$cfg')); print(d.get('integration','claude'))"
    return
  fi
  echo "${1:-claude}"
}

# --- Prerequisites ---
if ! command -v uv &>/dev/null; then
  echo "ERROR: uv is required. Install from https://docs.astral.sh/uv/"
  echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
  exit 1
fi

# --- Resolve settings ---
LATEST=$(latest_tag)
INTEGRATION=$(project_integration "${1:-claude}")
step "Latest spec-kit: $LATEST  |  Integration: $INTEGRATION"

# --- Install or upgrade the CLI ---
if ! command -v specify &>/dev/null; then
  step "Installing specify-cli $LATEST via uv..."
  uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git@$LATEST"
else
  CURRENT=$(specify version 2>&1 | tr -d '│ ' | grep 'CLIVersion' | sed 's/CLIVersion//')
  if [ "v${CURRENT}" = "$LATEST" ]; then
    step "CLI already up to date: $CURRENT"
  else
    step "Upgrading CLI: $CURRENT → $LATEST..."
    specify self upgrade
  fi
fi

# --- Back up constitution before force-init (it gets overwritten) ---
CONSTITUTION=".specify/memory/constitution.md"
CONSTITUTION_BAK="${CONSTITUTION}.bak"
if [ -f "$CONSTITUTION" ]; then
  cp "$CONSTITUTION" "$CONSTITUTION_BAK"
  step "Backed up $CONSTITUTION"
fi

# --- Initialize or update project files ---
step "Running: specify init --here --force --integration $INTEGRATION --ignore-agent-tools"
specify init --here --force --integration "$INTEGRATION" --ignore-agent-tools

# --- Restore constitution ---
if [ -f "$CONSTITUTION_BAK" ]; then
  mv "$CONSTITUTION_BAK" "$CONSTITUTION"
  step "Restored $CONSTITUTION from backup (customizations preserved)"
fi

echo ""
echo "Done. spec-kit $LATEST installed with $INTEGRATION integration."
echo "Available slash commands: /speckit-specify  /speckit-plan  /speckit-tasks  /speckit-implement"
