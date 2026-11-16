#!/bin/bash
################################################################################
# File: rename-directory.sh
# Description: Safely rename a directory with optional backup and git support
# Author: IT-Journey Team <team@it-journey.org>
# Created: 2025-11-02
# Last Modified: 2025-11-02
# Version: 1.0.0
#
# This script provides a safe and reliable way to rename directories, with
# special handling for git repositories, running Docker containers, and
# automatic backups.
#
# Usage:
#   bash rename-directory.sh [--dry-run] [-y|--yes] [--backup|--no-backup] <source_path> <target_path>
#   bash rename-directory.sh /path/to/old-name /path/to/new-name
#
# Example:
#   bash rename-directory.sh ~/github/posthog ~/github/bashog
#   bash rename-directory.sh --dry-run ~/github/posthog ~/github/bashog   # preview only
#   bash rename-directory.sh --yes ~/github/posthog ~/github/bashog       # unattended, with backup
#
# Features:
#   - Pre-flight checks for source/target paths
#   - Automatic detection and stopping of related Docker containers
#   - Git repository integrity checks
#   - Optional backup creation before rename
#   - Comprehensive error handling
#   - Detailed logging and status messages
################################################################################

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

################################################################################
# Color codes for output
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# Logging functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_header() {
    echo ""
    echo "=================================="
    echo -e "${MAGENTA}$1${NC}"
    echo "=================================="
    echo ""
}

################################################################################
# Usage and help
################################################################################

show_usage() {
    cat << EOF
Usage: $(basename "$0") [options] <source_path> <target_path>

Safely rename a directory with optional backup and git repository support.

Arguments:
  source_path    The current path of the directory to rename
  target_path    The new path for the directory

Options:
  --dry-run      Run the read-only pre-flight checks (paths, permissions,
                 docker ps, git status) and print what would happen; never
                 prompts, stops containers, copies or moves anything
  -y, --yes      Answer yes to the stop-containers and uncommitted-changes
                 prompts and take a backup (unless --no-backup), so the
                 rename runs unattended
  --backup       Create the backup without asking
  --no-backup    Skip the backup without asking
  -h, --help     Show this help message

Without --yes or --backup/--no-backup, each prompt is asked on stdin; with no
stdin to answer from (CI, cron) the run stops before changing anything.

Examples:
  # Rename a project directory
  $(basename "$0") ~/github/old-project ~/github/new-project

  # Rename with full paths
  $(basename "$0") /Users/username/projects/app-v1 /Users/username/projects/app-v2

  # Preview the rename: checks only, nothing changes
  $(basename "$0") --dry-run ~/github/old-project ~/github/new-project

  # Unattended (scripts, cron): stop related containers, back up, rename
  $(basename "$0") --yes ~/github/old-project ~/github/new-project

  # Unattended without a backup
  $(basename "$0") --yes --no-backup ~/github/old-project ~/github/new-project

Features:
  - Automatically detects and stops related Docker containers
  - Verifies git repository integrity (if applicable)
  - Offers optional backup before rename
  - Comprehensive pre-flight checks
  - Detailed logging and error handling

EOF
}

################################################################################
# Argument parsing
################################################################################

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

DRY_RUN=false
ASSUME_YES=false
BACKUP_CHOICE=""   # yes / no from --backup / --no-backup; empty = ask (or back up under --yes)
POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            ASSUME_YES=true
            shift
            ;;
        --backup)
            BACKUP_CHOICE=yes
            shift
            ;;
        --no-backup)
            BACKUP_CHOICE=no
            shift
            ;;
        --)
            shift
            while [ $# -gt 0 ]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            log_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL[@]} -ne 2 ]; then
    log_error "Invalid number of arguments"
    echo ""
    show_usage
    exit 1
fi

SOURCE_DIR="${POSITIONAL[0]}"
TARGET_DIR="${POSITIONAL[1]}"

# --yes means unattended, and unattended is never less safe than answering the
# prompts by hand: it takes the backup unless --no-backup says otherwise.
if [ -z "$BACKUP_CHOICE" ] && [ "$ASSUME_YES" = true ]; then
    BACKUP_CHOICE=yes
fi

# Ask a yes/no question on stdin; succeed only on "yes". With nothing on stdin
# to answer (CI, cron), stop here, before anything has changed, instead of
# letting set -e end the run without a word.
ask_yes() {
    local reply
    if ! read -r -p "$1 (yes/no): " reply; then
        if [ -t 0 ]; then echo ""; fi
        log_error "No answer on stdin to: $1"
        log_error "Nothing was changed. For unattended use pass --yes (and --backup or --no-backup), or --dry-run to preview."
        exit 1
    fi
    [ "$reply" = "yes" ]
}

# Print what a --dry-run skipped.
would() {
    log_info "[DRY RUN] Would $*"
}

# Expand tilde and resolve paths
SOURCE_DIR="${SOURCE_DIR/#\~/$HOME}"
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# Get absolute paths (left as given if the parent is missing; the
# pre-flight check below then reports the path the user actually typed)
if SOURCE_PARENT=$(cd "$(dirname "$SOURCE_DIR")" 2>/dev/null && pwd); then
    SOURCE_DIR="${SOURCE_PARENT%/}/$(basename "$SOURCE_DIR")"
fi
TARGET_DIR_PARENT=$(dirname "$TARGET_DIR")
TARGET_DIR_NAME=$(basename "$TARGET_DIR")

# Create backup directory name
BACKUP_DIR="${SOURCE_DIR}-backup-$(date +%Y%m%d-%H%M%S)"

################################################################################
# Pre-flight checks
################################################################################

print_header "Directory Rename Tool"

log_info "Source: $SOURCE_DIR"
log_info "Target: $TARGET_DIR"
if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN: checks only; nothing will be stopped, copied or moved"
fi
echo ""

# Check if source directory exists
log_step "Checking source directory..."
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi
log_success "Source directory exists"

# Check if target directory already exists
log_step "Checking target directory..."
if [ -d "$TARGET_DIR" ]; then
    log_error "Target directory already exists: $TARGET_DIR"
    log_error "Please remove or rename the existing directory first"
    exit 1
fi
log_success "Target path is available"

# Check if target parent directory exists
log_step "Checking target parent directory..."
if [ ! -d "$TARGET_DIR_PARENT" ]; then
    log_error "Target parent directory does not exist: $TARGET_DIR_PARENT"
    exit 1
fi
log_success "Target parent directory exists"

# Make the target absolute now: the git checks below cd into the source, so a
# relative target would otherwise resolve inside it and the mv would fail.
TARGET_DIR_PARENT=$(cd "$TARGET_DIR_PARENT" && pwd)
TARGET_DIR="${TARGET_DIR_PARENT%/}/${TARGET_DIR_NAME}"

# Check write permissions
log_step "Checking permissions..."
if [ ! -w "$(dirname "$SOURCE_DIR")" ]; then
    log_error "No write permission in source directory parent"
    exit 1
fi
if [ ! -w "$TARGET_DIR_PARENT" ]; then
    log_error "No write permission in target directory parent"
    exit 1
fi
log_success "Permissions verified"

################################################################################
# Docker container checks
################################################################################

log_step "Checking for related Docker containers..."
SOURCE_NAME=$(basename "$SOURCE_DIR")

# Check if docker is available
if command -v docker &> /dev/null; then
    RUNNING_CONTAINERS=$(docker ps --filter "name=$SOURCE_NAME" --format "{{.Names}}" 2>/dev/null || echo "")
    
    if [ -n "$RUNNING_CONTAINERS" ]; then
        log_warning "Found running Docker containers related to '$SOURCE_NAME':"
        echo "$RUNNING_CONTAINERS"
        echo ""
        if [ "$DRY_RUN" = true ]; then
            if [ "$ASSUME_YES" = true ]; then
                would "stop these containers (--yes): docker stop ${RUNNING_CONTAINERS//$'\n'/ }"
            else
                would "ask whether to stop these containers"
            fi
        elif [ "$ASSUME_YES" = true ] || ask_yes "Do you want to stop these containers?"; then
            log_info "Stopping containers..."
            echo "$RUNNING_CONTAINERS" | xargs docker stop 2>/dev/null || true
            log_success "Containers stopped"
        else
            log_warning "Proceeding with containers running (may cause issues)"
        fi
    else
        log_success "No related Docker containers running"
    fi
else
    log_info "Docker not installed, skipping container check"
fi

################################################################################
# Git repository checks
################################################################################

log_step "Checking if source is a git repository..."
cd "$SOURCE_DIR"

if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository detected"
    
    # Check git status
    log_info "Checking git status..."
    GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "")
    
    if [ -n "$GIT_STATUS" ]; then
        log_warning "There are uncommitted changes in the repository:"
        echo ""
        git status --short
        echo ""
        if [ "$DRY_RUN" = true ]; then
            if [ "$ASSUME_YES" = true ]; then
                would "continue despite the uncommitted changes (--yes)"
            else
                would "ask whether to continue despite the uncommitted changes"
            fi
        elif [ "$ASSUME_YES" = true ]; then
            log_info "Continuing despite uncommitted changes (--yes)"
        elif ! ask_yes "Do you want to continue anyway?"; then
            log_info "Aborting rename operation"
            exit 0
        fi
    else
        log_success "Git working directory is clean"
    fi
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    log_info "Current branch: $CURRENT_BRANCH"
else
    log_info "Not a git repository (skipping git checks)"
fi

################################################################################
# Backup option
################################################################################

echo ""
print_header "Backup Option"

log_info "Backup would be created at:"
log_info "  $BACKUP_DIR"
echo ""
if [ -n "$BACKUP_CHOICE" ]; then
    CREATE_BACKUP="$BACKUP_CHOICE"
elif [ "$DRY_RUN" = true ]; then
    CREATE_BACKUP=ask
elif ask_yes "Do you want to create a backup before renaming?"; then
    CREATE_BACKUP=yes
else
    CREATE_BACKUP=no
fi

if [ "$DRY_RUN" = true ]; then
    case "$CREATE_BACKUP" in
        yes) would "create the backup: cp -R \"$SOURCE_DIR\" \"$BACKUP_DIR\"" ;;
        no)  would "skip the backup (--no-backup)" ;;
        *)   would "ask whether to create the backup (pre-answer with --backup, --no-backup or --yes)" ;;
    esac
    would "rename: mv \"$SOURCE_DIR\" \"$TARGET_DIR\""
    echo ""
    log_success "Dry run complete: nothing was stopped, copied or moved"
    exit 0
fi

if [ "$CREATE_BACKUP" = "yes" ]; then
    log_step "Creating backup..."
    
    # Calculate directory size
    DIR_SIZE=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1)
    log_info "Directory size: $DIR_SIZE"
    log_info "This may take a few moments..."
    
    if cp -R "$SOURCE_DIR" "$BACKUP_DIR"; then
        log_success "Backup created successfully"
        log_info "Backup location: $BACKUP_DIR"
    else
        log_error "Failed to create backup"
        exit 1
    fi
else
    log_info "Skipping backup (not recommended)"
fi

################################################################################
# Perform the rename
################################################################################

echo ""
print_header "Performing Rename"

log_step "Renaming directory..."
log_info "From: $SOURCE_DIR"
log_info "To:   $TARGET_DIR"
echo ""

# Perform the rename
if mv "$SOURCE_DIR" "$TARGET_DIR"; then
    log_success "Directory renamed successfully!"
else
    log_error "Failed to rename directory"
    if [ "$CREATE_BACKUP" = "yes" ]; then
        log_info "Backup is available at: $BACKUP_DIR"
    fi
    exit 1
fi

################################################################################
# Verify the rename
################################################################################

echo ""
log_step "Verifying rename operation..."

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    log_error "Target directory does not exist after rename"
    exit 1
fi

# Check if source directory still exists (shouldn't)
if [ -d "$SOURCE_DIR" ]; then
    log_error "Source directory still exists after rename"
    exit 1
fi

# Verify git repository is intact (if applicable)
cd "$TARGET_DIR"
if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository is intact"
    
    # Show git status
    log_info "Git status after rename:"
    git status --short || true
else
    log_success "Directory structure verified"
fi

################################################################################
# Post-rename information
################################################################################

echo ""
print_header "Rename Complete"

log_success "Directory successfully renamed! 🎉"
echo ""
log_info "New location: $TARGET_DIR"
echo ""

log_info "Next Steps:"
echo "  1. Update your VS Code workspace to point to the new location"
echo "  2. Update any terminal sessions or IDE windows"
echo "  3. Update bookmarks and shortcuts"
echo "  4. If this is a git repository, consider updating:"
echo "     - Remote URLs (git remote set-url origin <new-url>)"
echo "     - Any CI/CD configurations"
echo "     - Documentation references"
echo ""

if [ "$CREATE_BACKUP" = "yes" ]; then
    log_info "Backup Information:"
    echo "  Location: $BACKUP_DIR"
    echo "  You can safely remove this backup once you've verified everything works"
    echo "  Command: rm -rf \"$BACKUP_DIR\""
    echo ""
fi

log_warning "Important Notes:"
echo "  - Git history has been preserved (if applicable)"
echo "  - Remote URLs still point to old repository paths (if applicable)"
echo "  - Package names and imports may need updating"
echo "  - Docker configurations may need updating"
echo "  - Environment variables may need updating"
echo ""

log_success "Operation completed successfully!"
echo ""

################################################################################
# End of script
################################################################################
