#!/usr/bin/env bash

# Simple system upgrade script
set -e

echo "🔄 Starting system upgrades..."

# Homebrew
echo "📦 Updating Homebrew..."
brew update
brew upgrade

# UV tools
echo "🐍 Upgrading UV tools..."
uv tool upgrade --all

# Rust (check if rustup exists)
if command -v rustup >/dev/null 2>&1; then
    echo "🦀 Updating Rust toolchains..."
    rustup update
else
    echo "⚠️  rustup not found, skipping Rust updates"
fi

# Cleanup
echo "🧹 Cleaning up..."
brew cleanup
uv cache prune

echo "✅ All upgrades completed!"
