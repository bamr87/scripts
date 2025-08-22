#!/bin/bash
# filepath: /Users/bamr87/github/scripts/create_package.sh

# Usage: ./create_package.sh <package-name>

if [ -z "$1" ]; then
  echo "Usage: $0 <package-name>"
  exit 1
fi

PACKAGE_NAME=$1

# Create the repository directory
cd ~/github || exit
mkdir -p "$PACKAGE_NAME"
cd "$PACKAGE_NAME" || exit

# Initialize a new local repository
git init

# Pull in the template from GitHub into a temporary folder
TEMP_DIR=$(mktemp -d)
git clone --depth=1 https://github.com/microsoft/python-package-template.git "$TEMP_DIR"

# Copy template files into current directory (excluding the .git folder)
rsync -av --progress "$TEMP_DIR"/ . --exclude .git
rm -rf "$TEMP_DIR"

# Stage and commit the template files
git add .


