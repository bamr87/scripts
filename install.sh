#!/bin/bash
# File: install.sh
# Description: Installer for the Project Initialization Wizard, wiring project-init.sh into a per-user CLI with PATH updates and example config
# Author: Amr Abdel-Motaleb <amr.abdel@gmail.com>
# Created: 2025-11-13
# Last Modified: 2025-11-13
# Version: 1.1.0
#
# Dependencies:
# - bash 4+
# - ln, mkdir, chmod, cp
# - A POSIX-compliant shell startup file (~/.zshrc or ~/.bashrc)
#
# Container Requirements:
# - Base Image: bash-compatible Linux image (e.g. debian:stable, ubuntu:22.04)
# - Volumes: $HOME/.local/bin (optional bind for global CLI); $HOME/.project-wizard for user config
# - Environment: HOME must be set for the target user
#
# Usage:
#   ./install.sh
#     Installs the Project Initialization Wizard under ~/.project-wizard,
#     ensures project-init.sh is executable, and exposes a project-wizard
#     command on your PATH (via ~/.local/bin).
#
#   ENV NOTES:
#     - For zsh users on macOS, PATH is appended to ~/.zshrc
#     - For bash users, PATH is appended to ~/.bashrc
#
# Design Notes:
#   - Follows "Design for Failure" by exiting on first error with clear logging
#   - Safe to re-run: directory creation, chmod, and symlink operations are idempotent

set -e

echo "🚀 Installing Project Initialization Wizard..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD_DIR="${HOME}/.project-wizard"

# Create wizard directory (idempotent)
echo "📁 Creating wizard directory..."
mkdir -p "$WIZARD_DIR"
mkdir -p "$WIZARD_DIR/templates"

# Ensure core wizard script is executable
echo "🔧 Setting permissions..."
chmod +x "$SCRIPT_DIR/project-init.sh"

# Create or refresh symlink in user's local bin for CLI access
if [ -d "$HOME/.local/bin" ]; then
    echo "🔗 Creating symlink in ~/.local/bin..."
    ln -sf "$SCRIPT_DIR/project-init.sh" "$HOME/.local/bin/project-wizard"
    echo "✅ Symlink created at ~/.local/bin/project-wizard"
fi

# Detect shell and update configuration so project-wizard is available on new shells
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Check if PATH update is needed for this shell RC file
    if ! grep -q "# Project Wizard PATH" "$SHELL_CONFIG" 2>/dev/null; then
        echo "📝 Updating shell configuration..."
        cat >> "$SHELL_CONFIG" <<'EOF'

# Project Wizard PATH
export PATH="$PATH:$HOME/.local/bin"
EOF
        echo "✅ Updated $SHELL_CONFIG"
        echo "   Run 'source $SHELL_CONFIG' to apply changes"
    else
        echo "✅ Shell configuration already updated"
    fi
fi

# Copy example configuration for users to customize defaults
if [ -f "$SCRIPT_DIR/env.example" ]; then
    echo "📋 Installing example configuration..."
    cp "$SCRIPT_DIR/env.example" "$WIZARD_DIR/env.example"
    echo "✅ Example configuration installed to $WIZARD_DIR/env.example"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "🎯 Quick Start:"
echo "   1. Run 'source $SHELL_CONFIG' to update your PATH (if needed)"
echo "   2. Run 'project-wizard' from anywhere to start the wizard"
echo "   3. Or run '${SCRIPT_DIR}/project-init.sh' directly"
echo ""
echo "📖 For more information:"
echo "   - Run 'project-wizard --help' to see all options"
echo "   - Check ${SCRIPT_DIR}/README.md for documentation"
echo "   - Copy $WIZARD_DIR/env.example to .env for custom defaults"
echo ""
echo "Happy coding! 🚀"
