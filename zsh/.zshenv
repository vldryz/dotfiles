# XDG
export XDG_CONFIG_HOME=$HOME/.config
# export XDG_DATA_HOME=$XDG_CONFIG_HOME/local/share
# export XDG_CACHE_HOME=$XDG_CONFIG_HOME/cache

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# History size/file live in .zshrc: macOS /etc/zshrc overrides them if set here
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
# completion colors
export LS_COLORS='di=01;34:ln=01;36:so=01;35:pi=40;33:ex=01;32:bd=40;33;01:cd=40;33;01:fi=00;37'
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# homebrew
# `brew upgrade` leaves apps that update themselves (Zen, Helium, T3 Code,
# Claude, ...) alone, so it never quits them mid-session; they update when I
# choose. The exceptions below are upgraded by `brew upgrade` / `upall` anyway.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
export HOMEBREW_UPGRADE_GREEDY_CASKS="google-chrome"

# Per-account tools. Set here, not in .zshrc, so commands run over ssh and by
# agents (Claude Code, T3 Code) find them too.
# Rust (rustup installs here; install it with --no-modify-path)
[[ -d $HOME/.cargo/bin ]] && export PATH="$HOME/.cargo/bin:$PATH"
# mise shims: Node etc. for non-interactive shells; .zshrc activates mise fully
[[ -d $HOME/.local/share/mise/shims ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"
# uv, uv tools, Claude Code
export PATH="$HOME/.local/bin:$PATH"
