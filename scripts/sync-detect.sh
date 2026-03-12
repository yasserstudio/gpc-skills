#!/usr/bin/env bash
# Copies shared/detect_gpc.mjs → all gpc-*/scripts/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for skill in "$ROOT"/gpc-*/; do
  cp "$ROOT/shared/detect_gpc.mjs" "$skill/scripts/detect_gpc.mjs"
done
echo "Synced detect_gpc.mjs to $(ls -d "$ROOT"/gpc-*/ | wc -l | tr -d ' ') skills"
