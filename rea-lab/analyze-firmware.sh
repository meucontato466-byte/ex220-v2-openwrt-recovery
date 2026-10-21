#!/usr/bin/env bash
# Authorized static firmware analysis only; never executes extracted binaries.
set -euo pipefail
[[ $# -ge 1 && $# -le 2 ]] || { echo "Usage: $0 /absolute/firmware.bin [case-name]" >&2; exit 2; }
[[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] || { echo "REA firmware workflow verified only for Linux x64" >&2; exit 1; }
input="$(realpath -- "$1")"
[[ -f "$input" && -s "$input" ]] || { echo "Firmware missing or empty" >&2; exit 1; }
size="$(stat -c %s "$input")"
(( size <= 128*1024*1024 )) || { echo "Firmware exceeds REA 128 MiB limit" >&2; exit 1; }
name="${2:-firmware}"
[[ "$name" =~ ^[[:alnum:]][[:alnum:]_.-]*$ ]] || { echo "Invalid case name" >&2; exit 2; }
for cmd in npx ps prlimit sha256sum; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
bw="${REA_BINWALK_COMMAND:-$(command -v binwalk || true)}"
ub="${REA_UNBLOB_COMMAND:-$(command -v unblob || true)}"
[[ -n "$bw" && -x "$bw" && -n "$ub" && -x "$ub" ]] || { echo "Set REA_BINWALK_COMMAND and REA_UNBLOB_COMMAND to installed tools" >&2; exit 1; }
bw="$(realpath "$bw")"
ub="$(realpath "$ub")"
[[ "$("$bw" --version 2>&1)" =~ ^binwalk[[:space:]]3\.1\. ]] || { echo "Requires Binwalk 3.1.x" >&2; exit 1; }
[[ "$("$ub" --version 2>&1)" =~ ^26\.6\. ]] || { echo "Requires Unblob 26.6.x" >&2; exit 1; }
export REA_BINWALK_COMMAND="$bw" REA_UNBLOB_COMMAND="$ub"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$root/output"
out="$(mktemp -d "$root/output/$name.XXXXXX")"
{
  printf 'Original: %s\nSize: %s bytes\n' "$input" "$size"
  sha256sum -- "$input"
  "$bw" --version
  "$ub" --version
} > "$out/manifest.txt"
if command -v rea >/dev/null; then
  cmd=(rea)
else
  cmd=(npx -y rea-agents@latest)
fi
"${cmd[@]}" inspect-firmware-regions "$input" --json > "$out/regions.json"
"${cmd[@]}" extract-firmware "$input" "$out/extracted" --json > "$out/extraction.json"
echo "Read-only analysis finished: $out"
echo "Keep outputs private and excluded from Git."
