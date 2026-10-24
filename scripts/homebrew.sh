#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v brew >/dev/null 2>&1; then
  echo "✓ Homebrew already installed"
else
  echo "→ Installing Homebrew..."

  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "→ Updating Homebrew..."
brew update

echo "→ Installing packages from Brewfile..."
brew bundle --file="$ROOT_DIR/Brewfile"

echo "✓ Homebrew setup completed"