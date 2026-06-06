#!/usr/bin/env sh
# install.sh — fetch the canonical CLAUDE.md into a target path.
#
# Usage:
#   ./install.sh [target]
#
# target defaults to ./CLAUDE.md. If the target already exists it is
# backed up to <target>.bak before being overwritten.
#
# POSIX sh only — no bashisms.

set -e

# Canonical source of the file we install.
SRC_URL="https://raw.githubusercontent.com/arjunlohan/claude.md/main/CLAUDE.md"

# Target path: first CLI argument, or ./CLAUDE.md by default.
TARGET="${1:-./CLAUDE.md}"

# If something is already at the target, preserve it as <target>.bak.
if [ -e "$TARGET" ]; then
  cp "$TARGET" "$TARGET.bak"
  echo "Backed up existing file to $TARGET.bak"
fi

# Download the file. Prefer curl, fall back to wget, error if neither exists.
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$SRC_URL" -o "$TARGET"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TARGET" "$SRC_URL"
else
  echo "Error: neither curl nor wget is installed." >&2
  exit 1
fi

# Report success with both the source and the destination.
echo "Installed CLAUDE.md from $SRC_URL to $TARGET"
