#!/usr/bin/env bash
# Sets up the developer's shell environment inside the container. Runs from
# post-create; safe to re-run by hand after editing a profile.
#
# The startup script is ~/.config/bazel-steward/devcontainer.sh on the host,
# mounted read-only at the same path in the container. Without it, the default
# profile runs.
set -euo pipefail

devcontainer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly devcontainer_dir
export BAZEL_STEWARD_PROFILES="${devcontainer_dir}/profiles"
readonly personal_script="${HOME}/.config/bazel-steward/devcontainer.sh"
readonly common_rc="${devcontainer_dir}/shell/common.sh"

ensure_line() {
  local file="$1" line="$2"
  touch "${file}"
  grep -qxF "${line}" "${file}" || printf '%s\n' "${line}" >> "${file}"
}

if [[ -f "${personal_script}" ]]; then
  printf 'Running personal startup script %s.\n' "${personal_script}"
  bash "${personal_script}"
else
  printf 'No ~/.config/bazel-steward/devcontainer.sh on the host; using the default profile.\n'
  bash "${BAZEL_STEWARD_PROFILES}/default.sh"
fi

ensure_line "${HOME}/.zshrc" ". ${common_rc}"
ensure_line "${HOME}/.bashrc" ". ${common_rc}"
