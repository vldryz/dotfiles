# +-----------------+
# | PATH & FPATH    |
# +-----------------+
# Add all custom fpaths
fpath=($HOME/.docker/completions $fpath)

# zsh-completions from brew
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi

# Homebrew (early because it might affect PATH)
eval "$(brew shellenv)"

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
setopt CORRECT              # Spelling correction
setopt EXTENDED_GLOB        # Use extended globbing syntax

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
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

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
zstyle ':completion:*:*:*:*:messages' format ' %F{purple} -- %d --%f'
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
# Expand aliases with space
function expand-alias() {
	zle _expand_alias
	zle self-insert
}
zle -N expand-alias
bindkey -M main ' ' expand-alias

# History search
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# zsh-autosuggestions
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
# Initialize zoxide
eval "$(zoxide init zsh)"

# Initialize fnm (Fast Node Manager)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi

# Kubectl completion
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi

# +-----------------+
# | PLUGINS         |
# +-----------------+
# Must be at the end of the file
[ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(starship init zsh)"
