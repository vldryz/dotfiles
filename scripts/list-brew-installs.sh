#!/usr/bin/env bash

set -e

echo "--- Formulae (Installed on Request) ---"
brew list --installed-on-request

echo -e "\n--- Casks ---"
brew list --cask
