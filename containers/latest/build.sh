#!/usr/bin/env bash
set -euo pipefail

__main() {
  :
  _root_dir="$(git rev-parse --show-toplevel)"
  cd "$_root_dir" || return 1

  _url=$(git remote get-url origin)
  _path=$(printf '%s\n' "$_url" | sed -E '
    s#^[^/:]+@[^:]+:##;
    s#^[a-zA-Z][a-zA-Z0-9+.-]*://([^@/]+@)?[^/]+/##;
    s#\.git$##
  ')

  _owner="${_path%/*}"
  _repo="${_path##*/}"
  _image="${1:-ghcr.io/${_owner}/${_repo}:latest}"
  _platforms="${PLATFORMS:-linux/amd64,linux/arm64}"

  docker buildx build \
    --builder "${BUILDER:-default}" \
    --platform "$_platforms" \
    --file containers/latest/Dockerfile \
    --tag "$_image" \
    --network host \
    --progress plain \
    --push \
    .

}

__main
