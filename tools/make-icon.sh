#!/bin/bash
# Renders the app icon and packs it into Resources/Scribo.icns.
# Requires macOS (sips + iconutil).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
MASTER="${WORK}/icon_1024.png"
ICONSET="${WORK}/Scribo.iconset"
OUT="${ROOT}/Resources/Scribo.icns"

echo "▶ Rendering master PNG…"
swift "${ROOT}/tools/make-icon.swift" "${MASTER}"

echo "▶ Building iconset…"
mkdir -p "${ICONSET}"
sizes=(16 32 128 256 512)
for s in "${sizes[@]}"; do
  s2=$((s * 2))
  sips -z "$s"  "$s"  "${MASTER}" --out "${ICONSET}/icon_${s}x${s}.png"      >/dev/null
  sips -z "$s2" "$s2" "${MASTER}" --out "${ICONSET}/icon_${s}x${s}@2x.png"   >/dev/null
done

echo "▶ Packing .icns…"
iconutil -c icns "${ICONSET}" -o "${OUT}"
rm -rf "${WORK}"
echo "✅ Wrote ${OUT}"
