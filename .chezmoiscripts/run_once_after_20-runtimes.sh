#!/bin/bash
# Node/pnpm via mise, pnpm supply-chain guard, Claude Code
set -euo pipefail
eval "$(/opt/homebrew/bin/brew shellenv)"
mise use -g node@lts pnpm@latest
mise exec -- pnpm config set minimum-release-age 1440 --global
if ! command -v claude >/dev/null && [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
