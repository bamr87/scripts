#!/bin/bash
# File: create_package.sh
# Description: Bootstrap a new Python package repo using microsoft/python-package-template
# Author: Amr Abdel-Motaleb <amr.abdel@gmail.com>
# Created: 2025-11-13
# Last Modified: 2025-11-13
# Version: 0.2.0
#
# Dependencies:
# - git: for initializing the new repository and cloning the template
# - rsync: for copying template contents without .git metadata
# - mktemp: for creating a disposable working directory
#
# Container Requirements:
# - Base Image: linux distro with git, rsync, and coreutils installed
# - Volumes: $HOME/github mounted if you want host-visible repositories
#
# Usage:
#   ./create_package.sh <package-name>
#     Creates ~/github/<package-name>, initializes a git repo, and
#     overlays the microsoft/python-package-template into it.
#
# Example:
#   ./create_package.sh awesome-lib
#   cd ~/github/awesome-lib
#   # customize package metadata, then add remote and push

# Fail fast on errors and unset variables
set -euo pipefail

usage() {
  echo "Usage: $0 <package-name>"
  echo "  Creates \$HOME/github/<package-name> from microsoft/python-package-template."
}

if [ $# -lt 1 ]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  -*|*/*|.|..)
    # Guard against flags or paths being taken as the name and creating e.g. ~/github/--help
    echo "Error: invalid package name '$1' (a plain directory name is expected)" >&2
    usage >&2
    exit 1
    ;;
esac

PACKAGE_NAME="$1"

# Create the repository directory under ~/github (a common workspace root)
mkdir -p "$HOME/github/$PACKAGE_NAME"
cd "$HOME/github/$PACKAGE_NAME"

# Initialize a new local repository
git init

# Pull in the template from GitHub into a temporary folder and overlay into repo
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
git clone --depth=1 https://github.com/microsoft/python-package-template.git "$TEMP_DIR"

# Copy template files into current directory (excluding the .git folder)
rsync -a "$TEMP_DIR"/ . --exclude .git
rm -rf "$TEMP_DIR"

# Stage template files so caller can commit or amend as desired
git add .

echo "✅ Package skeleton created in $HOME/github/$PACKAGE_NAME"
echo "   Next steps:"
echo "     1. cd $HOME/github/$PACKAGE_NAME"
echo "     2. Update package metadata (name, author, etc.)"
echo "     3. git commit -m 'chore: bootstrap package from microsoft/python-package-template'"
echo "     4. git remote add origin <your-remote-url> && git push -u origin main"


