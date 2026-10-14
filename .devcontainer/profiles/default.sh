#!/usr/bin/env bash
# Default profile: zsh as the login shell, configured like a fresh macOS account.
set -euo pipefail

if ! command -v zsh >/dev/null; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends zsh
fi
sudo usermod --shell "$(command -v zsh)" "$(id -un)"

# Without ~/.zshrc, Ubuntu's zsh opens its interactive new-user wizard.
if [[ ! -e "${HOME}/.zshrc" ]]; then
  cat > "${HOME}/.zshrc" <<'EOF'
# Mirrors macOS /etc/zshrc defaults.
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=2000
SAVEHIST=1000
setopt share_history
bindkey -e
PS1='%n@%m %1~ %# '

[[ -d $HOME/.local/bin ]] && path=($HOME/.local/bin $path)
EOF
fi
