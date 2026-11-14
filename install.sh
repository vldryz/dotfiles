#!/usr/bin/env bash
# Set up a Mac from this repo: Homebrew, the Brewfile, and config symlinks.
#
# Safe to re-run. Links that are already right are left alone, and an existing
# config that differs from the repo is never replaced unless you say how
# (--adopt or --overwrite). Anything replaced is moved to ~/.dotfiles-backup/.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--check] [--no-brew] [--adopt | --overwrite] [--karabiner-default]

  --check      Show what would change; change nothing.
  --no-brew    Skip Homebrew and the Brewfile; only link configs.
  --adopt      For existing configs that differ from the repo: keep them,
               copy them into the repo (review with `git diff`), then link.
  --overwrite  For existing configs that differ from the repo: back them up
               to ~/.dotfiles-backup/ and link the repo's version.
  --karabiner-default
               For an account someone else uses: Karabiner starts on
               "Default profile" (no remaps), with a menu bar icon to switch
               to "Vlad". The config is copied instead of linked, so switching
               profiles there never changes the repo.

Without --adopt/--overwrite, differing configs are left alone and listed.

On a Mac with several accounts, Homebrew belongs to the one that installed it.
From any other account the Brewfile is only checked, and anything missing is
listed for that account to install.
EOF
}

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Files named after this Mac (Brewfile.<host>, zsh/hosts/<host>.zsh) hold
# what's specific to it.
HOST_NAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
BREWFILE="$DOTFILES/Brewfile.$HOST_NAME"
[[ -f $BREWFILE ]] || BREWFILE="$DOTFILES/Brewfile"

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
# zsh settings for this Mac only, if the repo has any (sourced by .zshrc)
if [[ -f $DOTFILES/zsh/hosts/$HOST_NAME.zsh ]]; then
  LINKS+=("zsh/hosts/$HOST_NAME.zsh $HOME/.config/zsh/host.zsh")
fi

CHECK=0
BREW=1
ON_DIFF=skip
KARABINER_DEFAULT=0
for arg in "$@"; do
  case $arg in
    --check) CHECK=1 ;;
    --no-brew) BREW=0 ;;
    --adopt) ON_DIFF=adopt ;;
    --overwrite) ON_DIFF=overwrite ;;
    --karabiner-default) KARABINER_DEFAULT=1 ;;
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
  echo "install.sh is for macOS." >&2
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
    brew_owner=$(stat -f %Su "$HOMEBREW_PREFIX")
    ok "Homebrew is installed (owned by $brew_owner)"

    brewfile=$BREWFILE
    brewfile_name=${brewfile##*/}
    if brew bundle check --no-upgrade --file="$brewfile" >/dev/null 2>&1; then
      ok "everything in $brewfile_name is installed"
    elif [[ ! -O $HOMEBREW_PREFIX ]]; then
      # `brew bundle check` is unreliable from an account that doesn't own
      # Homebrew, so look in the Homebrew folder directly
      missing=$(sed -nE 's/^(brew|cask) "([^"]+)".*/\1 \2/p' "$brewfile" |
        while read -r kind name; do
          name=${name##*/}
          if [[ $kind == brew ]]; then dir=$HOMEBREW_PREFIX/opt/$name; else dir=$HOMEBREW_PREFIX/Caskroom/$name; fi
          [[ -e $dir ]] || echo "$kind $name"
        done)
      if [[ -z $missing ]]; then
        ok "everything in $brewfile_name is installed"
      else
        problem "some of $brewfile_name is missing; run install.sh as $brew_owner to install it:"
        sed 's/^/      /' <<<"$missing"
      fi
    elif ((CHECK)); then
      act "install these from $brewfile_name (missing only; nothing gets upgraded):"
      # brew lists missing items on stderr and exits 1 when anything is missing
      { brew bundle check --no-upgrade --verbose --file="$brewfile" 2>&1 || true; } |
        sed -n 's/^→ /      /p'
    else
      act "install what's missing from $brewfile_name (nothing gets upgraded)"
      if ! brew bundle install --no-upgrade --file="$brewfile"; then
        problem "some $brewfile_name items failed to install (see the output above)"
      fi
    fi

    # compinit refuses group/world-writable completion dirs (zsh-completions)
    insecure=$(zsh -fc 'fpath=("$1"/share/zsh-completions "$1"/share/zsh/site-functions $fpath)
      autoload -Uz compaudit; compaudit 2>&1' _ "$HOMEBREW_PREFIX" | grep '^/' || true)
    if [[ -z $insecure ]]; then
      ok "zsh completion directories have safe permissions"
    elif [[ ! -O $HOMEBREW_PREFIX ]]; then
      # .zshrc trusts Homebrew's own dirs on other accounts, as long as they
      # are not writable by others; only Homebrew's owner can fix those
      writable=$(grep "^$HOMEBREW_PREFIX/" <<<"$insecure" | while IFS= read -r d; do
        [[ -n $(find "$d" -maxdepth 0 -perm +022) ]] && echo "$d"; done || true)
      if [[ -z $writable ]]; then
        ok "zsh completion directories are fine (Homebrew's belong to $brew_owner)"
      else
        problem "zsh completion directories writable by others; run install.sh as $brew_owner to fix: $(tr '\n' ' ' <<<"$writable")"
      fi
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

# Karabiner config for an account someone else uses: the repo's profiles, with
# "Default profile" selected and the menu bar icon on, copied into place.
karabiner_default() {
  local dst=$HOME/.config/karabiner shown tmp i name found=0
  shown=$(pretty "$dst/karabiner.json")
  tmp=$(mktemp)
  cp "$DOTFILES/karabiner/karabiner.json" "$tmp"
  for ((i = 0; ; i++)); do
    name=$(plutil -extract "profiles.$i.name" raw -o - "$tmp" 2>/dev/null) || break
    if [[ $name == "Default profile" ]]; then
      plutil -replace "profiles.$i.selected" -bool true "$tmp"
      found=1
    else
      plutil -replace "profiles.$i.selected" -bool false "$tmp"
    fi
  done
  plutil -replace global.show_in_menu_bar -bool true "$tmp"
  if ((!found)); then
    problem "karabiner/karabiner.json has no \"Default profile\"; $shown not set up"
    rm -f "$tmp"
    return
  fi

  local replace=0
  if [[ -L $dst ]]; then
    act "replace the link $(pretty "$dst") with a folder holding a copy of the config"
    replace=1
  elif [[ -f $dst/karabiner.json ]]; then
    if diff -q <(plutil -convert xml1 -o - "$dst/karabiner.json") \
      <(plutil -convert xml1 -o - "$tmp") >/dev/null 2>&1; then
      ok "$shown (repo profiles, \"Default profile\" selected)"
      rm -f "$tmp"
      return
    fi
    # Profiles switched from the menu bar land here too, so only replace when asked
    if [[ $ON_DIFF != overwrite ]]; then
      problem "$shown differs from the repo's profiles; left alone (re-run with --overwrite to reset it)"
      rm -f "$tmp"
      return
    fi
    act "back up $shown and copy in the repo's profiles"
    replace=1
  else
    act "copy the repo's profiles to $shown (\"Default profile\" selected)"
  fi

  if ((!CHECK)); then
    if ((replace)); then
      if [[ -L $dst ]]; then backup "$dst"; else backup "$dst/karabiner.json"; fi
    fi
    mkdir -p "$dst"
    cp "$tmp" "$dst/karabiner.json"
  fi
  rm -f "$tmp"
}

section "Config links"
for entry in "${LINKS[@]}"; do
  # shellcheck disable=SC2086  # intentional word splitting: "repo-path target"
  set -- $entry
  if ((KARABINER_DEFAULT)) && [[ $1 == karabiner ]]; then
    karabiner_default
  else
    link_one "$@"
  fi
done

section "Other"
# With ZDOTDIR set in ~/.zshenv, zsh no longer reads these. Installers (mise,
# rustup, uv, ...) often write setup lines into them, which would then be lost.
for f in .zshrc .zprofile .zlogin; do
  if [[ -f $HOME/$f && ! -L $HOME/$f ]]; then
    problem "~/$f is ignored (zsh reads ~/.config/zsh/ instead); move anything you need from it into the repo, then delete it"
  fi
done
if [[ -e $HOME/.hushlogin ]]; then
  ok "~/.hushlogin (no 'Last login' line in new terminals)"
else
  act "create ~/.hushlogin (no 'Last login' line in new terminals)"
  ((CHECK)) || touch "$HOME/.hushlogin"
fi
# Ghostty's terminal type, xterm-ghostty, for this account. Ghostty points its
# own windows at the copy inside the app, and its ssh-terminfo copies it to the
# account you ssh into, but `su - <account>` keeps TERM=xterm-ghostty without
# the definition, and zsh can't redraw the command line (keystrokes pile up).
ghostty_terminfo=/Applications/Ghostty.app/Contents/Resources/terminfo
if [[ -d $ghostty_terminfo ]]; then
  if env -u TERMINFO -u TERMINFO_DIRS infocmp xterm-ghostty >/dev/null 2>&1; then
    ok "xterm-ghostty terminal type (for su - and ssh into this account)"
  else
    act "add the xterm-ghostty terminal type to ~/.terminfo (for su - and ssh into this account)"
    # -o: never write into the app, which Ghostty's TERMINFO points at
    if ((!CHECK)) && ! { infocmp -x -A "$ghostty_terminfo" xterm-ghostty |
      tic -x -o "$HOME/.terminfo" -; } 2>/dev/null; then
      problem "couldn't add xterm-ghostty to ~/.terminfo"
    fi
  fi
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
