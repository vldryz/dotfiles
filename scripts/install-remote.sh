#!/usr/bin/env bash
# Provision a remote Ubuntu 22.04 machine with the same shell experience as
# the local macOS setup — using native apt packages (no Homebrew on Linux).
# Idempotent: safe to re-run.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if [ ! -d "$DOTFILES" ]; then
  echo "Error: expected dotfiles at $DOTFILES. Clone the repo there first." >&2
  exit 1
fi

# --- 1. System packages ---------------------------------------------------
# zsh-autosuggestions / zsh-syntax-highlighting / zoxide / bat / direnv / fnm
# zoxide is in 22.04 universe; bat ships the binary as `batcat` on Debian.
log "Installing apt packages"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zoxide \
  bat \
  direnv \
  git \
  curl \
  ca-certificates \
  locales \
  unzip

# Ensure a UTF-8 locale so starship glyphs render over SSH
if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf8$'; then
  sudo locale-gen en_US.UTF-8
fi

# --- 2. Starship (not in apt; official installer to ~/.local/bin) --------
if ! command -v starship >/dev/null 2>&1; then
  log "Installing starship"
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
fi

# --- 3. fnm (not in apt) --------------------------------------------------
if ! command -v fnm >/dev/null 2>&1 && [ ! -x "$HOME/.local/share/fnm/fnm" ]; then
  log "Installing fnm"
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/share/fnm"
  ln -sfn "$HOME/.local/share/fnm/fnm" "$HOME/.local/bin/fnm"
fi

# --- 4. Config directories ------------------------------------------------
log "Creating XDG config directories"
mkdir -p "$HOME/.config/zsh" "$HOME/.config/starship"

# --- 5. Symlink configs ---------------------------------------------------
log "Symlinking dotfiles"
ln -sfn "$DOTFILES/zsh/.zshrc"              "$HOME/.config/zsh/.zshrc"
ln -sfn "$DOTFILES/zsh/.zprofile"           "$HOME/.config/zsh/.zprofile"
ln -sfn "$DOTFILES/zsh/aliases.zsh"         "$HOME/.config/zsh/aliases.zsh"
ln -sfn "$DOTFILES/zsh/.zshenv"             "$HOME/.zshenv"
ln -sfn "$DOTFILES/starship/starship.toml"  "$HOME/.config/starship/starship.toml"

# --- 6. Quiet login banner -----------------------------------------------
touch "$HOME/.hushlogin"

# --- 7. Default shell -> zsh ---------------------------------------------
ZSH_BIN="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
  log "Changing default shell to $ZSH_BIN"
  if ! grep -qx "$ZSH_BIN" /etc/shells; then
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  fi
  sudo chsh -s "$ZSH_BIN" "$USER"
fi

log "Done. Start a new shell (or run: exec zsh -l)."
log "Note: Debian ships \`bat\` as \`batcat\`. Add an alias if you want \`bat\`."
