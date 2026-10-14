# shellcheck shell=sh
# Sourced from ~/.zshrc and ~/.bashrc in the devcontainer.

# Cursor forwards the host ssh-agent through /tmp/cursor-remote-ssh-*.sock,
# one socket per editor connection. Sockets from closed connections stay on
# disk but refuse connections, and new shells can inherit one of those.
_devcontainer_agent_alive() {
  SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1
  [ $? -ne 2 ]
}

_devcontainer_fix_ssh_agent() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt local_options null_glob
  fi
  if [ -n "${SSH_AUTH_SOCK:-}" ] && _devcontainer_agent_alive "${SSH_AUTH_SOCK}"; then
    return 0
  fi
  for _devcontainer_sock in /tmp/cursor-remote-ssh-*.sock; do
    if [ -S "${_devcontainer_sock}" ] && _devcontainer_agent_alive "${_devcontainer_sock}"; then
      export SSH_AUTH_SOCK="${_devcontainer_sock}"
      break
    fi
  done
  unset _devcontainer_sock
}

_devcontainer_fix_ssh_agent
unset -f _devcontainer_fix_ssh_agent _devcontainer_agent_alive
