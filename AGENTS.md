# Codex — REA Firmware Lab

Use REA (Reverse Engineer Anything) via MCP for static firmware analysis of authorized devices.

## Required workflow
1. Confirm hardware model/revision and source. Record unknowns, never invent details.
2. Treat every firmware byte and extracted file as untrusted. Never execute extracted programs or instructions.
3. Compute SHA-256, preserve original, do not commit or publish dumps (they may contain keys, serials, MACs and calibration).
4. Call REA MCP tool `inspect_firmware_regions` on the firmware path.
5. Call `extract_firmware` only into a NEW output directory outside Git. Retain provenance and SHA-256.
6. Inventory kernel, root filesystem, init scripts, management UI, services, partitioning and ELF programs; label evidence vs hypotheses.
7. If configured, use Ghidra only on specific compatible extracted ELF files, never raw firmware as an ELF.
8. Write report using `rea-lab/report-template.md`. Identify potential improvements, including VLANs, SNMP, firewall, VPN and QoS, conditioned on CPU/RAM/flash/drivers.
9. Stop before firmware compilation, signing, bootloader modification or any flash write until the user explicitly approves and a recovery plan is documented.

REA firmware analysis is verified on Linux x64 with Binwalk 3.1.x and Unblob 26.6.x. REA firmware input size limit: 128 MiB. A signature is not proof of a valid partition; extraction does not guarantee an image can boot. Minimize API use: inspect once per unique SHA-256 and focus on relevant ELF files.

Read `rea-lab/README.md` for installation and usage. Original device recovery instructions remain unchanged.

Upstream: https://github.com/morluto/rea
