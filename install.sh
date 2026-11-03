#!/usr/bin/env bash
# Set up a Mac from this repo: Homebrew, the Brewfile, and config symlinks.
#
# Safe to re-run. Links that are already right are left alone, and an existing
# config that differs from the repo is never replaced unless you say how
# (--adopt or --overwrite). Anything replaced is moved to ~/.dotfiles-backup/.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--check] [--no-brew] [--adopt | --overwrite]

  --check      Show what would change; change nothing.
  --no-brew    Skip Homebrew and the Brewfile; only link configs.
  --adopt      For existing configs that differ from the repo: keep them,
               copy them into the repo (review with `git diff`), then link.
  --overwrite  For existing configs that differ from the repo: back them up
               to ~/.dotfiles-backup/ and link the repo's version.

Without --adopt/--overwrite, differing configs are left alone and listed.
EOF
}

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Repo path -> where it gets linked. Karabiner is linked as a whole directory:
# when it saves, it replaces a symlinked karabiner.json with a plain file.
LINKS=(
  "zsh/.zshenv             $HOME/.zshenv"
  "zsh/.zshrc              $HOME/.config/zsh/.zshrc"
  "zsh/.zprofile           $HOME/.config/zsh/.zprofile"
  "zsh/aliases.zsh         $HOME/.config/zsh/aliases.zsh"
  "starship/starship.toml  $HOME/.config/starship/starship.toml"
  "ghostty/config          $HOME/.config/ghostty/config"
  "zed/settings.json       $HOME/.config/zed/settings.json"
  "zed/keymap.json         $HOME/.config/zed/keymap.json"
  "karabiner               $HOME/.config/karabiner"
  "claude/skills/unslop    $HOME/.claude/skills/unslop"
)

CHECK=0
BREW=1
ON_DIFF=skip
for arg in "$@"; do
  case $arg in
    --check) CHECK=1 ;;
    --no-brew) BREW=0 ;;
    --adopt) ON_DIFF=adopt ;;
    --overwrite) ON_DIFF=overwrite ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

TILDE='~'
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BACKED_UP=0
ADOPTED=0
PROBLEMS=""   # newline-separated, reported at the end

section() { printf '\n%s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
act() { if ((CHECK)); then printf '  → would %s\n' "$*"; else printf '  → %s\n' "$*"; fi; }
problem() { printf '  ! %s\n' "$*"; PROBLEMS+="$*"$'\n'; }
pretty() { printf '%s' "${1/#$HOME/$TILDE}"; }

# Move a path into the backup dir, keeping its location relative to $HOME.
backup() {
  local dest="$BACKUP_DIR/${1#"$HOME"/}"
  mkdir -p "$(dirname "$dest")"
  mv "$1" "$dest"
  BACKED_UP=1
}

link_one() {
  local rel=$1 dst=$2
  local src="$DOTFILES/$rel" shown
  shown=$(pretty "$dst")

  if [[ ! -e $src ]]; then
    problem "$rel is missing from the repo; $shown not linked"
    return
  fi
  if [[ -L $dst && $dst -ef $src ]]; then
    ok "$shown"
    return
  fi

  local replace=1
  if [[ -L $dst && ! -e $dst ]]; then
    act "replace broken link $shown"
  elif [[ -e $dst || -L $dst ]]; then
    if diff -rq "$dst" "$src" >/dev/null 2>&1; then
      act "replace $shown (same content as the repo)"
    else
      case $ON_DIFF in
        skip)
          problem "$shown differs from the repo; left alone (compare: diff -ru $shown $(pretty "$src"))"
          return
          ;;
        adopt)
          act "copy $shown into the repo, then link it"
          if ((!CHECK)); then
            if [[ -d $src ]]; then cp -Rp "$dst"/. "$src"/; else cp -p "$dst" "$src"; fi
            ADOPTED=1
          fi
          ;;
        overwrite)
          act "back up $shown and link the repo's version"
          ;;
      esac
    fi
  else
    replace=0
    act "link $shown"
  fi

  if ((!CHECK)); then
    if ((replace)); then backup "$dst"; fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
  fi
}

# --------------------------------------------------------------------------

if [[ $(uname -s) != Darwin ]]; then
  echo "install.sh is for macOS. On Debian/Ubuntu servers use scripts/install-remote.sh." >&2
  exit 1
fi

((CHECK)) && echo "Dry run: nothing will be changed."
if [[ $DOTFILES != "$HOME/dotfiles" ]]; then
  problem "repo is at $(pretty "$DOTFILES"), but the upall/brlist aliases expect ~/dotfiles"
fi

if ((BREW)); then
  section "Homebrew"
  brew_bin=""
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $b ]]; then brew_bin=$b; break; fi
  done

  if [[ -z $brew_bin ]]; then
    act "install Homebrew (asks for your password)"
    if ((!CHECK)); then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x $b ]]; then brew_bin=$b; break; fi
      done
    fi
  fi

  if [[ -n $brew_bin ]]; then
    eval "$("$brew_bin" shellenv)"
    ok "Homebrew is installed"

    brewfile="$DOTFILES/Brewfile"
    if brew bundle check --no-upgrade --file="$brewfile" >/dev/null 2>&1; then
      ok "everything in the Brewfile is installed"
    elif ((CHECK)); then
      act "install these from the Brewfile (missing only; nothing gets upgraded):"
      brew bundle check --no-upgrade --verbose --file="$brewfile" 2>/dev/null |
        sed -n 's/^→ /      /p'
    else
      act "install what's missing from the Brewfile (nothing gets upgraded)"
      if ! brew bundle install --no-upgrade --file="$brewfile"; then
        problem "some Brewfile items failed to install (see the output above)"
      fi
    fi

    # compinit refuses group/world-writable completion dirs (zsh-completions)
    insecure=$(zsh -fc 'fpath=("$1"/share/zsh-completions "$1"/share/zsh/site-functions $fpath)
      autoload -Uz compaudit; compaudit 2>&1' _ "$HOMEBREW_PREFIX" | grep '^/' || true)
    if [[ -z $insecure ]]; then
      ok "zsh completion directories have safe permissions"
    else
      while IFS= read -r d; do
        act "remove group/other write permission from $d"
        ((CHECK)) || chmod go-w "$d"
      done <<<"$insecure"
    fi
  elif ((CHECK)); then
    act "install everything in the Brewfile"
  else
    problem "Homebrew installation did not finish; skipped the Brewfile"
  fi
fi

section "Config links"
for entry in "${LINKS[@]}"; do
  # shellcheck disable=SC2086  # intentional word splitting: "repo-path target"
  link_one $entry
done

section "Other"
if [[ -e $HOME/.hushlogin ]]; then
  ok "~/.hushlogin (no 'Last login' line in new terminals)"
else
  act "create ~/.hushlogin (no 'Last login' line in new terminals)"
  ((CHECK)) || touch "$HOME/.hushlogin"
fi

section "Summary"
((BACKED_UP)) && echo "  Replaced files were moved to $(pretty "$BACKUP_DIR")"
((ADOPTED)) && echo "  Copied local configs into the repo. Review: git -C $(pretty "$DOTFILES") diff"
if [[ -n $PROBLEMS ]]; then
  echo "  Needs attention:"
  printf '%s' "$PROBLEMS" | sed 's/^/    - /'
  if [[ $PROBLEMS == *"differs from the repo"* ]]; then
    echo "  Re-run with --adopt to keep your versions, or --overwrite to use the repo's."
  fi
  exit 1
fi
if ((CHECK)); then
  echo "  Dry run finished. Run without --check to apply."
else
  echo "  Done. Open a new terminal tab to load the shell config."
fi
