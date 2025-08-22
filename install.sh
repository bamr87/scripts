#!/bin/bash

# Installation script for the Project Initialization Wizard
# This script sets up the wizard and adds it to your PATH

set -e

echo "🚀 Installing Project Initialization Wizard..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIZARD_DIR="${HOME}/.project-wizard"

# Create wizard directory
echo "📁 Creating wizard directory..."
mkdir -p "$WIZARD_DIR"
mkdir -p "$WIZARD_DIR/templates"

# Make scripts executable
echo "🔧 Setting permissions..."
chmod +x "$SCRIPT_DIR/project-init.sh"

# Create symlink in user's local bin
if [ -d "$HOME/.local/bin" ]; then
    echo "🔗 Creating symlink in ~/.local/bin..."
    ln -sf "$SCRIPT_DIR/project-init.sh" "$HOME/.local/bin/project-wizard"
    echo "✅ Symlink created at ~/.local/bin/project-wizard"
fi

# Detect shell and update configuration
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Check if PATH update is needed
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

# Copy example configuration
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
