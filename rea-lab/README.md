# REA Firmware Lab for Codex

Read `rea-lab/SECURITY.md` before using this repo. This GitHub repository is currently **PUBLIC**. Never upload confidential inputs or analysis output. Security policy: local-only by default; no external API key required for Binwalk/Unblob/REA local CLI.

## Host prerequisites

- Dedicated, non-production Linux x64 VM (Proxmox recommended), non-admin user and disk encryption where appropriate.
- Node.js supported by REA, Binwalk 3.1.x, Unblob 26.6.x, `ps` and `prlimit`.
- Pre-install vetted dependencies with network access temporarily allowed; disconnect the VM from the internet before examining private firmware. The firewall/network isolation is not automated by these scripts.
- Select the REA version explicitly; this lab uses 6.7.0. Updates require security review.

## Read-only MCP setup for Codex

From a checkout of the feature branch, run:
```bash
bash rea-lab/bootstrap.sh
# Review the setup plan, then:
bash rea-lab/bootstrap.sh --apply
npx --yes rea-agents@6.7.0 doctor --client codex --json
```

Restart Codex. REA setup registers a LOCAL stdio MCP server for Codex; never expose it as a publicly reachable MCP service. Setting up an MCP server does not make your GitHub repo private, grant authorization to share sensitive firmware with cloud models, or create a cost cap.

## Analyze firmware safely

1. Create a private directory OUTSIDE the Git checkout, such as `$HOME/rea-private`, permission 0700.
2. Put the firmware there via a local transfer. Do not copy raw dumps to GitHub or Codex Cloud.
3. First use the REA CLI locally, or use Codex MCP only for content approved to share with the service. Firmware bytes and tool results could be visible to a hosted model depending on the environment.
4. Inspect the SHA-256, partition signatures and extraction metadata; do not execute any extracted program. Record full reports privately.
5. Only publish short REDACTED summaries after manual review.

The insecure first-draft `rea-lab/analyze-firmware.sh` helper was removed from this branch: it wrote analysis output in the Git checkout and used `@latest`. Use the pinned REA CLI directly with PRIVATE paths outside Git:

```bash
umask 077
mkdir -p "$HOME/rea-private"
chmod 700 "$HOME/rea-private"
# Place authorized firmware in this private directory by a local transfer.
npx --offline --yes rea-agents@6.7.0 inspect-firmware-regions "$HOME/rea-private/firmware.bin" --json > "$HOME/rea-private/regions.json"
npx --offline --yes rea-agents@6.7.0 extract-firmware "$HOME/rea-private/firmware.bin" "$HOME/rea-private/extracted-001" --json > "$HOME/rea-private/extraction.json"
```

Offline mode requires the pinned package to have been installed and cached earlier. Inspect tool versions and read the official REA firmware documentation before running. The extraction destination must not already exist, and output must never be committed or sent to external services.

## Before commit
```bash
gitleaks git --staged --redact --no-banner
git diff --cached
```
Install the reviewed Gitleaks v8.30.1 binary and the pre-commit framework locally, then run `pre-commit install` to enable `.pre-commit-config.yaml`. Scanning cannot catch every leak; GitHub push protection and manual review remain necessary.

### Reference material
- https://github.com/morluto/rea/blob/main/docs/installation.md
- https://github.com/morluto/rea/blob/main/docs/firmware-analysis.md
- https://github.com/ReFirmLabs/binwalk
- https://github.com/onekey-sec/unblob

The experimental Python scanner was removed after failing validation. Use Gitleaks instead.
