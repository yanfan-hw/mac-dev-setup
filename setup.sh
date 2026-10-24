#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo " mac-dev-setup"
echo "================================"
echo

echo "→ Homebrew"
"$ROOT_DIR/scripts/homebrew.sh"

echo "→ Git"
"$ROOT_DIR/scripts/git.sh"

echo "→ Dotfiles"
"$ROOT_DIR/scripts/dotfiles.sh"

echo "→ macOS settings"
"$ROOT_DIR/scripts/macos.sh"

echo
echo "✓ Mac development environment ready."