#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

WORK_GITHUB_USER="cam8386"
PERSONAL_GITHUB_USER="yanfan-hw"

WORK_DIR="$HOME/workspace"
PERSONAL_DIR="$HOME/personal"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

WORK_KEY="$SSH_DIR/id_ed25519_work"
PERSONAL_KEY="$SSH_DIR/id_ed25519_personal"

WORK_GITCONFIG="$HOME/.gitconfig-work"
PERSONAL_GITCONFIG="$HOME/.gitconfig-personal"

echo
echo "================================="
echo "       Git & GitHub Setup"
echo "================================="
echo

# ------------------------------------------------------------
# Developer directories
# ------------------------------------------------------------

echo "→ Creating developer directories..."

mkdir -p "$WORK_DIR"
mkdir -p "$PERSONAL_DIR"

echo "✓ Work:     $WORK_DIR"
echo "✓ Personal: $PERSONAL_DIR"

# ------------------------------------------------------------
# SSH directory
# ------------------------------------------------------------

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# ------------------------------------------------------------
# SSH keys
# ------------------------------------------------------------

create_ssh_key() {
  local key_path="$1"
  local label="$2"

  if [[ -f "$key_path" ]]; then
    echo "✓ $label SSH key already exists"
    return
  fi

  echo
  echo "→ Creating $label SSH key..."

  ssh-keygen \
    -t ed25519 \
    -f "$key_path" \
    -C "$label"
}

create_ssh_key "$WORK_KEY" "GitHub Work"
create_ssh_key "$PERSONAL_KEY" "GitHub Personal"

# ------------------------------------------------------------
# SSH config
# ------------------------------------------------------------

echo
echo "→ Configuring SSH..."

if ! grep -q "^Host github-work$" "$SSH_CONFIG"; then
  cat >> "$SSH_CONFIG" <<EOF

# GitHub Work
Host github-work
    HostName github.com
    User git
    IdentityFile $WORK_KEY
    IdentitiesOnly yes
EOF

  echo "✓ Added github-work"
else
  echo "✓ github-work already configured"
fi

if ! grep -q "^Host github-personal$" "$SSH_CONFIG"; then
  cat >> "$SSH_CONFIG" <<EOF

# GitHub Personal
Host github-personal
    HostName github.com
    User git
    IdentityFile $PERSONAL_KEY
    IdentitiesOnly yes
EOF

  echo "✓ Added github-personal"
else
  echo "✓ github-personal already configured"
fi

# ------------------------------------------------------------
# SSH agent / macOS Keychain
# ------------------------------------------------------------

echo
echo "→ Adding SSH keys to ssh-agent..."

ssh-add --apple-use-keychain "$WORK_KEY" 2>/dev/null || true
ssh-add --apple-use-keychain "$PERSONAL_KEY" 2>/dev/null || true

# ------------------------------------------------------------
# GitHub CLI authentication
# ------------------------------------------------------------

setup_github_account() {
  local username="$1"
  local public_key="$2"
  local label="$3"

  echo
  echo "→ Setting up GitHub account: $username"

  # Check whether account is already authenticated.
  if ! gh auth status --hostname github.com 2>&1 | grep -q "$username"; then
    echo "→ Login to GitHub as: $username"
    echo "  Make sure you select the correct GitHub account in the browser."

    gh auth login \
      --hostname github.com \
      --git-protocol ssh \
      --skip-ssh-key \
      --web
  fi

  # Switch gh to this account.
  gh auth switch \
    --hostname github.com \
    --user "$username"

  echo "✓ Active GitHub account: $username"

  # Check whether this SSH key is already registered.
  local fingerprint
  fingerprint="$(ssh-keygen -lf "$public_key" | awk '{print $2}')"

  if gh ssh-key list | grep -q "$fingerprint"; then
    echo "✓ $label SSH key already exists on GitHub"
  else
    echo "→ Uploading $label SSH key..."

    gh ssh-key add "$public_key" \
      --title "$(scutil --get ComputerName) - $label"

    echo "✓ $label SSH key uploaded"
  fi
}

setup_github_account \
  "$WORK_GITHUB_USER" \
  "${WORK_KEY}.pub" \
  "Work"

setup_github_account \
  "$PERSONAL_GITHUB_USER" \
  "${PERSONAL_KEY}.pub" \
  "Personal"

# ------------------------------------------------------------
# Git identities
# ------------------------------------------------------------

create_git_identity() {
  local config_file="$1"
  local label="$2"

  if [[ -f "$config_file" ]]; then
    echo "✓ $label Git identity already configured"
    return
  fi

  echo
  echo "→ Configure $label Git identity"

  read -r -p "Name: " git_name
  read -r -p "Email: " git_email

  git config --file "$config_file" user.name "$git_name"
  git config --file "$config_file" user.email "$git_email"

  echo "✓ Created $config_file"
}

create_git_identity "$WORK_GITCONFIG" "Work"
create_git_identity "$PERSONAL_GITCONFIG" "Personal"

# ------------------------------------------------------------
# Conditional Git configuration
# ------------------------------------------------------------

echo
echo "→ Configuring Git identities by directory..."

git config --global \
  includeIf."gitdir:$WORK_DIR/".path \
  "$WORK_GITCONFIG"

git config --global \
  includeIf."gitdir:$PERSONAL_DIR/".path \
  "$PERSONAL_GITCONFIG"

echo "✓ Work projects use work Git identity"
echo "✓ Personal projects use personal Git identity"

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "================================="
echo "       Git setup completed"
echo "================================="
echo

echo "Directories:"
echo "  Work:     $WORK_DIR"
echo "  Personal: $PERSONAL_DIR"

echo
echo "SSH:"
echo "  Work:     git@github-work"
echo "  Personal: git@github-personal"

echo
echo "Clone examples:"
echo "  Work:"
echo "    git clone git@github-work:ORG/REPO.git"

echo
echo "  Personal:"
echo "    git clone git@github-personal:USER/REPO.git"

echo
echo "GitHub CLI:"
gh auth status

echo
echo "✓ Done"