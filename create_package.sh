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
#   ./create_package.sh [--dry-run] [--force] <package-name>
#     Creates ~/github/<package-name>, initializes a git repo, and
#     overlays the microsoft/python-package-template into it. A non-empty
#     ~/github/<package-name> is refused unless --force is given.
#
# Example:
#   ./create_package.sh awesome-lib
#   ./create_package.sh --dry-run awesome-lib   # print the steps, change nothing
#   cd ~/github/awesome-lib
#   # customize package metadata, then add remote and push

# Fail fast on errors and unset variables
set -euo pipefail

TEMPLATE_URL="https://github.com/microsoft/python-package-template.git"

usage() {
  echo "Usage: $0 [--dry-run] [--force] <package-name>"
  echo "  Creates \$HOME/github/<package-name> from microsoft/python-package-template."
  echo ""
  echo "Options:"
  echo "  --dry-run   Print the mkdir, git init, clone, rsync and git add steps; change nothing"
  echo "  --force     Overlay the template onto \$HOME/github/<package-name> even if it is not empty"
  echo "  -h, --help  Show this help and exit"
}

DRY_RUN=false
FORCE=false
PACKAGE_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -*|*/*|.|..)
      # Guard against flags or paths being taken as the name and creating e.g. ~/github/--help
      echo "Error: invalid package name '$1' (a plain directory name is expected)" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ -n "$PACKAGE_NAME" ]; then
        echo "Error: more than one package name given ('$PACKAGE_NAME' and '$1')" >&2
        usage >&2
        exit 1
      fi
      PACKAGE_NAME="$1"
      shift
      ;;
  esac
done

if [ -z "$PACKAGE_NAME" ]; then
  usage >&2
  exit 1
fi

PACKAGE_DIR="$HOME/github/$PACKAGE_NAME"

# Overlaying the template onto existing work would mix it into whatever is
# there and stage all of it, so a non-empty target needs an explicit --force.
if [ -d "$PACKAGE_DIR" ] && [ -n "$(ls -A "$PACKAGE_DIR")" ] && [ "$FORCE" != true ]; then
  echo "Error: $PACKAGE_DIR already exists and is not empty." >&2
  echo "  Nothing was changed. Pass --force to overlay the template onto it anyway." >&2
  exit 1
fi

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Nothing will be created. The run would:"
  if [ -d "$PACKAGE_DIR" ] && [ -n "$(ls -A "$PACKAGE_DIR")" ]; then
    echo "  (--force: $PACKAGE_DIR is not empty; the template would be overlaid onto it)"
  fi
  echo "  mkdir -p $(printf '%q' "$PACKAGE_DIR")"
  echo "  cd $(printf '%q' "$PACKAGE_DIR")"
  echo "  git init"
  echo "  git clone --depth=1 $TEMPLATE_URL <temp-dir>"
  echo "  rsync -a <temp-dir>/ . --exclude .git"
  echo "  git add ."
  exit 0
fi

# Create the repository directory under ~/github (a common workspace root)
mkdir -p "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Initialize a new local repository
git init

# Pull in the template from GitHub into a temporary folder and overlay into repo
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
git clone --depth=1 "$TEMPLATE_URL" "$TEMP_DIR"

# Copy template files into current directory (excluding the .git folder)
rsync -a "$TEMP_DIR"/ . --exclude .git
rm -rf "$TEMP_DIR"

# Stage template files so caller can commit or amend as desired
git add .

echo "✅ Package skeleton created in $PACKAGE_DIR"
echo "   Next steps:"
echo "     1. cd $PACKAGE_DIR"
echo "     2. Update package metadata (name, author, etc.)"
echo "     3. git commit -m 'chore: bootstrap package from microsoft/python-package-template'"
echo "     4. git remote add origin <your-remote-url> && git push -u origin main"


