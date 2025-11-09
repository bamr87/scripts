#!/bin/bash

###############################################################################
# File: forkme.sh
# Description: Advanced GitHub repository forking and cloning utility with 
#              multiple strategies for analysis, review, testing, and research
# Author: IT-Journey Scripts Team
# Created: 2025-11-01
# Last Modified: 2025-11-01
# Version: 1.0.0
#
# Dependencies:
# - gh (GitHub CLI)
# - git
# - jq (for JSON parsing)
# - find, grep, sed (standard Unix tools)
#
# Usage: ./forkme.sh [options] <repository-url>
# Example: ./forkme.sh --strategy shallow --depth 1 https://github.com/user/repo
###############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
FORK_STRATEGY="full"
CLONE_DEPTH=""
TARGET_DIR=""
FILE_TYPES=()
INCLUDE_PATTERNS=()
EXCLUDE_PATTERNS=()
DRY_RUN=false
VERBOSE=false
CREATE_FORK=true
BRANCH=""
SPARSE_CHECKOUT=false
SPARSE_PATHS=()
ANALYZE_ONLY=false
SKIP_FORK=false
WORK_DIR="$(pwd)/forkme-workspace"

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

${YELLOW}CONTROL OPTIONS:${NC}
    ${CYAN}--dry-run${NC}           - Show what would be done without executing
    ${CYAN}--verbose${NC}           - Enable verbose output
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
            gh repo fork "$repo" --clone=false
            local forked_repo
            forked_repo=$(gh api user | jq -r '.login')
            repo="$forked_repo/$(echo "$repo" | cut -d'/' -f2)"
        fi
    fi
    
    log_info "Cloning repository with full history..."
    if [[ "$DRY_RUN" == false ]]; then
        git clone "https://github.com/${repo}.git" "$target_dir"
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
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        git clone --depth "$depth" $branch_arg "https://github.com/${repo}.git" "$target_dir"
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
        git clone --filter=blob:none --sparse "https://github.com/${repo}.git" "$target_dir"
        cd "$target_dir"
        git sparse-checkout init --cone
        for path in "${SPARSE_PATHS[@]}"; do
            log_debug "Adding sparse path: $path"
            git sparse-checkout add "$path"
        done
        cd - > /dev/null
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
        
        # Build find command to keep only specified file types
        local find_cmd="find \"$target_dir\" -type f ! -path \"*/.git/*\""
        local first=true
        for ext in "${FILE_TYPES[@]}"; do
            if [[ "$first" == true ]]; then
                find_cmd+=" ! -name \"*.$ext\""
                first=false
            else
                find_cmd+=" ! -name \"*.$ext\""
            fi
        done
        find_cmd+=" -delete"
        
        eval "$find_cmd"
        
        # Remove empty directories
        find "$target_dir" -type d -empty ! -path "*/.git/*" -delete
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
        git clone "https://github.com/${repo}.git" "$temp_clone"
        cd "$temp_clone"
        git bundle create "$bundle_file" --all
        cd - > /dev/null
        rm -rf "$temp_clone"
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
# Main Execution Logic
###############################################################################

execute_fork() {
    local repo_url="$1"
    local repo
    repo=$(parse_repo_url "$repo_url")
    
    log_info "Repository: $repo"
    log_info "Strategy: $FORK_STRATEGY"
    
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
            --help|-h)
                show_usage
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

    if [[ -z "${REPO_URL:-}" ]]; then
        log_error "Repository URL is required"
        echo ""
        show_usage
        exit 1
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
    
    execute_fork "$REPO_URL"
    
    echo ""
    log_success "ForkMe operation completed"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Run main function
main "$@"
