#!/usr/bin/env python3
"""Fail-closed local pre-commit check for suspicious staged files.

Heuristic only: this is not a substitute for GitHub push protection, MFA,
restricted repository access and manual review of the staged diff.
No network and no secrets printed.
"""
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

MAX_BYTES = 256 * 1024
BLOCK_EXT = {
    ".bin", ".img", ".rom", ".dump", ".raw", ".nand", ".spi", ".mtd",
    ".squashfs", ".ubifs", ".elf", ".so", ".zip", ".tar", ".gz",
    ".xz", ".7z", ".pdf", ".pcap", ".pcapng", ".har", ".db",
    ".sqlite", ".sqlite3", ".pem", ".key", ".p12", ".pfx"
}
BLOCK_DIR = {
    "backup", "firmware", "dumps", "private", "rea-private",
    "analysis-private", "reports-private", "output", "artifacts"
}
PATTERNS = {
    "OpenAI key": re.compile(rb"sk-(?:proj-|svcacct-|admin-)?[A-Za-z0-9_-]{20,}"),
    "GitHub token": re.compile(rb"(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})"),
    "AWS key ID": re.compile(rb"AKIA[0-9A-Z]{16}"),
    "Slack token": re.compile(rb"xox[baprs]-[A-Za-z0-9-]{15,}"),
    "Private key header": re.compile(rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----"),
    "JWT value": re.compile(rb"eyJ[A-Za-z0-9_-]{16,}\\.eyJ[A-Za-z0-9_-]{16,}\\.[A-Za-z0-9_-]{12,}"),
    "hardcoded credential": re.compile(
        rb"(?im)^\\s*(?:export\\s+)?(?:OPENAI_API_KEY|GITHUB_TOKEN|AWS_SECRET_ACCESS_KEY|"
        rb"API_SECRET|PASSWORD|PASSWD)\\s*[:=]\\s*['\\\"]?"
        rb"(?!\\$|\\{|<|example|placeholder|changeme|dummy)[A-Za-z0-9/_+=.-]{12,}"
    ),
}

def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], check=True, capture_output=True).stdout

def scan() -> int:
    try:
        names = [n.decode("utf-8", errors="surrogateescape")
                 for n in git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR").split(b"\\x00") if n]
    except (subprocess.CalledProcessError, OSError) as exc:
        print("ERROR: cannot inspect staged files:", type(exc).__name__, file=sys.stderr)
        return 2
    errors: list[str] = []
    for name in names:
        path = pathlib.PurePosixPath(name)
        lower = name.casefold()
        if any(part.casefold() in BLOCK_DIR for part in path.parts):
            errors.append(f"{name}: protected directory")
            continue
        if path.suffix.casefold() in BLOCK_EXT or path.name.startswith(".env") or "credential" in lower or "secret" in lower:
            errors.append(f"{name}: forbidden filename/type")
            continue
        try:
            data = git("show", f":{name}")
        except (subprocess.CalledProcessError, OSError):
            errors.append(f"{name}: unreadable staged content")
            continue
        if len(data) > MAX_BYTES:
            errors.append(f"{name}: staged file exceeds audit limit")
            continue
        if b"\\x00" in data:
            errors.append(f"{name}: binary data")
            continue
        try:
            data.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"{name}: non-UTF-8 data")
            continue
        for label, regex in PATTERNS.items():
            if regex.search(data):
                errors.append(f"{name}: suspected {label}")
    if errors:
        print("BLOCKED: suspicious staged material; review privately (values are not printed).", file=sys.stderr)
        for error in errors:
            print(" - " + error, file=sys.stderr)
        return 1
    print(f"OK: {len(names)} staged file(s) passed local heuristic screening.")
    return 0

if __name__ == "__main__":
    if sys.argv[1:] != ["--staged"]:
        sys.exit("Usage: python3 rea-lab/security/preflight.py --staged")
    sys.exit(scan())
