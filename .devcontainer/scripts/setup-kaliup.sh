#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/workspaces/github-vps"
KALIUP="$REPO_DIR/kaliup.sh"
BASHRC="$HOME/.bashrc"
ALIAS_LINE="alias kaliup='cd $REPO_DIR && ./kaliup.sh'"

echo "[devcontainer] ensuring kaliup script is present and executable"
if [ -f "$KALIUP" ]; then
  ls -l "$KALIUP" || true
  chmod +x "$KALIUP" || true
else
  echo "[devcontainer] WARNING: $KALIUP not found" >&2
fi

# Add alias to .bashrc if missing (idempotent)
if ! grep -Fxq "$ALIAS_LINE" "$BASHRC" 2>/dev/null; then
  echo "$ALIAS_LINE" >> "$BASHRC"
  echo "[devcontainer] added alias to $BASHRC"
else
  echo "[devcontainer] alias already present in $BASHRC"
fi

# Source the file for the current shell (best-effort)
if [ -f "$BASHRC" ]; then
  # shellcheck disable=SC1090
  source "$BASHRC" || true
fi

echo "[devcontainer] setup-kaliup complete"
