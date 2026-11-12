#!/usr/bin/env bash
# Upgrade everything installed with Homebrew and uv, tidy up, then rewrite the
# Brewfile to match what's installed.
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
# Rewrite the Brewfile from what's installed, so it never drifts. npm globals
# are left out: they belong to fnm's Node, not Homebrew.
dump=$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file=- 2>/dev/null | grep -v -E '^(#|npm )') ||
  dump=""
if [[ -z $dump ]]; then
  echo "  Couldn't read what's installed; Brewfile left as it was."
  FAILED+=("brew bundle dump")
elif [[ $dump == "$(<"$BREWFILE")" ]]; then
  echo "  Already matches what's installed."
else
  echo "  Updated to match what's installed (not committed):"
  { diff <(cat "$BREWFILE") <(printf '%s\n' "$dump") || true; } |
    sed -n 's/^< /    - /p; s/^> /    + /p'
  printf '%s\n' "$dump" >"$BREWFILE"
fi

if ((${#FAILED[@]})); then
  step "⚠️  These steps failed:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
step "✅ All upgrades completed!"
