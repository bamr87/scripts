#!/bin/bash

###############################################################################
# File: forkme.sh
# Description: Advanced GitHub repository forking and cloning utility with 
#              multiple strategies for analysis, review, testing, and research.
#              Supports interactive mode for batch-listing, filtering, selecting,
#              and cloning all repos from a GitHub user or organization.
# Author: IT-Journey Scripts Team
# Created: 2025-11-01
# Last Modified: 2026-02-10
# Version: 2.2.0
#
# Dependencies:
# - gh (GitHub CLI)
# - git
# - jq (for JSON parsing)
# - find, grep, sed (standard Unix tools)
#
# Usage: ./forkme.sh [options] <repository-url>
#        ./forkme.sh --interactive [--user <name>] [--target <dir>]
# Example: ./forkme.sh --strategy shallow --depth 1 https://github.com/user/repo
# Example: ./forkme.sh -i --user bamr87 --target ~/github
###############################################################################

set -euo pipefail

# Cleanup on exit
TEMP_DIRS=()
cleanup() {
    if [[ ${#TEMP_DIRS[@]} -gt 0 ]]; then
        log_debug "Cleaning up temporary directories..."
        for dir in "${TEMP_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                rm -rf "$dir"
            fi
        done
    fi
}
trap cleanup EXIT INT TERM

# Color codes for output
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color

# Script version
VERSION="2.2.0"

# Default configuration
FORK_STRATEGY="full"
CLONE_DEPTH=""
TARGET_DIR=""
FILE_TYPES=()
INCLUDE_PATTERNS=()
EXCLUDE_PATTERNS=()
DRY_RUN=false
VERBOSE=false
CREATE_FORK=false
BRANCH=""
SPARSE_CHECKOUT=false
SPARSE_PATHS=()
ANALYZE_ONLY=false
SKIP_FORK=false
WORK_DIR="$(pwd)/forkme-workspace"

# Interactive mode configuration
INTERACTIVE=false
CLONE_ALL=false
GH_USER=""
GH_ORG_MODE=false
INTERACTIVE_TARGET="$(pwd)/repos"

# Interactive filter state
FILTER_LANGUAGE=""
FILTER_VISIBILITY=""
FILTER_FORK_STATUS=""
FILTER_ARCHIVED="false"
FILTER_NAME_PATTERN=""
FILTER_TAGS=()
FILTER_TAG_MODE="any"
FILTER_MIN_SIZE=""
FILTER_MAX_SIZE=""
FILTER_UPDATED_AFTER=""
SORT_ORDER="stars"

# Interactive data
REPO_JSON=""
FILTERED_JSON=""
FILTERED_REPOS=()
SELECTED_REPOS=()

# Bold/dim (for interactive display)
if [[ -t 1 ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
else
    BOLD=''
    DIM=''
fi

###############################################################################
# Logging Functions
###############################################################################

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

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

###############################################################################
# Help and Usage
###############################################################################

show_usage() {
    cat << EOF
${GREEN}ForkMe - Advanced GitHub Repository Forking Utility${NC}

${YELLOW}USAGE:${NC}
    ./forkme.sh [OPTIONS] <repository-url>

${YELLOW}REPOSITORY URL FORMATS:${NC}
    - Full URL: https://github.com/owner/repo
    - SSH URL: git@github.com:owner/repo.git
    - Short form: owner/repo

${YELLOW}FORKING STRATEGIES:${NC}
    ${CYAN}--strategy${NC} <type>
        ${GREEN}full${NC}           - Complete fork with all history (default)
        ${GREEN}shallow${NC}        - Shallow clone with limited history
        ${GREEN}sparse${NC}         - Sparse checkout (specific directories only)
        ${GREEN}toplevel${NC}       - Top-level files only (no subdirectories)
        ${GREEN}structure${NC}      - Directory structure only (no file contents)
        ${GREEN}filetype${NC}       - Files matching specific extensions only
        ${GREEN}analysis${NC}       - Optimized for quick analysis (shallow + sparse)
        ${GREEN}mirror${NC}         - Mirror clone (for backup/archival)
        ${GREEN}bundle${NC}         - Create a git bundle file
        ${GREEN}metadata${NC}       - Repository metadata only (no clone)

${YELLOW}CLONE OPTIONS:${NC}
    ${CYAN}--depth${NC} <n>         - Limit history to <n> commits (for shallow clones)
    ${CYAN}--branch${NC} <name>     - Clone specific branch only
    ${CYAN}--no-fork${NC}           - Skip GitHub fork creation (clone only)
    ${CYAN}--target${NC} <dir>      - Target directory for clone
    ${CYAN}--work-dir${NC} <dir>    - Working directory base (default: ./forkme-workspace)

${YELLOW}FILTERING OPTIONS:${NC}
    ${CYAN}--file-types${NC} <ext>  - Include only specific file types (comma-separated)
                           Example: --file-types "py,js,md"
    ${CYAN}--include${NC} <pattern> - Include paths matching pattern (can be used multiple times)
    ${CYAN}--exclude${NC} <pattern> - Exclude paths matching pattern (can be used multiple times)
    ${CYAN}--sparse-paths${NC} <p>  - Sparse checkout paths (comma-separated)
                           Example: --sparse-paths "src/,docs/,README.md"

${YELLOW}ANALYSIS OPTIONS:${NC}
    ${CYAN}--analyze${NC}           - Perform repository analysis after cloning
    ${CYAN}--analyze-only${NC}      - Analyze without cloning (requires GitHub API)
    ${CYAN}--stats${NC}             - Show repository statistics

${YELLOW}INTERACTIVE MODE:${NC}
    ${CYAN}--interactive, -i${NC}   - Launch interactive mode: list, filter, and select
                           repos from a GitHub user/org to batch-clone
    ${CYAN}--user${NC} <name>       - GitHub username or org (prompted if omitted)
    ${CYAN}--org${NC} <name>        - Alias for --user (explicit org mode)
    ${CYAN}--clone-all${NC}         - Quick mode: clone all repos without interactive selection
    ${CYAN}--fork${NC}              - Create GitHub forks (default: clone only)
    ${CYAN}--tags${NC} <topics>     - Filter repos by GitHub topics/tags (comma-separated)
                           Example: --tags "python,web,cli"
    ${CYAN}--tag-mode${NC} <mode>   - Tag matching mode: 'any' (default) or 'all'
                           any = repo must have at least one of the tags
                           all = repo must have all specified tags

${YELLOW}CONTROL OPTIONS:${NC}
    ${CYAN}--dry-run${NC}           - Show what would be done without executing
    ${CYAN}--verbose${NC}           - Enable verbose output
    ${CYAN}--version${NC}           - Display version information
    ${CYAN}--help${NC}              - Display this help message

${YELLOW}EXAMPLES:${NC}

    ${GREEN}# Full fork with all history${NC}
    ./forkme.sh https://github.com/torvalds/linux

    ${GREEN}# Shallow clone for quick review (last 1 commit)${NC}
    ./forkme.sh --strategy shallow --depth 1 owner/repo

    ${GREEN}# Sparse checkout of specific directories${NC}
    ./forkme.sh --strategy sparse --sparse-paths "src/,docs/" owner/repo

    ${GREEN}# Top-level files only (no subdirectories)${NC}
    ./forkme.sh --strategy toplevel owner/repo

    ${GREEN}# Filter by file types (Python and JavaScript only)${NC}
    ./forkme.sh --strategy filetype --file-types "py,js" owner/repo

    ${GREEN}# Analysis strategy (shallow + specific paths)${NC}
    ./forkme.sh --strategy analysis --sparse-paths "src/,package.json" owner/repo

    ${GREEN}# Clone without forking (direct clone)${NC}
    ./forkme.sh --no-fork --depth 10 owner/repo

    ${GREEN}# Metadata analysis only (no clone)${NC}
    ./forkme.sh --analyze-only owner/repo

    ${GREEN}# Create git bundle for offline analysis${NC}
    ./forkme.sh --strategy bundle owner/repo

    ${GREEN}# Directory structure analysis${NC}
    ./forkme.sh --strategy structure owner/repo

${YELLOW}COMMON USE CASES:${NC}

    ${CYAN}Security Review:${NC}
    ./forkme.sh --strategy analysis --sparse-paths "src/,*.config" \\
                --exclude "node_modules/,*.min.js" owner/repo

    ${CYAN}Documentation Review:${NC}
    ./forkme.sh --strategy filetype --file-types "md,txt,rst" owner/repo

    ${CYAN}Configuration Analysis:${NC}
    ./forkme.sh --strategy sparse --sparse-paths "*.yml,*.json,*.toml,Dockerfile" owner/repo

    ${CYAN}Quick Code Structure Review:${NC}
    ./forkme.sh --strategy structure --analyze owner/repo

    ${CYAN}Testing/Research Clone:${NC}
    ./forkme.sh --strategy shallow --depth 5 --no-fork owner/repo

    ${CYAN}Interactive: batch-clone all repos from a user:${NC}
    ./forkme.sh --interactive --user bamr87 --target ~/github

    ${CYAN}Quick clone all repos from a user:${NC}
    ./forkme.sh -i --user bamr87 --clone-all --target ~/github

    ${CYAN}Interactive: clone org repos with dry run:${NC}
    ./forkme.sh -i --org my-org --dry-run

    ${CYAN}Clone all non-archived original repos (no forks):${NC}
    ./forkme.sh -i --user bamr87 --clone-all --target ~/github

    ${CYAN}Clone only repos tagged with specific topics:${NC}
    ./forkme.sh -i --user bamr87 --tags "python,api" --target ~/github

    ${CYAN}Clone repos that have ALL specified tags:${NC}
    ./forkme.sh -i --user bamr87 --tags "python,cli" --tag-mode all --target ~/github

EOF
}

###############################################################################
# Dependency Checks
###############################################################################

check_dependencies() {
    local missing_deps=()

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v gh &> /dev/null; then
        missing_deps+=("gh (GitHub CLI)")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        echo "  macOS: brew install git gh jq"
        echo "  Ubuntu/Debian: apt-get install git gh jq"
        echo "  Fedora/RHEL: dnf install git gh jq"
        exit 1
    fi

    # Check GitHub CLI authentication
    if [[ "$CREATE_FORK" == true ]] && ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated"
        echo "Run: gh auth login"
        exit 1
    fi
}

###############################################################################
# Input Validation Functions
###############################################################################

validate_sparse_paths() {
    for path in "${SPARSE_PATHS[@]}"; do
        # Check for leading slash (invalid)
        if [[ "$path" =~ ^/ ]]; then
            log_error "Invalid sparse path: $path (paths should not start with /)"
            exit 1
        fi
        # Warn about potentially problematic patterns
        if [[ "$path" =~ \.\. ]]; then
            log_warning "Sparse path contains '..': $path (may cause issues)"
        fi
    done
}

validate_file_types() {
    for ext in "${FILE_TYPES[@]}"; do
        # Remove leading dots if present
        ext="${ext#.}"
        # Check for invalid characters
        if [[ "$ext" =~ [^a-zA-Z0-9_-] ]]; then
            log_error "Invalid file extension: $ext (use alphanumeric, underscore, or hyphen only)"
            exit 1
        fi
    done
}

validate_target_dir() {
    local target="$1"
    
    # Check if target already exists
    if [[ -e "$target" ]] && [[ "$DRY_RUN" == false ]]; then
        log_error "Target directory already exists: $target"
        log_info "Please remove it or choose a different target with --target option"
        exit 1
    fi
}

###############################################################################
# Repository URL Parsing
###############################################################################

parse_repo_url() {
    local url="$1"
    local owner=""
    local repo=""

    # Handle different URL formats
    if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/?$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^git@github\.com:([^/]+)/(.+)\.git$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^([^/]+)/([^/]+)$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
    else
        log_error "Invalid repository URL format: $url"
        exit 1
    fi

    # Remove .git suffix if present
    repo="${repo%.git}"

    echo "${owner}/${repo}"
}

###############################################################################
# Repository Analysis Functions
###############################################################################

analyze_repo_metadata() {
    local repo="$1"
    
    log_step "Analyzing repository metadata: $repo"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would analyze metadata for: $repo"
        return
    fi

    local metadata
    metadata=$(gh repo view "$repo" --json name,owner,description,createdAt,updatedAt,pushedAt,diskUsage,forkCount,stargazerCount,watchers,primaryLanguage,languages,licenseInfo,isPrivate,isFork,parent 2>/dev/null || echo "{}")

    if [[ "$metadata" == "{}" ]]; then
        log_error "Failed to retrieve repository metadata"
        return 1
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    REPOSITORY METADATA"
    echo "═══════════════════════════════════════════════════════════════"
    echo "$metadata" | jq -r '
        "Repository: \(.owner.login)/\(.name)",
        "Description: \(.description // "N/A")",
        "Created: \(.createdAt)",
        "Last Updated: \(.updatedAt)",
        "Last Push: \(.pushedAt)",
        "Size: \(.diskUsage) KB",
        "Stars: ⭐ \(.stargazerCount)",
        "Forks: 🍴 \(.forkCount)",
        "Watchers: 👁️  \(.watchers.totalCount)",
        "Primary Language: \(.primaryLanguage.name // "N/A")",
        "License: \(.licenseInfo.name // "N/A")",
        "Private: \(.isPrivate)",
        "Is Fork: \(.isFork)",
        (if .isFork then "Parent: \(.parent.owner.login)/\(.parent.name)" else "" end)
    '
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

analyze_repo_structure() {
    local clone_dir="$1"
    
    log_step "Analyzing repository structure"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                  REPOSITORY STRUCTURE"
    echo "═══════════════════════════════════════════════════════════════"
    
    # Directory count
    local dir_count=$(find "$clone_dir" -type d ! -path "*/.git/*" | wc -l)
    echo "📁 Total Directories: $dir_count"
    
    # File count
    local file_count=$(find "$clone_dir" -type f ! -path "*/.git/*" | wc -l)
    echo "📄 Total Files: $file_count"
    
    # File type distribution
    echo ""
    echo "File Type Distribution:"
    find "$clone_dir" -type f ! -path "*/.git/*" -name "*.*" | \
        sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10 | \
        awk '{printf "  %-15s %s\n", $2":", $1}'
    
    # Largest files
    echo ""
    echo "Largest Files:"
    find "$clone_dir" -type f ! -path "*/.git/*" -exec ls -lh {} \; | \
        sort -k5 -hr | head -5 | \
        awk '{printf "  %8s  %s\n", $5, $9}'
    
    # Directory tree (limited depth)
    echo ""
    echo "Directory Tree (3 levels):"
    tree -L 3 -d "$clone_dir" 2>/dev/null || \
        find "$clone_dir" -type d ! -path "*/.git/*" -maxdepth 3 | \
        sed "s|$clone_dir||" | head -20
    
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

###############################################################################
# Forking Strategies
###############################################################################

strategy_full() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing FULL fork strategy"
    
    if [[ "$CREATE_FORK" == true ]]; then
        log_info "Creating fork on GitHub..."
        if [[ "$DRY_RUN" == false ]]; then
            # Check if fork already exists
            local username
            username=$(gh api user | jq -r '.login')
            local repo_name=$(echo "$repo" | cut -d'/' -f2)
            
            if gh repo view "$username/$repo_name" &> /dev/null; then
                log_warning "Fork already exists: $username/$repo_name"
                repo="$username/$repo_name"
            else
                if gh repo fork "$repo" --clone=false; then
                    repo="$username/$repo_name"
                    log_success "Fork created: $repo"
                else
                    log_error "Failed to create fork, will clone original repository"
                fi
            fi
        fi
    fi
    
    log_info "Cloning repository with full history..."
    if [[ "$DRY_RUN" == false ]]; then
        if ! git clone "https://github.com/${repo}.git" "$target_dir"; then
            log_error "Failed to clone repository"
            exit 1
        fi
    else
        log_info "[DRY RUN] Would clone: https://github.com/${repo}.git to $target_dir"
    fi
}

strategy_shallow() {
    local repo="$1"
    local target_dir="$2"
    local depth="${CLONE_DEPTH:-1}"
    
    log_step "Executing SHALLOW clone strategy (depth: $depth)"
    
    local branch_arg=""
    if [[ -n "$BRANCH" ]]; then
        branch_arg="--branch $BRANCH --single-branch"
        log_info "Cloning branch: $BRANCH"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        if ! git clone --depth "$depth" $branch_arg "https://github.com/${repo}.git" "$target_dir"; then
            log_error "Failed to perform shallow clone"
            exit 1
        fi
        log_success "Shallow clone completed (depth: $depth)"
    else
        log_info "[DRY RUN] Would shallow clone (depth $depth): https://github.com/${repo}.git"
    fi
}

strategy_sparse() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing SPARSE checkout strategy"
    
    if [[ ${#SPARSE_PATHS[@]} -eq 0 ]]; then
        log_error "Sparse strategy requires --sparse-paths option"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        if ! git clone --filter=blob:none --sparse "https://github.com/${repo}.git" "$target_dir"; then
            log_error "Failed to perform sparse clone"
            exit 1
        fi
        
        cd "$target_dir"
        if ! git sparse-checkout init --cone; then
            log_error "Failed to initialize sparse checkout"
            cd - > /dev/null
            exit 1
        fi
        
        for path in "${SPARSE_PATHS[@]}"; do
            log_info "Adding sparse path: $path"
            if ! git sparse-checkout add "$path"; then
                log_warning "Failed to add sparse path: $path (path may not exist)"
            fi
        done
        cd - > /dev/null
        
        log_success "Sparse checkout completed for paths: ${SPARSE_PATHS[*]}"
    else
        log_info "[DRY RUN] Would sparse checkout paths: ${SPARSE_PATHS[*]}"
    fi
}

strategy_toplevel() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing TOP-LEVEL only strategy"
    
    # Clone with filter, then remove subdirectories
    if [[ "$DRY_RUN" == false ]]; then
        git clone --depth 1 "https://github.com/${repo}.git" "$target_dir"
        find "$target_dir" -mindepth 1 -maxdepth 1 -type d ! -name ".git" -exec rm -rf {} +
    else
        log_info "[DRY RUN] Would clone and keep only top-level files"
    fi
}

strategy_structure() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing STRUCTURE only strategy"
    
    if [[ "$DRY_RUN" == false ]]; then
        git clone --filter=blob:none --depth 1 "https://github.com/${repo}.git" "$target_dir"
        # Remove actual file contents (keep structure)
        find "$target_dir" -type f ! -path "*/.git/*" -exec truncate -s 0 {} \;
    else
        log_info "[DRY RUN] Would clone structure only (empty files)"
    fi
}

strategy_filetype() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing FILE TYPE filter strategy"
    
    if [[ ${#FILE_TYPES[@]} -eq 0 ]]; then
        log_error "File type strategy requires --file-types option"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        git clone --depth 1 "https://github.com/${repo}.git" "$target_dir"
        
        # Build find command to DELETE files NOT matching specified types
        # We need to find files that don't match ANY of the specified extensions
        local find_cmd="find \"$target_dir\" -type f ! -path \"*/.git/*\" \\( "
        local first=true
        for ext in "${FILE_TYPES[@]}"; do
            if [[ "$first" == true ]]; then
                find_cmd+="! -name \"*.$ext\""
                first=false
            else
                find_cmd+=" -a ! -name \"*.$ext\""
            fi
        done
        find_cmd+=" \\) -delete"
        
        log_debug "Executing: $find_cmd"
        eval "$find_cmd"
        
        # Remove empty directories
        find "$target_dir" -type d -empty ! -path "*/.git/*" -delete
        
        log_success "Filtered repository to file types: ${FILE_TYPES[*]}"
    else
        log_info "[DRY RUN] Would filter for file types: ${FILE_TYPES[*]}"
    fi
}

strategy_analysis() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing ANALYSIS optimized strategy"
    
    # Combination of shallow + sparse for quick analysis
    local depth=1
    local sparse_args=""
    
    if [[ ${#SPARSE_PATHS[@]} -gt 0 ]]; then
        sparse_args="--sparse"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        git clone --depth "$depth" --filter=blob:none $sparse_args \
            "https://github.com/${repo}.git" "$target_dir"
        
        if [[ ${#SPARSE_PATHS[@]} -gt 0 ]]; then
            cd "$target_dir"
            git sparse-checkout init --cone
            for path in "${SPARSE_PATHS[@]}"; do
                git sparse-checkout add "$path"
            done
            cd - > /dev/null
        fi
    else
        log_info "[DRY RUN] Would use analysis strategy (shallow + sparse)"
    fi
}

strategy_mirror() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing MIRROR clone strategy"
    
    if [[ "$DRY_RUN" == false ]]; then
        git clone --mirror "https://github.com/${repo}.git" "$target_dir"
    else
        log_info "[DRY RUN] Would create mirror clone"
    fi
}

strategy_bundle() {
    local repo="$1"
    local target_dir="$2"
    
    log_step "Executing BUNDLE creation strategy"
    
    local bundle_file="${target_dir}.bundle"
    
    if [[ "$DRY_RUN" == false ]]; then
        local temp_clone="${target_dir}_temp"
        TEMP_DIRS+=("$temp_clone")
        
        if ! git clone "https://github.com/${repo}.git" "$temp_clone"; then
            log_error "Failed to clone repository for bundling"
            exit 1
        fi
        
        cd "$temp_clone"
        if ! git bundle create "$bundle_file" --all; then
            log_error "Failed to create bundle"
            cd - > /dev/null
            exit 1
        fi
        cd - > /dev/null
        
        # Move bundle to parent directory
        if [[ -f "$temp_clone/$bundle_file" ]]; then
            mv "$temp_clone/$bundle_file" "$bundle_file"
        fi
        
        log_success "Bundle created: $bundle_file"
    else
        log_info "[DRY RUN] Would create git bundle: $bundle_file"
    fi
}

strategy_metadata() {
    local repo="$1"
    
    log_step "Executing METADATA only strategy"
    
    analyze_repo_metadata "$repo"
}

###############################################################################
# Interactive Mode Functions
###############################################################################

#######################################
# Fetch all repositories for a user/org via gh api with pagination.
# Populates the global REPO_JSON variable.
# Arguments:
#   $1 - GitHub username or org name
# Returns:
#   0 on success, 1 on failure
#######################################
fetch_repos() {
    local owner="$1"
    log_step "Fetching repositories for ${owner} ..."

    local endpoint="users/${owner}/repos"
    if [[ "$GH_ORG_MODE" == true ]]; then
        endpoint="orgs/${owner}/repos"
    fi

    # gh api --paginate returns JSON arrays; slurp them together
    REPO_JSON=$(
        gh api "${endpoint}" \
            --paginate \
            -H "Accept: application/vnd.github+json" \
            --jq '.[] | {
                full_name: .full_name,
                name: .name,
                owner: .owner.login,
                description: (.description // ""),
                language: (.language // "n/a"),
                stargazers_count: .stargazers_count,
                forks_count: .forks_count,
                fork: .fork,
                archived: .archived,
                private: .private,
                visibility: .visibility,
                size: .size,
                default_branch: .default_branch,
                updated_at: .updated_at,
                topics: (.topics // []),
                html_url: .html_url,
                ssh_url: .ssh_url,
                clone_url: .clone_url
            }' 2>/dev/null
    ) || true

    # Fallback: try the other endpoint type if first attempt returned nothing
    if [[ -z "$REPO_JSON" ]]; then
        if [[ "$GH_ORG_MODE" == true ]]; then
            endpoint="users/${owner}/repos"
        else
            endpoint="orgs/${owner}/repos"
        fi
        REPO_JSON=$(
            gh api "${endpoint}" \
                --paginate \
                -H "Accept: application/vnd.github+json" \
                --jq '.[] | {
                    full_name: .full_name,
                    name: .name,
                    owner: .owner.login,
                    description: (.description // ""),
                    language: (.language // "n/a"),
                    stargazers_count: .stargazers_count,
                    forks_count: .forks_count,
                    fork: .fork,
                    archived: .archived,
                    private: .private,
                    visibility: .visibility,
                    size: .size,
                    default_branch: .default_branch,
                    updated_at: .updated_at,
                    topics: (.topics // []),
                    html_url: .html_url,
                    ssh_url: .ssh_url,
                    clone_url: .clone_url
                }' 2>/dev/null
        ) || true
    fi

    if [[ -z "$REPO_JSON" ]]; then
        log_error "Could not fetch repositories for '${owner}'."
        log_error "Ensure the username/org exists and you have access."
        return 1
    fi

    # ndjson -> JSON array
    REPO_JSON=$(echo "$REPO_JSON" | jq -s '.')
    FILTERED_JSON="$REPO_JSON"

    local count
    count=$(echo "$REPO_JSON" | jq 'length')
    log_success "Found ${count} repositories"
    return 0
}

#######################################
# Apply all active filters to REPO_JSON and populate FILTERED_REPOS array.
#######################################
apply_filters() {
    local jq_filter='.'

    if [[ -n "$FILTER_LANGUAGE" ]]; then
        jq_filter+=" | map(select(.language | ascii_downcase == (\"${FILTER_LANGUAGE}\" | ascii_downcase)))"
    fi

    if [[ -n "$FILTER_VISIBILITY" && "$FILTER_VISIBILITY" != "all" ]]; then
        if [[ "$FILTER_VISIBILITY" == "public" ]]; then
            jq_filter+=' | map(select(.private == false))'
        elif [[ "$FILTER_VISIBILITY" == "private" ]]; then
            jq_filter+=' | map(select(.private == true))'
        fi
    fi

    if [[ -n "$FILTER_FORK_STATUS" && "$FILTER_FORK_STATUS" != "all" ]]; then
        if [[ "$FILTER_FORK_STATUS" == "true" ]]; then
            jq_filter+=' | map(select(.fork == true))'
        elif [[ "$FILTER_FORK_STATUS" == "false" ]]; then
            jq_filter+=' | map(select(.fork == false))'
        fi
    fi

    if [[ -n "$FILTER_ARCHIVED" && "$FILTER_ARCHIVED" != "all" ]]; then
        if [[ "$FILTER_ARCHIVED" == "true" ]]; then
            jq_filter+=' | map(select(.archived == true))'
        elif [[ "$FILTER_ARCHIVED" == "false" ]]; then
            jq_filter+=' | map(select(.archived == false))'
        fi
    fi

    if [[ -n "$FILTER_NAME_PATTERN" ]]; then
        jq_filter+=" | map(select(.name | test(\"${FILTER_NAME_PATTERN}\"; \"i\")))"
    fi

    if [[ ${#FILTER_TAGS[@]} -gt 0 ]]; then
        # Build JSON array of lowercase tags for jq
        local tags_jq_array="["
        local first_tag=true
        for tag in "${FILTER_TAGS[@]}"; do
            if [[ "$first_tag" == true ]]; then
                first_tag=false
            else
                tags_jq_array+=","
            fi
            tags_jq_array+="\"$(echo "$tag" | tr '[:upper:]' '[:lower:]')\""
        done
        tags_jq_array+="]"

        if [[ "$FILTER_TAG_MODE" == "all" ]]; then
            jq_filter+=" | map(select((.topics // []) | map(ascii_downcase) as \$t | ${tags_jq_array} | all(. as \$tag | \$t | index(\$tag))))"
        else
            jq_filter+=" | map(select((.topics // []) | map(ascii_downcase) as \$t | ${tags_jq_array} | any(. as \$tag | \$t | index(\$tag))))"
        fi
    fi

    if [[ -n "$FILTER_MIN_SIZE" ]]; then
        jq_filter+=" | map(select(.size >= ${FILTER_MIN_SIZE}))"
    fi

    if [[ -n "$FILTER_MAX_SIZE" ]]; then
        jq_filter+=" | map(select(.size <= ${FILTER_MAX_SIZE}))"
    fi

    if [[ -n "$FILTER_UPDATED_AFTER" ]]; then
        jq_filter+=" | map(select(.updated_at >= \"${FILTER_UPDATED_AFTER}\"))"
    fi

    # Apply sort order
    case "$SORT_ORDER" in
        stars)   jq_filter+=' | sort_by(-.stargazers_count)' ;;
        name)    jq_filter+=' | sort_by(.name | ascii_downcase)' ;;
        updated) jq_filter+=' | sort_by(-.updated_at)' ;;
        size)    jq_filter+=' | sort_by(-.size)' ;;
        *)       jq_filter+=' | sort_by(-.stargazers_count)' ;;
    esac

    FILTERED_JSON=$(echo "$REPO_JSON" | jq "$jq_filter")

    FILTERED_REPOS=()
    while IFS= read -r name; do
        [[ -n "$name" ]] && FILTERED_REPOS+=("$name")
    done < <(echo "$FILTERED_JSON" | jq -r '.[].full_name')

    log_info "Filtered to ${#FILTERED_REPOS[@]} repositories"
}

#######################################
# Print a numbered table of filtered repos.
#######################################
display_repos() {
    if [[ ${#FILTERED_REPOS[@]} -eq 0 ]]; then
        log_warning "No repositories match the current filters."
        return
    fi

    echo ""
    printf "${BOLD}%-5s %-40s %-12s %6s %6s %8s %-6s %-8s${NC}\n" \
        "#" "REPOSITORY" "LANGUAGE" "STARS" "FORKS" "SIZE" "FORK?" "ARCHIVE"
    printf "%-5s %-40s %-12s %6s %6s %8s %-6s %-8s\n" \
        "-----" "----------------------------------------" "------------" "------" "------" "--------" "------" "--------"

    local idx=1
    local total_size_kb=0
    echo "$FILTERED_JSON" | jq -r '.[] | [
        .full_name,
        .language,
        (.stargazers_count | tostring),
        (.forks_count | tostring),
        (.size | tostring),
        (if .fork then "yes" else "no" end),
        (if .archived then "yes" else "no" end)
    ] | @tsv' | while IFS=$'\t' read -r name lang stars forks size_kb is_fork is_arch; do
        local display_name="$name"
        if [[ ${#display_name} -gt 38 ]]; then
            display_name="${display_name:0:35}..."
        fi
        # Human-readable size
        local size_display
        if [[ $size_kb -ge 1048576 ]]; then
            size_display="$(echo "scale=1; $size_kb / 1048576" | bc)G"
        elif [[ $size_kb -ge 1024 ]]; then
            size_display="$(echo "scale=1; $size_kb / 1024" | bc)M"
        else
            size_display="${size_kb}K"
        fi
        printf "%-5s %-40s %-12s %6s %6s %8s %-6s %-8s\n" \
            "$idx" "$display_name" "$lang" "$stars" "$forks" "$size_display" "$is_fork" "$is_arch"
        ((idx++))
    done

    # Total estimated size
    total_size_kb=$(echo "$FILTERED_JSON" | jq '[.[].size] | add // 0')
    local total_display
    if [[ $total_size_kb -ge 1048576 ]]; then
        total_display="$(echo "scale=1; $total_size_kb / 1048576" | bc) GB"
    elif [[ $total_size_kb -ge 1024 ]]; then
        total_display="$(echo "scale=1; $total_size_kb / 1024" | bc) MB"
    else
        total_display="${total_size_kb} KB"
    fi
    echo ""
    echo "  Total: ${#FILTERED_REPOS[@]} repositories (~${total_display} estimated)"
    echo "  Sort:  ${SORT_ORDER}"
    echo ""
}

#######################################
# Show active filter summary.
#######################################
show_filter_summary() {
    echo ""
    echo -e "${BOLD}Active Filters:${NC}"
    [[ -n "$FILTER_LANGUAGE" ]]     && echo "  Language:   $FILTER_LANGUAGE"
    [[ -n "$FILTER_VISIBILITY" && "$FILTER_VISIBILITY" != "all" ]] && echo "  Visibility: $FILTER_VISIBILITY"
    [[ -n "$FILTER_FORK_STATUS" && "$FILTER_FORK_STATUS" != "all" ]] && echo "  Forks:      $FILTER_FORK_STATUS"
    [[ -n "$FILTER_ARCHIVED" && "$FILTER_ARCHIVED" != "all" ]]    && echo "  Archived:   $FILTER_ARCHIVED"
    [[ -n "$FILTER_NAME_PATTERN" ]] && echo "  Name match: $FILTER_NAME_PATTERN"
    [[ ${#FILTER_TAGS[@]} -gt 0 ]]   && echo "  Tags:       ${FILTER_TAGS[*]}  (mode: ${FILTER_TAG_MODE})"
    [[ -n "$FILTER_MIN_SIZE" ]]     && echo "  Min size:   ${FILTER_MIN_SIZE} KB"
    [[ -n "$FILTER_MAX_SIZE" ]]     && echo "  Max size:   ${FILTER_MAX_SIZE} KB"
    [[ -n "$FILTER_UPDATED_AFTER" ]] && echo "  Updated >=: $FILTER_UPDATED_AFTER"
    echo "  Sort by:    $SORT_ORDER"

    local has_filter=false
    [[ -n "$FILTER_LANGUAGE" ]] && has_filter=true
    [[ -n "$FILTER_VISIBILITY" && "$FILTER_VISIBILITY" != "all" ]] && has_filter=true
    [[ -n "$FILTER_FORK_STATUS" && "$FILTER_FORK_STATUS" != "all" ]] && has_filter=true
    [[ -n "$FILTER_ARCHIVED" && "$FILTER_ARCHIVED" != "all" ]] && has_filter=true
    [[ -n "$FILTER_NAME_PATTERN" ]] && has_filter=true
    [[ ${#FILTER_TAGS[@]} -gt 0 ]] && has_filter=true
    [[ -n "$FILTER_MIN_SIZE" ]] && has_filter=true
    [[ -n "$FILTER_MAX_SIZE" ]] && has_filter=true
    [[ -n "$FILTER_UPDATED_AFTER" ]] && has_filter=true
    if [[ "$has_filter" == false ]]; then
        echo "  (no filters — showing all repos)"
    fi
    echo ""
}

#######################################
# Prompt for GitHub user/org if not provided via flags.
#######################################
prompt_user() {
    if [[ -n "$GH_USER" ]]; then
        return
    fi

    local current_user
    current_user=$(gh api user --jq '.login' 2>/dev/null || echo "")

    echo ""
    echo -e "${BOLD}Enter a GitHub username or organization to list repos from.${NC}"
    if [[ -n "$current_user" ]]; then
        echo -e "  Press Enter to use your account: ${BOLD}${current_user}${NC}"
    fi
    echo ""
    read -r -p "GitHub user/org: " input_user
    GH_USER="${input_user:-$current_user}"

    if [[ -z "$GH_USER" ]]; then
        log_error "No username provided and could not detect authenticated user."
        exit 2
    fi
}

#######################################
# Interactive filter menu.
#######################################
filter_menu() {
    while true; do
        show_filter_summary

        echo -e "${BOLD}Filter Options:${NC}"
        echo "  1) Filter by language"
        echo "  2) Filter by visibility (public/private)"
        echo "  3) Filter by fork status (original/forked)"
        echo "  4) Filter by archived status"
        echo "  5) Filter by name (regex pattern)"
        echo "  6) Filter by topic"
        echo "  7) Filter by size (min/max KB)"
        echo "  8) Filter by last updated date"
        echo "  9) Change sort order"
        echo ""
        echo "  c) Clear all filters"
        echo "  l) List / show filtered repos"
        echo "  d) Done filtering — proceed to selection"
        echo "  q) Quit"
        echo ""
        read -r -p "Choice: " choice

        case "$choice" in
            1)
                echo ""
                echo -e "${BOLD}Available languages:${NC}"
                echo "$REPO_JSON" | jq -r '[.[].language] | map(select(. != "n/a")) | unique | .[]' 2>/dev/null | sort | head -30
                echo ""
                read -r -p "Language (or blank to clear): " FILTER_LANGUAGE
                apply_filters
                ;;
            2)
                echo ""
                echo "  1) public   2) private   3) all"
                read -r -p "Visibility: " vis_choice
                case "$vis_choice" in
                    1) FILTER_VISIBILITY="public" ;;
                    2) FILTER_VISIBILITY="private" ;;
                    *) FILTER_VISIBILITY="all" ;;
                esac
                apply_filters
                ;;
            3)
                echo ""
                echo "  1) Only original repos   2) Only forks   3) All"
                read -r -p "Fork status: " fork_choice
                case "$fork_choice" in
                    1) FILTER_FORK_STATUS="false" ;;
                    2) FILTER_FORK_STATUS="true" ;;
                    *) FILTER_FORK_STATUS="all" ;;
                esac
                apply_filters
                ;;
            4)
                echo ""
                echo "  1) Only active (not archived)   2) Only archived   3) All"
                read -r -p "Archived status: " arch_choice
                case "$arch_choice" in
                    1) FILTER_ARCHIVED="false" ;;
                    2) FILTER_ARCHIVED="true" ;;
                    *) FILTER_ARCHIVED="all" ;;
                esac
                apply_filters
                ;;
            5)
                echo ""
                read -r -p "Name pattern (regex, blank to clear): " FILTER_NAME_PATTERN
                apply_filters
                ;;
            6)
                echo ""
                echo -e "${BOLD}Available topics:${NC}"
                local available_topics
                available_topics=$(echo "$REPO_JSON" | jq -r '[.[].topics[]] | unique | .[]' 2>/dev/null | sort)
                if [[ -n "$available_topics" ]]; then
                    echo "$available_topics" | head -40
                else
                    echo "  (no topics found on any repos)"
                fi
                echo ""
                if [[ ${#FILTER_TAGS[@]} -gt 0 ]]; then
                    echo -e "  Current tags: ${GREEN}${FILTER_TAGS[*]}${NC}  (mode: ${FILTER_TAG_MODE})"
                    echo ""
                fi
                echo "  Enter comma-separated topics (e.g. python,web,cli)"
                echo "  Leave blank to clear tag filter."
                read -r -p "Tags: " tag_input
                if [[ -z "$tag_input" ]]; then
                    FILTER_TAGS=()
                    log_info "Tag filter cleared."
                else
                    FILTER_TAGS=()
                    IFS=',' read -ra tag_parts <<< "$tag_input"
                    for t in "${tag_parts[@]}"; do
                        # Trim whitespace
                        t="$(echo "$t" | xargs)"
                        [[ -n "$t" ]] && FILTER_TAGS+=("$t")
                    done
                    echo ""
                    echo "  Match mode:"
                    echo "    1) any — repo has at least one of these tags (default)"
                    echo "    2) all — repo must have ALL specified tags"
                    read -r -p "  Mode [1]: " mode_choice
                    case "$mode_choice" in
                        2) FILTER_TAG_MODE="all" ;;
                        *) FILTER_TAG_MODE="any" ;;
                    esac
                    log_info "Filtering by tags: ${FILTER_TAGS[*]} (mode: ${FILTER_TAG_MODE})"
                fi
                apply_filters
                ;;
            7)
                echo ""
                read -r -p "Min size in KB (blank to clear): " FILTER_MIN_SIZE
                read -r -p "Max size in KB (blank to clear): " FILTER_MAX_SIZE
                apply_filters
                ;;
            8)
                echo ""
                echo "  Enter a date in YYYY-MM-DD format."
                echo "  Only repos updated on or after this date will be shown."
                read -r -p "Updated after (blank to clear): " FILTER_UPDATED_AFTER
                apply_filters
                ;;
            9)
                echo ""
                echo "  1) stars    — most stars first (default)"
                echo "  2) name     — alphabetical"
                echo "  3) updated  — most recently updated first"
                echo "  4) size     — largest first"
                read -r -p "Sort by [1]: " sort_choice
                case "$sort_choice" in
                    2) SORT_ORDER="name" ;;
                    3) SORT_ORDER="updated" ;;
                    4) SORT_ORDER="size" ;;
                    *) SORT_ORDER="stars" ;;
                esac
                apply_filters
                ;;
            c|C)
                FILTER_LANGUAGE=""
                FILTER_VISIBILITY=""
                FILTER_FORK_STATUS=""
                FILTER_ARCHIVED=""
                FILTER_NAME_PATTERN=""
                FILTER_TAGS=()
                FILTER_TAG_MODE="any"
                FILTER_MIN_SIZE=""
                FILTER_MAX_SIZE=""
                FILTER_UPDATED_AFTER=""
                SORT_ORDER="stars"
                apply_filters
                log_info "All filters cleared."
                ;;
            l|L)
                display_repos
                ;;
            d|D)
                break
                ;;
            q|Q)
                echo "Goodbye."
                exit 0
                ;;
            *)
                log_warning "Invalid choice."
                ;;
        esac
    done
}

#######################################
# Interactive repo selection.
# Users pick repos by number, range, or "all".
#######################################
select_repos() {
    if [[ ${#FILTERED_REPOS[@]} -eq 0 ]]; then
        log_warning "No repos to select. Adjust your filters."
        return 1
    fi

    display_repos

    echo -e "${BOLD}Select repositories to clone:${NC}"
    echo "  Enter numbers separated by spaces, commas, or ranges (e.g. 1 3 5-10)"
    echo -e "  Type ${GREEN}all${NC} to select everything, or ${RED}none${NC} to cancel."
    echo ""
    read -r -p "Selection: " selection

    SELECTED_REPOS=()

    if [[ "${selection,,}" == "all" ]]; then
        SELECTED_REPOS=("${FILTERED_REPOS[@]}")
        log_info "Selected all ${#SELECTED_REPOS[@]} repositories."
        return 0
    fi

    if [[ "${selection,,}" == "none" || -z "$selection" ]]; then
        log_info "No repos selected."
        return 1
    fi

    # Parse: support "1 3 5-10, 12"
    selection="${selection//,/ }"

    for token in $selection; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local range_start="${BASH_REMATCH[1]}"
            local range_end="${BASH_REMATCH[2]}"
            for ((i=range_start; i<=range_end; i++)); do
                local idx=$((i - 1))
                if [[ $idx -ge 0 && $idx -lt ${#FILTERED_REPOS[@]} ]]; then
                    SELECTED_REPOS+=("${FILTERED_REPOS[$idx]}")
                else
                    log_warning "Index $i is out of range (1-${#FILTERED_REPOS[@]})"
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            local idx=$((token - 1))
            if [[ $idx -ge 0 && $idx -lt ${#FILTERED_REPOS[@]} ]]; then
                SELECTED_REPOS+=("${FILTERED_REPOS[$idx]}")
            else
                log_warning "Index $token is out of range (1-${#FILTERED_REPOS[@]})"
            fi
        else
            log_warning "Ignoring invalid token: $token"
        fi
    done

    # Deduplicate
    local -A seen
    local unique=()
    for repo in "${SELECTED_REPOS[@]}"; do
        if [[ -z "${seen[$repo]:-}" ]]; then
            seen["$repo"]=1
            unique+=("$repo")
        fi
    done
    SELECTED_REPOS=("${unique[@]}")

    log_info "Selected ${#SELECTED_REPOS[@]} repositories."
    return 0
}

#######################################
# Prompt for clone settings (strategy, target dir, etc.)
#######################################
configure_clone() {
    echo ""
    echo -e "${BOLD}Clone Configuration${NC}"
    echo ""

    # Target directory
    read -r -p "Target directory [${INTERACTIVE_TARGET}]: " input_dir
    INTERACTIVE_TARGET="${input_dir:-$INTERACTIVE_TARGET}"

    # Strategy
    echo ""
    echo "Clone strategy:"
    echo "  1) shallow  — depth-1 clone, fast (default)"
    echo "  2) full     — complete history"
    echo "  3) mirror   — bare mirror clone (for backup)"
    echo ""
    read -r -p "Strategy [1]: " strat_choice
    case "$strat_choice" in
        2) FORK_STRATEGY="full" ;;
        3) FORK_STRATEGY="mirror" ;;
        *) FORK_STRATEGY="shallow" ;;
    esac

    if [[ "$FORK_STRATEGY" == "shallow" ]]; then
        local depth_default="${CLONE_DEPTH:-1}"
        read -r -p "Clone depth [${depth_default}]: " input_depth
        CLONE_DEPTH="${input_depth:-$depth_default}"
    fi

    # Fork or clone only
    echo ""
    read -r -p "Create GitHub forks? (y/n) [n]: " fork_choice
    case "${fork_choice,,}" in
        y|yes) CREATE_FORK=true ;;
        *)     CREATE_FORK=false ;;
    esac

    # Show estimated disk usage for selected repos
    if [[ ${#SELECTED_REPOS[@]} -gt 0 ]]; then
        local est_size_kb=0
        for sel_repo in "${SELECTED_REPOS[@]}"; do
            local repo_size
            repo_size=$(echo "$FILTERED_JSON" | jq -r --arg r "$sel_repo" '.[] | select(.full_name == $r) | .size' 2>/dev/null || echo "0")
            est_size_kb=$((est_size_kb + ${repo_size:-0}))
        done
        local est_display
        if [[ $est_size_kb -ge 1048576 ]]; then
            est_display="$(echo "scale=1; $est_size_kb / 1048576" | bc) GB"
        elif [[ $est_size_kb -ge 1024 ]]; then
            est_display="$(echo "scale=1; $est_size_kb / 1024" | bc) MB"
        else
            est_display="${est_size_kb} KB"
        fi
        echo ""
        echo -e "  ${BOLD}Estimated total size: ~${est_display}${NC}"
    fi
}

#######################################
# Clone a single repository for interactive batch mode.
# Arguments:
#   $1 - owner/repo (e.g. "bamr87/it-journey")
#   $2 - target directory base
# Returns:
#   0 on success, 1 on failure
#######################################
clone_single_repo() {
    local repo="$1"
    local base_dir="$2"
    local repo_name="${repo##*/}"
    local clone_dir="${base_dir}/${repo_name}"

    # Skip if directory already exists
    if [[ -d "$clone_dir" ]]; then
        log_warning "Skipping ${repo} — directory already exists: ${clone_dir}"
        return 0
    fi

    local clone_url="https://github.com/${repo}.git"

    # Fork if requested
    if [[ "$CREATE_FORK" == true ]]; then
        local my_user
        my_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
        if [[ -n "$my_user" ]]; then
            local owner="${repo%%/*}"
            if [[ "$owner" != "$my_user" ]]; then
                if [[ "$DRY_RUN" == false ]]; then
                    if gh repo view "${my_user}/${repo_name}" &>/dev/null 2>&1; then
                        log_debug "Fork already exists: ${my_user}/${repo_name}"
                        clone_url="https://github.com/${my_user}/${repo_name}.git"
                    else
                        log_debug "Forking ${repo} ..."
                        if gh repo fork "$repo" --clone=false 2>/dev/null; then
                            clone_url="https://github.com/${my_user}/${repo_name}.git"
                            log_debug "Forked: ${my_user}/${repo_name}"
                        else
                            log_warning "Fork failed for ${repo}, cloning original."
                        fi
                    fi
                else
                    log_info "[DRY RUN] Would fork: ${repo}"
                fi
            fi
        fi
    fi

    # Clone
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would clone ${repo} -> ${clone_dir}  (strategy: ${FORK_STRATEGY})"
        return 0
    fi

    case "$FORK_STRATEGY" in
        shallow)
            git clone --depth "${CLONE_DEPTH:-1}" "$clone_url" "$clone_dir" 2>/dev/null
            ;;
        full)
            git clone "$clone_url" "$clone_dir" 2>/dev/null
            ;;
        mirror)
            git clone --mirror "$clone_url" "$clone_dir" 2>/dev/null
            ;;
        *)
            git clone --depth 1 "$clone_url" "$clone_dir" 2>/dev/null
            ;;
    esac
}

#######################################
# Execute batch clone of all selected repos with progress.
#######################################
batch_clone() {
    local total=${#SELECTED_REPOS[@]}
    if [[ $total -eq 0 ]]; then
        log_warning "Nothing to clone."
        return
    fi

    # Create target directory
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$INTERACTIVE_TARGET"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                     CLONE SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Repos:     ${total}"
    echo "  Strategy:  ${FORK_STRATEGY}"
    [[ "$FORK_STRATEGY" == "shallow" ]] && echo "  Depth:     ${CLONE_DEPTH:-1}"
    echo "  Target:    ${INTERACTIVE_TARGET}"
    echo "  Fork:      ${CREATE_FORK}"
    echo "  Dry Run:   ${DRY_RUN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    for repo in "${SELECTED_REPOS[@]}"; do
        echo "  - $repo"
    done
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        read -r -p "Proceed? (y/n) [y]: " confirm
        case "${confirm,,}" in
            n|no) log_info "Aborted."; return ;;
        esac
    fi

    echo ""
    local current=0
    local succeeded=0
    local failed=0

    for repo in "${SELECTED_REPOS[@]}"; do
        ((current++))
        local pct=$((current * 100 / total))
        printf "\r[%3d%%] (%d/%d) Cloning %-50s" "$pct" "$current" "$total" "$repo"

        if clone_single_repo "$repo" "$INTERACTIVE_TARGET"; then
            ((succeeded++))
        else
            ((failed++))
            log_error "Failed to clone: ${repo}"
        fi
    done

    echo ""
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                       RESULTS"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "  ${GREEN}Succeeded:${NC}  ${succeeded}"
    echo -e "  ${RED}Failed:${NC}     ${failed}"
    echo -e "  Total:      ${total}"
    echo "  Location:   ${INTERACTIVE_TARGET}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

#######################################
# Run the full interactive workflow.
#######################################
run_interactive() {
    # Step 1: Get user/org
    prompt_user

    # Step 2: Fetch repos
    fetch_repos "$GH_USER" || exit 1

    # Step 3: Initial display
    apply_filters
    display_repos

    # Quick clone-all mode: skip interactive menus
    if [[ "$CLONE_ALL" == true ]]; then
        SELECTED_REPOS=("${FILTERED_REPOS[@]}")
        log_info "Clone-all mode: selected all ${#SELECTED_REPOS[@]} repos."

        # Use sensible defaults if not already configured
        if [[ -z "$CLONE_DEPTH" ]]; then
            CLONE_DEPTH=1
            FORK_STRATEGY="shallow"
        fi

        batch_clone
        log_success "Clone-all completed!"
        return
    fi

    # Interactive loop: filter -> select -> configure -> clone
    while true; do
        echo ""
        echo -e "${BOLD}What would you like to do?${NC}"
        echo "  1) Filter repos"
        echo "  2) Select repos & clone"
        echo "  3) Clone ALL filtered repos (${#FILTERED_REPOS[@]})"
        echo "  4) Show repo list"
        echo "  q) Quit"
        echo ""
        read -r -p "Choice: " main_choice

        case "$main_choice" in
            1)
                filter_menu
                display_repos
                ;;
            2)
                if ! select_repos; then
                    log_info "No repos selected. Try again or quit."
                    continue
                fi
                configure_clone
                batch_clone
                echo ""
                echo -e "${BOLD}Clone another batch? (y/n) [n]:${NC}"
                read -r -p "> " again
                if [[ "${again,,}" != "y" && "${again,,}" != "yes" ]]; then
                    break
                fi
                ;;
            3)
                SELECTED_REPOS=("${FILTERED_REPOS[@]}")
                log_info "Selected all ${#SELECTED_REPOS[@]} filtered repos."
                configure_clone
                batch_clone
                break
                ;;
            4)
                display_repos
                ;;
            q|Q)
                echo "Goodbye."
                exit 0
                ;;
            *)
                log_warning "Invalid choice."
                ;;
        esac
    done

    log_success "Interactive clone completed!"
}

###############################################################################
# Main Execution Logic
###############################################################################

execute_fork() {
    local repo_url="$1"
    local repo
    repo=$(parse_repo_url "$repo_url")
    
    log_info "Repository: $repo"
    log_info "Strategy: $FORK_STRATEGY"
    
    # Validate inputs
    if [[ ${#SPARSE_PATHS[@]} -gt 0 ]]; then
        validate_sparse_paths
    fi
    
    if [[ ${#FILE_TYPES[@]} -gt 0 ]]; then
        validate_file_types
    fi
    
    # Create working directory
    if [[ "$DRY_RUN" == false ]] && [[ ! -d "$WORK_DIR" ]]; then
        mkdir -p "$WORK_DIR"
    fi
    
    # Determine target directory
    if [[ -z "$TARGET_DIR" ]]; then
        local repo_name=$(echo "$repo" | cut -d'/' -f2)
        TARGET_DIR="${WORK_DIR}/${repo_name}"
    fi
    
    log_debug "Target directory: $TARGET_DIR"
    
    # Validate target directory
    validate_target_dir "$TARGET_DIR"
    
    # Execute strategy
    case "$FORK_STRATEGY" in
        full)
            strategy_full "$repo" "$TARGET_DIR"
            ;;
        shallow)
            strategy_shallow "$repo" "$TARGET_DIR"
            ;;
        sparse)
            strategy_sparse "$repo" "$TARGET_DIR"
            ;;
        toplevel)
            strategy_toplevel "$repo" "$TARGET_DIR"
            ;;
        structure)
            strategy_structure "$repo" "$TARGET_DIR"
            ;;
        filetype)
            strategy_filetype "$repo" "$TARGET_DIR"
            ;;
        analysis)
            strategy_analysis "$repo" "$TARGET_DIR"
            ;;
        mirror)
            strategy_mirror "$repo" "$TARGET_DIR"
            ;;
        bundle)
            strategy_bundle "$repo" "$TARGET_DIR"
            ;;
        metadata)
            strategy_metadata "$repo"
            return
            ;;
        *)
            log_error "Unknown strategy: $FORK_STRATEGY"
            exit 1
            ;;
    esac
    
    # Post-clone analysis
    if [[ "$ANALYZE_ONLY" == false ]] && [[ -d "$TARGET_DIR" ]]; then
        log_success "Repository processed successfully"
        echo ""
        echo "Location: $TARGET_DIR"
        
        if [[ -d "$TARGET_DIR/.git" ]]; then
            cd "$TARGET_DIR"
            echo "Branch: $(git branch --show-current)"
            echo "Commits: $(git rev-list --count HEAD)"
            cd - > /dev/null
        fi
        
        # Optional structure analysis
        analyze_repo_structure "$TARGET_DIR"
    fi
}

###############################################################################
# Argument Parsing
###############################################################################

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --strategy)
                FORK_STRATEGY="$2"
                shift 2
                ;;
            --depth)
                CLONE_DEPTH="$2"
                shift 2
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --no-fork)
                CREATE_FORK=false
                shift
                ;;
            --target)
                TARGET_DIR="$2"
                shift 2
                ;;
            --work-dir)
                WORK_DIR="$2"
                shift 2
                ;;
            --file-types)
                IFS=',' read -ra FILE_TYPES <<< "$2"
                shift 2
                ;;
            --include)
                INCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --exclude)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --sparse-paths)
                IFS=',' read -ra SPARSE_PATHS <<< "$2"
                shift 2
                ;;
            --analyze)
                # Analyze after cloning
                shift
                ;;
            --analyze-only)
                ANALYZE_ONLY=true
                FORK_STRATEGY="metadata"
                shift
                ;;
            --stats)
                # Show statistics
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
            --clone-all)
                CLONE_ALL=true
                INTERACTIVE=true
                shift
                ;;
            --tags)
                IFS=',' read -ra FILTER_TAGS <<< "$2"
                # Trim whitespace from each tag
                local trimmed_tags=()
                for t in "${FILTER_TAGS[@]}"; do
                    t="$(echo "$t" | xargs)"
                    [[ -n "$t" ]] && trimmed_tags+=("$t")
                done
                FILTER_TAGS=("${trimmed_tags[@]}")
                INTERACTIVE=true
                shift 2
                ;;
            --tag-mode)
                FILTER_TAG_MODE="$2"
                if [[ "$FILTER_TAG_MODE" != "any" && "$FILTER_TAG_MODE" != "all" ]]; then
                    log_error "Invalid tag mode: $FILTER_TAG_MODE (must be 'any' or 'all')"
                    exit 2
                fi
                shift 2
                ;;
            --fork)
                CREATE_FORK=true
                shift
                ;;
            --user)
                GH_USER="$2"
                shift 2
                ;;
            --org)
                GH_USER="$2"
                GH_ORG_MODE=true
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            --version|-v)
                echo "ForkMe version $VERSION"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                # This should be the repository URL
                REPO_URL="$1"
                shift
                ;;
        esac
    done

    # In interactive mode, REPO_URL is not required
    if [[ "$INTERACTIVE" == false && -z "${REPO_URL:-}" ]]; then
        log_error "Repository URL is required (or use --interactive / -i mode)"
        echo ""
        show_usage
        exit 1
    fi

    # Sync --target with INTERACTIVE_TARGET for interactive mode
    if [[ -n "$TARGET_DIR" && "$INTERACTIVE" == true ]]; then
        INTERACTIVE_TARGET="$TARGET_DIR"
    fi
}

###############################################################################
# Main Entry Point
###############################################################################

main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "       🍴 ForkMe - Advanced Repository Forking Utility 🍴"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    parse_arguments "$@"
    
    check_dependencies
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    if [[ "$INTERACTIVE" == true ]]; then
        run_interactive
    else
        execute_fork "$REPO_URL"
    fi
    
    echo ""
    log_success "ForkMe operation completed"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Run main function
main "$@"
