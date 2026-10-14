#!/usr/bin/env bash
# Example personal profile: applies github.com/krakeusz/linux-confs (zsh with
# oh-my-zsh, git, ssh and vim config). The repo is private, so this needs the
# forwarded ssh-agent. Use it from ~/.config/bazel-steward/devcontainer.sh:
#
#   source "${BAZEL_STEWARD_PROFILES}/linux-confs.sh"
set -euo pipefail

readonly linux_confs_repo="${LINUX_CONFS_REPO:-git@github.com:krakeusz/linux-confs.git}"
readonly linux_confs_dir="${LINUX_CONFS_DIR:-${HOME}/linux-confs}"

# The playbook reads ansible_env.USER; docker exec does not set USER.
export USER="${USER:-$(id -un)}"
# shellcheck source=/dev/null
. "${BAZEL_STEWARD_PROFILES}/../shell/common.sh"

if [[ -d "${linux_confs_dir}/.git" ]]; then
  git -C "${linux_confs_dir}" pull --ff-only
else
  git clone "${linux_confs_repo}" "${linux_confs_dir}"
fi

# The playbook's apt task also installs desktop apps (guake, meld). Install
# only its command-line packages and skip that task.
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  7zip fd-find htop iproute2 tree vim zsh
mkdir -p "${HOME}/.local/bin"
ln -sf /usr/bin/fdfind "${HOME}/.local/bin/fd"

cd "${linux_confs_dir}"
python3 src/linux_confs/bootstrap_plugins/install_uv.py
export PATH="${HOME}/.local/bin:${PATH}"
# Not `uv run run_ansible`: it prompts for a sudo password and exits 0 when the
# playbook fails. The inventory also lists a remote devcontainer host, hence --limit.
uv run ansible-galaxy collection install -r requirements.yml
ANSIBLE_CONFIG=ansible/ansible.cfg uv run ansible-playbook ansible/playbook-install-tools.yml \
  --limit localhost --skip-tags apt -e '{"has_gui": false}'
