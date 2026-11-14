
# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ~/.local/bin (uv tools, Claude Code) first. .zshenv adds it, but macOS
# path_helper in /etc/zprofile moves it behind /usr/bin.
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})
