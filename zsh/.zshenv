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

# locale
# UTF-8 when nothing set a locale. Terminal apps set LANG, and macOS sets it
# for login shells only (/etc/zprofile). Shells a background service starts
# (T3 Code's terminal on backbook) get none, and zsh garbles non-ASCII input.
# LANG ranks below LC_*, so this never overrides a locale that was asked for.
export LANG=${LANG:-en_US.UTF-8}

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

# ssh-agent for shells that have none (ssh logins, su -): each account keeps
# its own in ~/.ssh, so a key's passphrase is asked once per boot (with
# AddKeysToAgent yes in ~/.ssh/config). .zshrc starts it. Here so agents and
# scripts find it too. The Mac's own agent (terminals on the Mac) is left alone.
if [[ -z $SSH_AUTH_SOCK && -S $HOME/.ssh/agent.sock ]]; then
  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
fi
