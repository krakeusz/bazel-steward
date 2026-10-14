#!/usr/bin/env bash
# Copy the host checkout into a Docker volume once. Later opens reuse that
# volume, so editor and agent writes stay on the Linux VM filesystem.
set -euo pipefail

readonly volume="${BAZEL_STEWARD_SRC_VOLUME:-bazel-steward-dev-src}"
readonly cache_volume="${BAZEL_STEWARD_CACHE_VOLUME:-bazel-steward-dev-cache}"
readonly workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The image user is uid 1001. Opening from macOS does not remap that uid, so the
# volume must be owned by 1001 rather than the host user.
readonly uid=1001
readonly gid=1001
readonly helper_image="${BAZEL_STEWARD_SEED_IMAGE:-alpine:3.20}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null || fail "docker is required to seed the devcontainer volume"
docker info >/dev/null 2>&1 || fail "Docker is not running"

docker volume create "${volume}" >/dev/null
docker volume create "${cache_volume}" >/dev/null

seeded="$(docker run --rm -v "${volume}:/workspace:ro" "${helper_image}" \
  sh -c 'if [ -f /workspace/MODULE.bazel ] && [ -d /workspace/.git ]; then printf yes; else printf no; fi')"

if [[ "${seeded}" != "yes" ]]; then
  seed="$(mktemp -d)"
  trap 'rm -rf "${seed}"' EXIT

  git clone --local "${workspace}" "${seed}/repo"
  git -C "${seed}/repo" remote set-url origin "$(git -C "${workspace}" remote get-url origin)"
  git -C "${seed}/repo" config core.filemode true
  git -C "${seed}/repo" config core.autocrlf false

  docker run --rm \
    -v "${volume}:/workspace" \
    -v "${seed}/repo:/src:ro" \
    "${helper_image}" \
    sh -c "find /workspace -mindepth 1 -delete && cp -a /src/. /workspace/"

  printf 'Seeded %s from %s.\n' "${volume}" "${workspace}"
else
  printf 'Workspace volume %s already contains the checkout.\n' "${volume}"
fi

git_name="$(git -C "${workspace}" config --get user.name || true)"
git_email="$(git -C "${workspace}" config --get user.email || true)"
if [[ -n "${git_name}" && -n "${git_email}" ]]; then
  docker run --rm \
    -e GIT_NAME="${git_name}" \
    -e GIT_EMAIL="${git_email}" \
    -v "${volume}:/workspace" \
    "${helper_image}" \
    sh -c 'grep -q "^\[user\]" /workspace/.git/config || printf "[user]\n\tname = %s\n\temail = %s\n" "$GIT_NAME" "$GIT_EMAIL" >> /workspace/.git/config'
fi

docker run --rm \
  -v "${volume}:/workspace" \
  -v "${cache_volume}:/cache" \
  "${helper_image}" \
  sh -c "chown -R ${uid}:${gid} /workspace && chown ${uid}:${gid} /cache"
