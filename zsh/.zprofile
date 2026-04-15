
# Homebrew (macOS only; remote Linux boxes use native packages)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# JetBrains Toolbox (macOS only)
if [ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]; then
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi
