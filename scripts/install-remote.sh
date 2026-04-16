#!/usr/bin/env bash

# Setup script for remote Debian/Ubuntu servers.
# Installs core tools via apt, creates config symlinks, and sets zsh as default shell.

set -e

DOTFILES="$HOME/dotfiles"

# +-----------------+
# | CHECKS          |
# +-----------------+
if [[ ! -f /etc/debian_version ]]; then
  echo "Error: this script is intended for Debian/Ubuntu systems."
  exit 1
fi

if [[ ! -d "$DOTFILES" ]]; then
  echo "Error: dotfiles directory not found at $DOTFILES"
  exit 1
fi

# +-----------------+
# | APT PACKAGES    |
# +-----------------+
echo "📦 Installing packages via apt..."
sudo apt update
sudo apt install -y \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  bat

# +-----------------+
# | ZOXIDE          |
# +-----------------+
# apt ships an ancient version (0.4.x) that breaks with `alias cd="z"`,
# so install via the official script to get a current release
if ! command -v zoxide &>/dev/null; then
  echo "📂 Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# +-----------------+
# | STARSHIP        |
# +-----------------+
if ! command -v starship &>/dev/null; then
  echo "🚀 Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# +-----------------+
# | SYMLINKS        |
# +-----------------+
echo "🔗 Creating symlinks..."

link() {
  local target="$1" link_path="$2"
  if [[ -L "$link_path" ]] && [[ "$(readlink "$link_path")" == "$target" ]]; then
    echo "  ✓ $link_path (already exists)"
    return
  fi
  mkdir -p "$(dirname "$link_path")"
  ln -sfn "$target" "$link_path"
  echo "  → $link_path"
}

link "$DOTFILES/zsh/.zshenv"           "$HOME/.zshenv"
link "$DOTFILES/zsh/.zshrc"            "$HOME/.config/zsh/.zshrc"
link "$DOTFILES/zsh/.zprofile"         "$HOME/.config/zsh/.zprofile"
link "$DOTFILES/zsh/aliases.zsh"       "$HOME/.config/zsh/aliases.zsh"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship/starship.toml"

# +-----------------+
# | DEFAULT SHELL   |
# +-----------------+
if [[ "$SHELL" != */zsh ]]; then
  echo "🐚 Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi

echo "✅ Done! Log out and back in (or run 'exec zsh') to start using zsh."
