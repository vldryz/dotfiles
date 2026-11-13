#!/usr/bin/env bash
# Upgrade everything installed with Homebrew, uv and rustup, tidy up, then
# rewrite the Brewfile to match what's installed.
#
# Apps that update themselves (Zen, Helium, T3 Code, Claude, ...) are skipped,
# so this never quits them mid-session. The exceptions, like Chrome, are listed
# in HOMEBREW_UPGRADE_GREEDY_CASKS in zsh/.zshenv.
#
# On a Mac with several accounts, Homebrew is upgraded only from the account
# that owns it; every account upgrades its own uv and rustup.
#
# A step that fails doesn't stop the others; failures are listed at the end.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# Brewfile.<hostname> if this Mac has one, otherwise Brewfile.
BREWFILE="$DOTFILES/Brewfile.$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
[[ -f $BREWFILE ]] || BREWFILE="$DOTFILES/Brewfile"
FAILED=()

step() { printf '\n%s\n' "$*"; }

# Run a command; if it fails, note it and carry on.
run() {
  if ! "$@"; then
    FAILED+=("$*")
  fi
}

if command -v brew &>/dev/null && [[ -O $(brew --prefix) ]]; then
  OWN_BREW=1
else
  OWN_BREW=0
fi

if ((OWN_BREW)); then
  step "📦 Homebrew"
  run brew update
  run brew upgrade --yes # --yes: upgrade without asking first
  run brew autoremove    # remove dependencies nothing needs anymore
elif command -v brew &>/dev/null; then
  step "📦 Homebrew: skipped (it belongs to $(stat -f %Su "$(brew --prefix)"); run upall there)"
fi

if command -v uv &>/dev/null; then
  step "🐍 uv"
  # uv from its own installer (not Homebrew) updates itself
  if [[ $(command -v uv) != "$(brew --prefix 2>/dev/null || echo /nonexistent)"/* ]]; then
    run uv self update
  fi
  run uv tool upgrade --all
fi

if command -v rustup &>/dev/null; then
  step "🦀 Rust"
  run rustup update
fi

step "🧹 Cleanup"
((OWN_BREW)) && run brew cleanup
command -v uv &>/dev/null && run uv cache prune

if ((OWN_BREW)); then
  step "📋 ${BREWFILE##*/}"
  # Rewrite the Brewfile from what's installed, so it never drifts. npm globals
  # are left out: they belong to fnm's Node, not Homebrew. So are uv tools
  # when uv isn't from Homebrew (then each account has its own).
  skip='^(#|npm )'
  brew list --formula uv &>/dev/null || skip='^(#|npm |uv )'
  dump=$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file=- 2>/dev/null | grep -v -E "$skip") ||
    dump=""
  if [[ -z $dump ]]; then
    echo "  Couldn't read what's installed; ${BREWFILE##*/} left as it was."
    FAILED+=("brew bundle dump")
  elif [[ $dump == "$(<"$BREWFILE")" ]]; then
    echo "  Already matches what's installed."
  else
    echo "  Updated to match what's installed (not committed):"
    { diff <(cat "$BREWFILE") <(printf '%s\n' "$dump") || true; } |
      sed -n 's/^< /    - /p; s/^> /    + /p'
    printf '%s\n' "$dump" >"$BREWFILE"
  fi
fi

if ((${#FAILED[@]})); then
  step "⚠️  These steps failed:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
step "✅ All upgrades completed!"
