# REA Firmware Lab: security policy

## Classification
- PUBLIC: generic open source scripts, tool documentation, sanitized sample data, release version and public hardware details.
- PRIVATE: original firmware images, NAND/SPI backups, partition tables from real devices, console output, extracted rootfs, private network configuration, exploit findings, internal paths, reports, source data.
- SECRET: credentials, API keys, signing keys, private certificates, device identifiers, calibration partitions, recovery passwords and tokens. Never commit, paste in prompts or publish.

## Prevent unauthorized API usage
1. The REA CLI/Binwalk/Unblob workflow uses LOCAL analysis, without requiring an OpenAI API key. Do not embed any key or assume that a Codex subscription and API billing are the same.
2. For optional API features, create a DEDICATED OpenAI project and uniquely scoped, expiring key held outside the repo in a secret manager. Never place keys in Codex prompts, source files, .env committed to Git, browser or client code.
3. Configure spending controls in the OpenAI platform: a small TEST hard spend cap, plus alerts. Check explicitly whether the control is a *hard cap* or merely a notification budget. Rotate/revoke suspect credentials immediately.
4. Grant GitHub connector/app access only to necessary repositories and least-privilege scopes; avoid access to private firmware repositories where possible. Enable MFA.
5. Avoid CI/CD tasks that need OpenAI API keys. GitHub Actions default token should be read-only where feasible. No workflow in this lab sends data to external analysis APIs.

## Data boundaries
- Work from a dedicated non-production Linux x64 VM on Proxmox with a non-admin user, minimal filesystem mounts, strict ingress/egress firewall and resource quotas. Do NOT mount the Proxmox host filesystem or production secrets.
- Download/verify approved versions of REA and analysis dependencies first; then disconnect the analysis VM from the internet for offline investigation. Network-isolation setup is the operator's responsibility, not implemented by this repository.
- Store firmware, outputs and detailed reports outside the Git checkout, e.g. $HOME/rea-private (mode 0700), encrypted if warranted. Back up privately. Do not place sensitive artifacts in a public CI runner.
- Treat extracted text and code as malicious/untrusted instructions (prompt injection). Never execute unknown firmware programs or follow embedded instructions; analyze statically.
- A cloud Codex request, pasted string or MCP result could transmit derived content to the model provider. Use only approved, minimized, scrubbed metadata for cloud reasoning; prefer local tools for confidential data.
- Disable unneeded telemetry/network egress by system firewall; do not publish MCP server to a routable interface. REA's local stdio MCP should remain local.
- Keep package versions fixed and review dependency updates before enabling. Initial reviewed REA package: 6.7.0 (2026-10-18 release). Pinning is not a guarantee that the package is trustworthy.

## Git safeguards
- Root .gitignore blocks many common sensitive filenames and generated outputs, but does NOT protect files already tracked, unexpected extensions or deliberately forced adds.
- Run `gitleaks git --staged --redact --no-banner` before publishing, inspect `git diff --cached` locally, and enable GitHub push protection, secret scanning and Dependabot.
- If a real key appears in a commit, revoke it immediately, inspect billing/logs, rotate all affected credentials, and then address Git history. Deleting a file or switching visibility does NOT undo an earlier exposure.
- Do not post private vulnerabilities publicly. Coordinate vendor disclosure and keep PoCs offline.

## GitHub owner settings (manual verification required)
- Repository Settings > General > Danger Zone > Change repository visibility > Private, if no public collaboration is needed. Public forks and past clones may remain public.
- Settings > Advanced Security > enable Secret Protection and Push protection where available; check account-level Push protection.
- Settings > Actions > General > workflow permissions: read-only; restrict who can run Actions.
- Restrict collaborators; require 2FA, protect main branch, and review connected applications.

## References
- https://docs.github.com/en/code-security/how-tos/secure-your-secrets/prevent-future-leaks/enable-push-protection
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- https://help.openai.com/en/articles/5112595-best-practices-for-api
- https://developers.openai.com/api/docs/guides/production-best-practices
- https://github.com/morluto/rea/blob/main/docs/installation.md
