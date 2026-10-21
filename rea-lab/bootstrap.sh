#!/usr/bin/env bash
# Explicitly pinned release: audit upstream before changing REA_VERSION.
set -euo pipefail
umask 077
REA_VERSION="6.7.0"
[[ "${1:-}" == "" || "${1:-}" == "--apply" ]] || { echo "Usage: bash rea-lab/bootstrap.sh [--apply]" >&2; exit 2; }
command -v npx >/dev/null || { echo "Node.js/npm missing" >&2; exit 1; }
if [[ "${1:-}" == "--apply" ]]; then
  echo "REA setup will change Codex MCP registration after interactive approval."
  npx --yes "rea-agents@${REA_VERSION}" setup --client codex
else
  echo "Read-only REA setup preview; npm may download the pinned package."
  npx --yes "rea-agents@${REA_VERSION}" setup --client codex --dry-run
  echo "Review source/dependencies and approve explicitly: bash rea-lab/bootstrap.sh --apply"
fi
echo "Validation: npx --yes rea-agents@${REA_VERSION} doctor --client codex --json"
