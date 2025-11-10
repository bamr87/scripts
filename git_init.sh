#!/bin/bash

# Set GitHub user from environment variable or fallback to system user
GITHUB_USER="${GITHUB_USER:-$USER}"

# Validate GitHub user is set
if [ -z "$GITHUB_USER" ]; then
    echo "Error: GITHUB_USER environment variable is not set and USER is not available."
    echo "Please set GITHUB_USER environment variable: export GITHUB_USER=your_github_username"
    exit 1
fi

echo "Using GitHub user: $GITHUB_USER"

# Prompt for folder name
read -p "Enter the folder name for the GitHub repo: " USER_INPUT

# Validate input
if [ -z "$USER_INPUT" ]; then
    echo "Error: Repository name cannot be empty."
    exit 1
fi

# Define the full path
REPO_PATH=~/github/"$USER_INPUT"

# Create the directory
mkdir -p "$REPO_PATH"
cd "$REPO_PATH" || { echo "Failed to access directory."; exit 1; }

# Initialize Git and create README
git init
echo "# $USER_INPUT" > README.md
git add README.md
git commit -m "Initial commit"

# Construct GitHub remote URL using environment variable
REMOTE_URL="git@github.com:$GITHUB_USER/$USER_INPUT.git"
echo "Using remote URL: $REMOTE_URL"

# Prompt for confirmation or allow override
read -p "Use this URL? (y/n) or enter custom URL: " CONFIRM_URL

if [[ "$CONFIRM_URL" =~ ^[Yy]$ ]] || [ -z "$CONFIRM_URL" ]; then
    # Use the constructed URL
    echo "Using constructed URL: $REMOTE_URL"
elif [[ "$CONFIRM_URL" =~ ^[Nn]$ ]]; then
    # Prompt for custom URL
    read -p "Enter the GitHub repository URL: " REMOTE_URL
else
    # Treat input as custom URL
    REMOTE_URL="$CONFIRM_URL"
fi

# Add remote and push
git remote add origin "$REMOTE_URL"
git branch -M main
git push -u origin main

echo "Repository initialized and pushed successfully!"
echo "Repository location: $REPO_PATH"
echo "Remote URL: $REMOTE_URL"