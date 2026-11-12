#!/usr/bin/env bash
# Upgrade everything installed with Homebrew and uv, tidy up, then check that
# the Brewfile still matches what's installed.
#
# Apps that update themselves (Zen, Helium, T3 Code, Claude, ...) are skipped,
# so this never quits them mid-session. The exceptions, like Chrome, are listed
# in HOMEBREW_UPGRADE_GREEDY_CASKS in zsh/.zshenv.
#
# A step that fails doesn't stop the others; failures are listed at the end.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BREWFILE="$DOTFILES/Brewfile"
FAILED=()

step() { printf '\n%s\n' "$*"; }

# Run a command; if it fails, note it and carry on.
run() {
  if ! "$@"; then
    FAILED+=("$*")
  fi
}

step "📦 Homebrew"
run brew update
run brew upgrade --yes # --yes: upgrade without asking first
run brew autoremove    # remove dependencies nothing needs anymore

step "🐍 uv tools"
run uv tool upgrade --all

step "🧹 Cleanup"
run brew cleanup
run uv cache prune

step "📋 Brewfile"
export HOMEBREW_NO_AUTO_UPDATE=1 # updated above already
if brew bundle check --no-upgrade --file="$BREWFILE" >/dev/null 2>&1; then
  echo "  Everything in the Brewfile is installed."
else
  echo "  In the Brewfile but not installed:"
  # brew lists missing items on stderr and exits 1 when anything is missing
  { brew bundle check --no-upgrade --verbose --file="$BREWFILE" 2>&1 || true; } |
    sed -n 's/^→ /    /p'
fi
extra=$(brew bundle cleanup --file="$BREWFILE" 2>/dev/null |
  grep -v -E '^(==>|Run `brew bundle cleanup|[[:space:]]*$)' || true)
if [[ -n $extra ]]; then
  echo "  Installed but not in the Brewfile (add them to it, or uninstall them):"
  printf '%s\n' "$extra" | sed 's/^/    /'
else
  echo "  Nothing is installed that isn't in the Brewfile."
fi

if ((${#FAILED[@]})); then
  step "⚠️  These steps failed:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
step "✅ All upgrades completed!"
