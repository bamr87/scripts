#!/bin/bash

###############################################################################
# File: stashme.sh
# Description: Multi-repository cloud stash utility - saves uncommitted changes
#              across multiple git repositories to remote backup branches
# Author: IT-Journey Scripts Team
# Created: 2026-02-03
# Last Modified: 2026-02-03
# Version: 1.0.0
#
# Dependencies:
# - git
# - gh (GitHub CLI) - optional, for authentication verification
# - find (standard Unix tool)
#
# Usage: ./stashme.sh [options] [base-directory]
# Example: ./stashme.sh ~/github
#         ./stashme.sh --dry-run --verbose ~/projects
###############################################################################

set -euo pipefail

# Cleanup on exit
cleanup() {
    # Return to original directory
    if [[ -n "${ORIGINAL_DIR:-}" ]]; then
        cd "$ORIGINAL_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Color codes for output
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly MAGENTA=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# Script version
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ORIGINAL_DIR="$(pwd)"

# Default configuration
BASE_DIR="${HOME}/github"
BRANCH_PREFIX="stashme"
BRANCH_SUFFIX=""
DRY_RUN=false
VERBOSE=false
QUIET=false
INTERACTIVE=false
MAX_DEPTH=3
INCLUDE_HIDDEN=false
PUSH_IMMEDIATELY=true
STASH_MESSAGE=""
FORCE_PUSH=false
LIST_ONLY=false
RESTORE_MODE=false
CLEANUP_MODE=false
SUMMARY_FILE=""

# Statistics - Initialize after parsing
repos_found=0
repos_with_changes=0
repos_stashed=0
repos_pushed=0
repos_skipped=0
repos_failed=0

###############################################################################
# Logging Functions
###############################################################################

log_info() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    [[ "$QUIET" == true ]] && return
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

log_step() {
    [[ "$QUIET" == true ]] && return
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

log_repo() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BOLD}[REPO]${NC} $1"
}

###############################################################################
# Help and Usage
###############################################################################

show_usage() {
    cat << EOF
${GREEN}StashMe - Multi-Repository Cloud Stash Utility${NC}

${YELLOW}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS] [base-directory]

${YELLOW}DESCRIPTION:${NC}
    Iterates through git-controlled folders and saves uncommitted changes
    to remote backup branches. Essentially saves open work to the cloud
    across multiple repositories.

${YELLOW}DEFAULT BEHAVIOR:${NC}
    - Searches for git repos in ~/github (or specified directory)
    - Creates a timestamped branch: stashme/YYYY-MM-DD-HHMMSS
    - Commits all changes with a descriptive message
    - Pushes to origin (your fork/remote)

${YELLOW}OPTIONS:${NC}
    ${CYAN}Directory Options:${NC}
    -d, --dir <path>        Base directory to search (default: ~/github)
    --max-depth <n>         Maximum directory depth to search (default: 3)
    --include-hidden        Include hidden directories in search

    ${CYAN}Branch Options:${NC}
    -b, --branch <name>     Custom branch name (default: stashme/YYYY-MM-DD-HHMMSS)
    --prefix <prefix>       Branch name prefix (default: stashme)
    --suffix <suffix>       Branch name suffix (appended after timestamp)

    ${CYAN}Commit Options:${NC}
    -m, --message <msg>     Custom commit message
    --no-push               Create branch and commit, but don't push
    -f, --force             Force push (overwrite remote branch if exists)

    ${CYAN}Mode Options:${NC}
    -l, --list              List repos with uncommitted changes (no action)
    -r, --restore           Restore mode: checkout and merge stashme branches
    --cleanup               Cleanup mode: delete local and remote stashme branches
    -i, --interactive       Interactive mode: confirm before each action

    ${CYAN}Output Options:${NC}
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress non-error output
    --dry-run               Show what would be done without executing
    --summary <file>        Write summary report to file

    ${CYAN}Information:${NC}
    --version               Display version information
    -h, --help              Display this help message

${YELLOW}EXAMPLES:${NC}

    ${GREEN}# Stash all repos in ~/github (default)${NC}
    $SCRIPT_NAME

    ${GREEN}# Stash repos in a specific directory${NC}
    $SCRIPT_NAME ~/projects

    ${GREEN}# Custom branch name${NC}
    $SCRIPT_NAME --branch wip/emergency-backup

    ${GREEN}# List repos with changes (no action)${NC}
    $SCRIPT_NAME --list

    ${GREEN}# Dry run to preview actions${NC}
    $SCRIPT_NAME --dry-run --verbose

    ${GREEN}# Interactive mode with custom message${NC}
    $SCRIPT_NAME -i -m "WIP: saving before vacation"

    ${GREEN}# Restore previously stashed changes${NC}
    $SCRIPT_NAME --restore

    ${GREEN}# Cleanup old stashme branches${NC}
    $SCRIPT_NAME --cleanup

    ${GREEN}# Force push with custom prefix${NC}
    $SCRIPT_NAME --prefix backup --force

${YELLOW}BRANCH NAMING:${NC}
    Default format: stashme/YYYY-MM-DD-HHMMSS
    With suffix:    stashme/YYYY-MM-DD-HHMMSS-<suffix>
    Custom:         Specified via --branch option

${YELLOW}RESTORE MODE:${NC}
    In restore mode, the script will:
    1. Find repos with stashme/* branches
    2. Checkout the most recent stashme branch
    3. Optionally merge or cherry-pick changes back

${YELLOW}CLEANUP MODE:${NC}
    In cleanup mode, the script will:
    1. Find repos with stashme/* branches
    2. Delete local stashme branches
    3. Optionally delete remote stashme branches

${YELLOW}EXIT CODES:${NC}
    0 - Success (all repos processed)
    1 - Partial success (some repos failed)
    2 - Invalid arguments
    3 - No git repos found
    4 - All repos failed

${YELLOW}NOTES:${NC}
    - Only processes repos with a configured remote (origin)
    - Skips repos without uncommitted changes (unless in list mode)
    - Creates new branch from current HEAD
    - Does not modify your working branch
    - Use --restore to get changes back

EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
}

###############################################################################
# Dependency Checks
###############################################################################

check_dependencies() {
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v find &> /dev/null; then
        missing_deps+=("find")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 2
    fi

    # Check git version (need 2.0+ for some features)
    local git_version
    git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    log_debug "Git version: $git_version"
}

###############################################################################
# Utility Functions
###############################################################################

# Generate timestamp for branch naming
generate_timestamp() {
    date +"%Y-%m-%d-%H%M%S"
}

# Generate branch name
generate_branch_name() {
    local timestamp
    timestamp=$(generate_timestamp)
    
    if [[ -n "$BRANCH_SUFFIX" ]]; then
        echo "${BRANCH_PREFIX}/${timestamp}-${BRANCH_SUFFIX}"
    else
        echo "${BRANCH_PREFIX}/${timestamp}"
    fi
}

# Check if directory is a git repository
is_git_repo() {
    local dir="$1"
    [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1
}

# Check if repo has uncommitted changes
has_changes() {
    local dir="$1"
    ! git -C "$dir" diff --quiet HEAD 2>/dev/null || \
    ! git -C "$dir" diff --cached --quiet 2>/dev/null || \
    [[ -n "$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null)" ]]
}

# Get count of changed files
get_change_count() {
    local dir="$1"
    local count=0
    
    # Modified files
    count=$((count + $(git -C "$dir" diff --name-only 2>/dev/null | wc -l)))
    # Staged files
    count=$((count + $(git -C "$dir" diff --cached --name-only 2>/dev/null | wc -l)))
    # Untracked files
    count=$((count + $(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l)))
    
    echo "$count"
}

# Check if repo has a remote configured
has_remote() {
    local dir="$1"
    git -C "$dir" remote get-url origin &>/dev/null 2>&1
}

# Get current branch name
get_current_branch() {
    local dir="$1"
    git -C "$dir" branch --show-current 2>/dev/null || git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Get repo name from directory
get_repo_name() {
    local dir="$1"
    basename "$dir"
}

# Confirm action in interactive mode
confirm_action() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$INTERACTIVE" != true ]]; then
        return 0
    fi
    
    local yn_prompt
    if [[ "$default" == "y" ]]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi
    
    read -r -p "$prompt $yn_prompt: " response
    response="${response:-$default}"
    
    [[ "$response" =~ ^[Yy] ]]
}

###############################################################################
# Core Functions
###############################################################################

# Find all git repositories
find_git_repos() {
    local base_dir="$1"
    local repos=()
    
    log_step "Searching for git repositories in: $base_dir" >&2
    
    # Build find command
    local find_cmd="find \"$base_dir\" -maxdepth $MAX_DEPTH -type d -name .git"
    
    if [[ "$INCLUDE_HIDDEN" != true ]]; then
        find_cmd="find \"$base_dir\" -maxdepth $MAX_DEPTH -type d -name .git -not -path '*/.*/*'"
    fi
    
    # Execute find and extract parent directories
    while IFS= read -r git_dir; do
        local repo_dir
        repo_dir=$(dirname "$git_dir")
        repos+=("$repo_dir")
        log_debug "Found repo: $repo_dir" >&2
    done < <(eval "$find_cmd" 2>/dev/null | sort)
    
    repos_found=${#repos[@]}
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_warning "No git repositories found in: $base_dir"
        return 1
    fi
    
    log_info "Found ${#repos[@]} git repositories" >&2
    
    # Return repos array
    printf '%s\n' "${repos[@]}"
}

# Process a single repository
process_repo() {
    local repo_dir="$1"
    local branch_name="$2"
    local repo_name
    repo_name=$(get_repo_name "$repo_dir")
    
    log_repo "Processing: $repo_name ($repo_dir)"
    
    # Check for changes
    if ! has_changes "$repo_dir"; then
        log_debug "  No uncommitted changes, skipping"
        ((repos_skipped++))
        return 0
    fi
    
    ((repos_with_changes++))
    
    local change_count
    change_count=$(get_change_count "$repo_dir")
    log_info "  Found $change_count changed file(s)"
    
    # List-only mode
    if [[ "$LIST_ONLY" == true ]]; then
        echo "  📁 $repo_name: $change_count file(s) changed"
        git -C "$repo_dir" status --short 2>/dev/null | head -10 | sed 's/^/       /'
        local total_changes
        total_changes=$(git -C "$repo_dir" status --short 2>/dev/null | wc -l)
        if [[ $total_changes -gt 10 ]]; then
            echo "       ... and $((total_changes - 10)) more"
        fi
        return 0
    fi
    
    # Check for remote
    if ! has_remote "$repo_dir"; then
        log_warning "  No remote 'origin' configured, skipping"
        ((repos_skipped++))
        return 0
    fi
    
    # Interactive confirmation
    if ! confirm_action "  Stash changes in $repo_name?"; then
        log_info "  Skipped by user"
        ((repos_skipped++))
        return 0
    fi
    
    # Dry run mode
    if [[ "$DRY_RUN" == true ]]; then
        log_info "  [DRY RUN] Would create branch: $branch_name"
        log_info "  [DRY RUN] Would commit $change_count file(s)"
        [[ "$PUSH_IMMEDIATELY" == true ]] && log_info "  [DRY RUN] Would push to origin"
        return 0
    fi
    
    # Get current branch for return
    local original_branch
    original_branch=$(get_current_branch "$repo_dir")
    log_debug "  Current branch: $original_branch"
    
    # Stash the changes
    if ! stash_repo_changes "$repo_dir" "$branch_name" "$original_branch"; then
        log_error "  Failed to stash changes"
        ((repos_failed++))
        return 1
    fi
    
    ((repos_stashed++))
    
    # Push if enabled
    if [[ "$PUSH_IMMEDIATELY" == true ]]; then
        if push_stash_branch "$repo_dir" "$branch_name"; then
            ((repos_pushed++))
            log_success "  Pushed to origin/$branch_name"
        else
            log_warning "  Failed to push, changes saved locally only"
        fi
    fi
    
    return 0
}

# Stash changes in a repository
stash_repo_changes() {
    local repo_dir="$1"
    local branch_name="$2"
    local original_branch="$3"
    
    cd "$repo_dir" || return 1
    
    # Create new branch from current HEAD
    log_debug "  Creating branch: $branch_name"
    if ! git checkout -b "$branch_name" 2>/dev/null; then
        # Branch might exist, try to check it out
        if ! git checkout "$branch_name" 2>/dev/null; then
            log_error "  Failed to create/checkout branch: $branch_name"
            cd "$ORIGINAL_DIR"
            return 1
        fi
    fi
    
    # Add all changes (including untracked)
    log_debug "  Adding all changes..."
    git add -A
    
    # Create commit message
    local commit_msg
    if [[ -n "$STASH_MESSAGE" ]]; then
        commit_msg="$STASH_MESSAGE"
    else
        local timestamp
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        commit_msg="StashMe: Auto-saved changes from $original_branch at $timestamp

Original branch: $original_branch
Saved by: stashme.sh v$VERSION
Host: $(hostname)
User: $(whoami)"
    fi
    
    # Commit changes
    log_debug "  Committing changes..."
    if ! git commit -m "$commit_msg" 2>/dev/null; then
        log_error "  Failed to commit changes"
        git checkout "$original_branch" 2>/dev/null
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    # Return to original branch
    log_debug "  Returning to original branch: $original_branch"
    git checkout "$original_branch" 2>/dev/null
    
    cd "$ORIGINAL_DIR"
    return 0
}

# Push stash branch to remote
push_stash_branch() {
    local repo_dir="$1"
    local branch_name="$2"
    
    cd "$repo_dir" || return 1
    
    local push_cmd="git push origin $branch_name"
    [[ "$FORCE_PUSH" == true ]] && push_cmd="git push --force origin $branch_name"
    
    log_debug "  Pushing: $push_cmd"
    
    if ! eval "$push_cmd" 2>/dev/null; then
        cd "$ORIGINAL_DIR"
        return 1
    fi
    
    cd "$ORIGINAL_DIR"
    return 0
}

# List stashme branches in a repository
list_stash_branches() {
    local repo_dir="$1"
    
    # Local branches
    git -C "$repo_dir" branch --list "${BRANCH_PREFIX}/*" 2>/dev/null | sed 's/^[* ]*//'
    
    # Remote branches
    git -C "$repo_dir" branch -r --list "origin/${BRANCH_PREFIX}/*" 2>/dev/null | sed 's/^[* ]*//'
}

# Restore mode - checkout stashme branches
restore_repos() {
    local repos=()
    
    while IFS= read -r repo; do
        [[ -n "$repo" ]] && repos+=("$repo")
    done < <(find_git_repos "$BASE_DIR")
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_error "No git repositories found"
        return 3
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    RESTORE MODE"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    for repo_dir in "${repos[@]}"; do
        local repo_name
        repo_name=$(get_repo_name "$repo_dir")
        
        # Find stashme branches
        local stash_branches
        stash_branches=$(list_stash_branches "$repo_dir")
        
        if [[ -z "$stash_branches" ]]; then
            continue
        fi
        
        log_repo "$repo_name has stashme branches:"
        echo "$stash_branches" | sed 's/^/    /'
        
        if confirm_action "  Restore most recent stashme branch?"; then
            local latest_branch
            latest_branch=$(echo "$stash_branches" | grep -v "^origin/" | sort -r | head -1)
            
            if [[ -n "$latest_branch" ]]; then
                log_info "  Checking out: $latest_branch"
                if [[ "$DRY_RUN" != true ]]; then
                    git -C "$repo_dir" checkout "$latest_branch" 2>/dev/null
                fi
            fi
        fi
        echo ""
    done
}

# Cleanup mode - delete stashme branches
cleanup_repos() {
    local repos=()
    
    while IFS= read -r repo; do
        [[ -n "$repo" ]] && repos+=("$repo")
    done < <(find_git_repos "$BASE_DIR")
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_error "No git repositories found"
        return 3
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    CLEANUP MODE"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    for repo_dir in "${repos[@]}"; do
        local repo_name
        repo_name=$(get_repo_name "$repo_dir")
        
        # Find stashme branches
        local local_branches remote_branches
        local_branches=$(git -C "$repo_dir" branch --list "${BRANCH_PREFIX}/*" 2>/dev/null | sed 's/^[* ]*//')
        remote_branches=$(git -C "$repo_dir" branch -r --list "origin/${BRANCH_PREFIX}/*" 2>/dev/null | sed 's/^[* ]*/origin\//')
        
        if [[ -z "$local_branches" && -z "$remote_branches" ]]; then
            continue
        fi
        
        log_repo "$repo_name"
        
        # Delete local branches
        if [[ -n "$local_branches" ]]; then
            log_info "  Local stashme branches:"
            echo "$local_branches" | sed 's/^/    /'
            
            if confirm_action "  Delete local stashme branches?" "y"; then
                while IFS= read -r branch; do
                    [[ -z "$branch" ]] && continue
                    log_debug "  Deleting local branch: $branch"
                    if [[ "$DRY_RUN" != true ]]; then
                        git -C "$repo_dir" branch -D "$branch" 2>/dev/null || true
                    else
                        log_info "  [DRY RUN] Would delete: $branch"
                    fi
                done <<< "$local_branches"
            fi
        fi
        
        # Delete remote branches
        if [[ -n "$remote_branches" ]]; then
            log_info "  Remote stashme branches:"
            echo "$remote_branches" | sed 's/^/    /'
            
            if confirm_action "  Delete remote stashme branches?"; then
                while IFS= read -r branch; do
                    [[ -z "$branch" ]] && continue
                    local remote_name="${branch#origin/}"
                    log_debug "  Deleting remote branch: $remote_name"
                    if [[ "$DRY_RUN" != true ]]; then
                        git -C "$repo_dir" push origin --delete "$remote_name" 2>/dev/null || true
                    else
                        log_info "  [DRY RUN] Would delete remote: $remote_name"
                    fi
                done <<< "$remote_branches"
            fi
        fi
        
        echo ""
    done
}

# Print summary
print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                         SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  Repositories found:        ${repos_found}"
    echo "  Repositories with changes: ${repos_with_changes}"
    echo "  Successfully stashed:      ${repos_stashed}"
    echo "  Successfully pushed:       ${repos_pushed}"
    echo "  Skipped (no changes/user): ${repos_skipped}"
    echo "  Failed:                    ${repos_failed}"
    echo ""
    
    if [[ -n "$SUMMARY_FILE" ]]; then
        {
            echo "StashMe Summary Report"
            echo "Generated: $(date)"
            echo "Base Directory: $BASE_DIR"
            echo ""
            echo "Statistics:"
            echo "  Repos Found: ${repos_found}"
            echo "  With Changes: ${repos_with_changes}"
            echo "  Stashed: ${repos_stashed}"
            echo "  Pushed: ${repos_pushed}"
            echo "  Skipped: ${repos_skipped}"
            echo "  Failed: ${repos_failed}"
        } > "$SUMMARY_FILE"
        log_info "Summary written to: $SUMMARY_FILE"
    fi
}

###############################################################################
# Argument Parsing
###############################################################################

parse_arguments() {
    local custom_branch=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -d|--dir)
                BASE_DIR="$2"
                shift 2
                ;;
            --max-depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            --include-hidden)
                INCLUDE_HIDDEN=true
                shift
                ;;
            -b|--branch)
                custom_branch="$2"
                shift 2
                ;;
            --prefix)
                BRANCH_PREFIX="$2"
                shift 2
                ;;
            --suffix)
                BRANCH_SUFFIX="$2"
                shift 2
                ;;
            -m|--message)
                STASH_MESSAGE="$2"
                shift 2
                ;;
            --no-push)
                PUSH_IMMEDIATELY=false
                shift
                ;;
            -f|--force)
                FORCE_PUSH=true
                shift
                ;;
            -l|--list)
                LIST_ONLY=true
                shift
                ;;
            -r|--restore)
                RESTORE_MODE=true
                shift
                ;;
            --cleanup)
                CLEANUP_MODE=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --summary)
                SUMMARY_FILE="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 2
                ;;
            *)
                # Positional argument is the base directory
                BASE_DIR="$1"
                shift
                ;;
        esac
    done
    
    # Use custom branch if provided
    if [[ -n "$custom_branch" ]]; then
        BRANCH_NAME="$custom_branch"
    fi
    
    # Expand tilde in BASE_DIR
    BASE_DIR="${BASE_DIR/#\~/$HOME}"
    
    # Validate base directory
    if [[ ! -d "$BASE_DIR" ]]; then
        log_error "Base directory does not exist: $BASE_DIR"
        exit 2
    fi
}

###############################################################################
# Main Function
###############################################################################

main() {
    parse_arguments "$@"
    check_dependencies
    
    # Generate branch name if not custom
    local branch_name="${BRANCH_NAME:-$(generate_branch_name)}"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "     StashMe - Multi-Repository Cloud Stash Utility v$VERSION"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  Base directory: $BASE_DIR"
    echo "  Branch name:    $branch_name"
    echo "  Dry run:        $DRY_RUN"
    echo "  Push to remote: $PUSH_IMMEDIATELY"
    echo ""
    
    # Handle special modes
    if [[ "$RESTORE_MODE" == true ]]; then
        restore_repos
        exit $?
    fi
    
    if [[ "$CLEANUP_MODE" == true ]]; then
        cleanup_repos
        exit $?
    fi
    
    # Find repositories
    local repos=()
    while IFS= read -r repo; do
        [[ -n "$repo" ]] && repos+=("$repo")
    done < <(find_git_repos "$BASE_DIR")
    
    if [[ ${#repos[@]} -eq 0 ]]; then
        log_error "No git repositories found in: $BASE_DIR"
        exit 3
    fi
    
    echo ""
    
    # Process each repository
    for repo_dir in "${repos[@]}"; do
        process_repo "$repo_dir" "$branch_name"
        echo ""
    done
    
    # Print summary
    print_summary
    
    # Determine exit code
    if [[ ${repos_failed} -eq ${repos_with_changes} && ${repos_with_changes} -gt 0 ]]; then
        exit 4  # All repos failed
    elif [[ ${repos_failed} -gt 0 ]]; then
        exit 1  # Partial success
    else
        exit 0  # Success
    fi
}

# Run main function
main "$@"
