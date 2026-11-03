# +-----------------+
# | PLATFORM DETECT |
# +-----------------+
if [[ "$OSTYPE" == darwin* ]]; then
  IS_MACOS=true
  # Homebrew (early because it affects PATH and plugin paths).
  # Login shells already got this from .zprofile; only non-login shells need it.
  if [[ -z $HOMEBREW_PREFIX && -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ZSH_PLUGIN_DIR="$HOMEBREW_PREFIX/share"
elif [[ -f /etc/debian_version ]]; then
  IS_DEBIAN=true
  ZSH_PLUGIN_DIR="/usr/share"
fi

# +-----------------+
# | PATH & FPATH    |
# +-----------------+
# Keep PATH/FPATH free of duplicates (path_helper + brew shellenv overlap)
typeset -U path fpath

# Add all custom fpaths
[[ -d $HOME/.docker/completions ]] && fpath=($HOME/.docker/completions $fpath)

# zsh-completions from brew (macOS only)
if [[ -n $IS_MACOS && -d $HOMEBREW_PREFIX/share/zsh-completions ]]; then
  FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH
fi

# +-----------------+
# | COLORS          |
# +-----------------+
# Enable zsh colors (needed for prompt)
autoload -U colors && colors

# +-----------------+
# | INIT COMPLETION |
# +-----------------+
# Initialize completion system (after setting up zstyles)
autoload -Uz compinit
compinit

# +-----------------+
# | SHELL OPTIONS   |
# +-----------------+
# History file and size. Set here, not in .zshenv: macOS /etc/zshrc runs in
# between and resets them to 2000/1000. Not exported, so a child bash doesn't
# adopt HISTFILE and overwrite the zsh history on exit.
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000                   # Maximum events for internal history
SAVEHIST=10000                   # Maximum events in history file

# History options
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.

# Navigation options
setopt EXTENDED_GLOB        # Use extended globbing syntax

# Input options
setopt INTERACTIVE_COMMENTS # `# ...` is a comment at the prompt too (pasted snippets work)
# CORRECT is intentionally off: on pasted text it offered e.g. `edit` -> `exit`.
# Typo tolerance stays in completion via the _approximate completer below.

# Completion options
setopt MENU_COMPLETE        # Automatically highlight first element of completion menu
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt COMPLETE_IN_WORD     # Complete from both ends of a word

# +-----------------+
# | COMPLETION      |
# +-----------------+
# Define completers
zstyle ':completion:*' completer _extensions _complete _approximate

# Use cache for commands using cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache"

# Complete the alias when _expand_alias is used as a function
zstyle ':completion:*' complete true

# Allow you to select in a menu
zstyle ':completion:*' menu select

# Autocomplete options for cd instead of directory stack
zstyle ':completion:*' complete-options true

zstyle ':completion:*' file-sort modification

# Formatting and colors
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
zstyle ':completion:*:*:*:*:messages' format ' %F{magenta} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Tag order
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# Matching control
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' keep-prefix true

# SSH/SCP/SFTP completion
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# +-----------------+
# | KEY BINDINGS    |
# +-----------------+
# Safe alias expansion on space
# bracketed-paste-magic handles paste correctly on macOS (newer zsh),
# but is painfully slow on zsh 5.8.x (Ubuntu 22.04) — skip it there
if [[ -n $IS_MACOS ]]; then
  autoload -Uz bracketed-paste-magic
  zle -N bracketed-paste bracketed-paste-magic
fi

function expand-alias() {
	zle _expand_alias
	zle self-insert
}
zle -N expand-alias
bindkey -M main ' ' expand-alias

# Option+Enter: insert newline without submitting (enables multi-line editing)
function insert-newline() {
    LBUFFER+=$'\n'
}
zle -N insert-newline
bindkey '^[^M' insert-newline

# Option+Arrow: word jump (requires macos-option-as-alt = true in Ghostty)
bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Option+Backspace: delete word (requires macos-option-as-alt = true in Ghostty)
bindkey "^[^?" backward-kill-word

# zsh-autosuggestions: accept suggestion
bindkey '^[^I' autosuggest-accept

# +-----------------+
# | FUNCTIONS       |
# +-----------------+
# Custom functions can go here if needed
# Note: Prompt functions removed since Starship handles the prompt

# +-----------------+
# | ALIASES         |
# +-----------------+
source $ZDOTDIR/aliases.zsh

# +-----------------+
# | EXTERNAL TOOLS  |
# +-----------------+
# Initialize zoxide (aliases.zsh maps cd to z only when zoxide exists)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Initialize fnm (Fast Node Manager)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi

# Kubectl completion, generated once per kubectl binary instead of every shell
if command -v kubectl &> /dev/null; then
  _kubectl_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl-completion.zsh"
  if [[ ! -s $_kubectl_comp || $commands[kubectl] -nt $_kubectl_comp ]]; then
    mkdir -p "${_kubectl_comp:h}" && kubectl completion zsh >| "$_kubectl_comp"
  fi
  source "$_kubectl_comp"
  unset _kubectl_comp
fi

# +-----------------+
# | PLUGINS         |
# +-----------------+
# Must be at the end of the file
[ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
