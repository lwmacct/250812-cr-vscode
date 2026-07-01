#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel)"
cd "$root_dir"

image="${1:-ghcr.io/lwmacct/250812-cr-vscode:latest}"
platforms="${PLATFORMS:-linux/amd64,linux/arm64}"

docker buildx build \
  --builder "${BUILDER:-default}" \
  --platform "$platforms" \
  --file containers/latest/Dockerfile \
  --tag "$image" \
  --network host \
  --progress plain \
  --push \
  .
