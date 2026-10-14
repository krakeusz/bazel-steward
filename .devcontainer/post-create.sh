#!/usr/bin/env bash
# Runs inside the container after the volume workspace is mounted.
set -euo pipefail

cd /workspaces/bazel-steward

git config --global --get-all safe.directory 2>/dev/null | grep -qx /workspaces/bazel-steward \
  || git config --global --add safe.directory /workspaces/bazel-steward

if [[ ! -f .bazelrc.local ]]; then
  cat > .bazelrc.local <<'EOF'
startup --output_user_root=/home/runner/.cache/bazel/output
build --disk_cache=/home/runner/.cache/bazel/disk
EOF
fi

# Download the pinned Bazel now so the first edit does not wait on Bazelisk.
bazel version

printf '%s\n' \
  "Workspace /workspaces/bazel-steward is on a Linux volume (not a macOS bind mount)." \
  "Check the project with: bazel test --test_tag_filters=unit //..."
