#!/usr/bin/env bash
# Reproduce the ZMK GitHub Actions build locally with Docker (Linux/macOS/WSL).
# Usage:  ./docker/run-ci.sh
#
# Builds every entry in ../build.yaml and drops named .uf2 files in ../firmware/.
# Requires Docker running.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
IMG="zmk-eyelash-ci"
OUT="$REPO/firmware"

# 1) build the local image if missing (pulls the ZMK toolchain base + adds yq)
if ! docker image inspect "$IMG" >/dev/null 2>&1; then
  echo "Building local CI image ($IMG)..."
  docker build -t "$IMG" "$HERE"
fi

mkdir -p "$OUT"

# 2) run the pipeline (init/update the cached workspace, build all of build.yaml)
echo "Running CI pipeline (building every entry in build.yaml)..."
docker run --rm \
  -v zmk-ws:/workspace \
  -v "$REPO/config:/workspace/config" \
  -v "$REPO:/repo" \
  -v "$HERE:/docker" \
  -v "$OUT:/out" \
  -w /workspace "$IMG" \
  bash -c "tr -d '\r' < /docker/ci-pipeline.sh | bash"

echo ""
echo "Artifacts -> $OUT"
ls -la "$OUT"/*.uf2 2>/dev/null || true
