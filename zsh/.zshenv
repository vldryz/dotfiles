# XDG
export XDG_CONFIG_HOME=$HOME/.config
# export XDG_DATA_HOME=$XDG_CONFIG_HOME/local/share
# export XDG_CACHE_HOME=$XDG_CONFIG_HOME/cache

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zsh_history" # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
# completion colors
export LS_COLORS='di=01;34:ln=01;36:so=01;35:pi=40;33:ex=01;32:bd=40;33;01:cd=40;33;01:fi=00;37'
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# uv
export PATH="$HOME/.local/bin:$PATH"

# rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# bun
export PATH="$HOME/.bun/bin:$PATH"
