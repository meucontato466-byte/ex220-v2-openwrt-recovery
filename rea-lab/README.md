# REA Firmware Lab — Codex integration

The REA project (https://github.com/morluto/rea) exposes firmware tools to Codex through MCP. **No AI retraining is necessary**. This is a static analysis laboratory, not a firmware flasher.

## Setup (Linux x64 VM or WSL2)

Requirements: compatible Node.js (22.19+, 24.11+, 26+), Binwalk 3.1.x, Unblob 26.6.x, procps `ps`, util-linux `prlimit`, plus format-specific Unblob extractors. Refer to the official installation guides for building Binwalk and Unblob; some distro packages are outdated.

Run:
```bash
bash rea-lab/bootstrap.sh            # preview
bash rea-lab/bootstrap.sh --apply    # approvals and MCP registration for Codex
npx rea-agents@latest doctor --client codex --json
```

Restart Codex after setup. Codex Cloud environments are separate from local machines: they need their own environment setup and installed native tools. The `AGENTS.md` file guides Codex but **does not install the MCP**.

Use read-only analysis:
```bash
bash rea-lab/analyze-firmware.sh /absolute/path/to/firmware.bin device-revision
```

The script creates a uniquely named local output under `rea-lab/output/` and emits a manifest plus REA inspection/extraction reports. Never upload raw dumps or extracted calibration/secrets to a public repo.

Example Codex prompt: "Using the REA MCP tools, inspect /absolute/path/firmware.bin, extract to a new output directory, inventory components and produce the evidence-based report described in rea-lab/report-template.md. Do not execute extracted files or write to hardware."

A new device firmware requires independent confirmation of SoC, drivers, DTB, boot chain, flash layout, radio calibration, signatures and physical recovery before any flashing.

Sources:
- https://github.com/morluto/rea/blob/main/docs/installation.md
- https://github.com/morluto/rea/blob/main/docs/firmware-analysis.md
- https://github.com/ReFirmLabs/binwalk
- https://github.com/onekey-sec/unblob
