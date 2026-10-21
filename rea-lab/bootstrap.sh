#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "" || "${1:-}" == "--apply" ]] || { echo "Usage: bash rea-lab/bootstrap.sh [--apply]"; exit 2; }
command -v npx >/dev/null || { echo "Install Node.js and npm first"; exit 1; }
if [[ "${1:-}" == "--apply" ]]; then
  npx rea-agents@latest setup --client codex
  echo "Restart Codex, then run: npx rea-agents@latest doctor --client codex --json"
else
  npx rea-agents@latest setup --client codex --dry-run
  echo "Review the plan. To apply: bash rea-lab/bootstrap.sh --apply"
fi
