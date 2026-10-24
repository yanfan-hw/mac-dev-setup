#!/usr/bin/env bash

set -euo pipefail

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

WORK_KEY="$SSH_DIR/id_ed25519_work"
PERSONAL_KEY="$SSH_DIR/id_ed25519_personal"

WORK_DIR="$HOME/workspace"
PERSONAL_DIR="$HOME/personal"

WORK_GITCONFIG="$HOME/.gitconfig-work"
PERSONAL_GITCONFIG="$HOME/.gitconfig-personal"

echo
echo "→ Setting up Git & SSH..."

# ------------------------------------------------------------
# Developer directories
# ------------------------------------------------------------

echo
echo "→ Creating developer directories..."

mkdir -p "$WORK_DIR"
mkdir -p "$PERSONAL_DIR"

echo "✓ $WORK_DIR"
echo "✓ $PERSONAL_DIR"

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

create_key() {
  local key_path="$1"
  local label="$2"

  if [[ -f "$key_path" ]]; then
    echo "✓ $label SSH key already exists"
    return
  fi

  echo "→ Creating $label SSH key..."

  ssh-keygen \
    -t ed25519 \
    -f "$key_path" \
    -C "$label"
}

create_key "$WORK_KEY" "GitHub Work"
create_key "$PERSONAL_KEY" "GitHub Personal"

# ------------------------------------------------------------
# SSH config
# ------------------------------------------------------------

if ! grep -q "^Host github-work$" "$SSH_CONFIG"; then
  cat >> "$SSH_CONFIG" <<EOF

# GitHub Work
Host github-work
    HostName github.com
    User git
    IdentityFile $WORK_KEY
    IdentitiesOnly yes
EOF

  echo "✓ Added github-work SSH config"
else
  echo "✓ github-work SSH config already exists"
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

  echo "✓ Added github-personal SSH config"
else
  echo "✓ github-personal SSH config already exists"
fi

# ------------------------------------------------------------
# Git identities
# ------------------------------------------------------------

create_git_identity() {
  local config_file="$1"
  local label="$2"

  if [[ -f "$config_file" ]]; then
    echo "✓ $label Git identity already exists"
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
# Conditional Git config
# ------------------------------------------------------------

git config --global \
  includeIf."gitdir:$WORK_DIR/".path \
  "$WORK_GITCONFIG"

git config --global \
  includeIf."gitdir:$PERSONAL_DIR/".path \
  "$PERSONAL_GITCONFIG"

echo "✓ Configured Git identities by directory"

# ------------------------------------------------------------
# macOS SSH agent
# ------------------------------------------------------------

ssh-add --apple-use-keychain "$WORK_KEY" 2>/dev/null || true
ssh-add --apple-use-keychain "$PERSONAL_KEY" 2>/dev/null || true

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "================================="
echo " Git setup completed"
echo "================================="

echo
echo "Work SSH public key:"
cat "${WORK_KEY}.pub"

echo
echo "Personal SSH public key:"
cat "${PERSONAL_KEY}.pub"

echo
echo "Add each public key to its corresponding GitHub account."

echo
echo "Clone work repositories with:"
echo "  git clone git@github-work:ORG/REPO.git"

echo
echo "Clone personal repositories with:"
echo "  git clone git@github-personal:USER/REPO.git"

echo
echo "Developer directories:"
echo "  Work:     $WORK_DIR"
echo "  Personal: $PERSONAL_DIR"