#!/usr/bin/env bash

# Set GitHub user from environment variable or fallback to system user
set -euo pipefail

# --- helpers and defaults
GITHUB_USER="${GITHUB_USER:-$USER}"
DEFAULT_BRANCH="main"
DRY_RUN=false
MODE="interactive"
REPO_NAME=""
REPO_DESC=""
VISIBILITY="public"
LICENSE="MIT"
GITIGNORE=""
SCAFFOLD="none"
TEMPLATE=""
FORCE_NO_PUSH=false
GH_CLI_AVAILABLE=false
BASE_DIR="${BASE_DIR:-$HOME/github}"

# Ensure required tools are available
if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is not installed or not on PATH." >&2
        exit 1
fi

# Check for gh availability
if command -v gh >/dev/null 2>&1; then
        GH_CLI_AVAILABLE=true
fi

usage() {
        cat <<EOF
Usage: $(basename "$0") [options]

Options:
    -n, --name NAME           Repository name (required in headless mode)
    -u, --user USER           GitHub user/organization to use (defaults to USER or GITHUB_USER)
    -d, --desc DESCRIPTION    Description for the repo
    -p, --private             Create private repository (default: public)
        --path DIR            Base directory for repositories (default: \$HOME/github)
    --license LICENSE         License type (MIT, Apache-2.0, None)
    --gitignore TYPES         comma separated types for .gitignore (e.g., python,macos)
    --scaffold TYPE           Basic scaffold type: none | jekyll | python | node | minimal
    -t, --template OWNER/REPO Create repo from a GitHub template (requires gh)
    --headless                Headless mode (don't ask interactive prompts)
    --no-push                 Do not push to remote (local only)
    -h, --help                Show this help and exit

Example:
    $(basename "$0") --headless -n myrepo -u myuser -d "My demo repo" --gitignore python,macos --scaffold python
EOF
        exit 1
}

parse_args() {
    while (( "$#" )); do
        case "$1" in
            -n|--name)
                REPO_NAME="$2" && shift 2 || usage
                ;;
            -u|--user)
                GITHUB_USER="$2" && shift 2 || usage
                ;;
            -d|--desc)
                REPO_DESC="$2" && shift 2 || usage
                ;;
            -p|--private)
                VISIBILITY="private" && shift
                ;;
            --path)
                BASE_DIR="$2" && shift 2 || usage
                ;;
            --license)
                LICENSE="$2" && shift 2 || usage
                ;;
            --gitignore)
                GITIGNORE="$2" && shift 2 || usage
                ;;
            --scaffold)
                SCAFFOLD="$2" && shift 2 || usage
                ;;
            -t|--template)
                TEMPLATE="$2" && shift 2 || usage
                ;;
            --headless)
                MODE="headless" && shift
                ;;
            --no-push)
                FORCE_NO_PUSH=true && shift
                ;;
            --dry-run)
                DRY_RUN=true && shift
                ;;
            -h|--help)
                usage
                ;;
            --) shift; break;;
            -*|--*=)
                echo "Unknown option: $1" >&2
                usage
                ;;
            *)
                # positional argument, maybe repo name
                if [ -z "$REPO_NAME" ]; then REPO_NAME="$1"; else echo "Ignoring extra param: $1"; fi
                shift
                ;;
        esac
    done
}

parse_args "$@"

# If running non-interactively and no repo name, fail
if [ "$MODE" = "headless" ] && [ -z "$REPO_NAME" ]; then
    echo "Error: --headless provided but no repo name. Use -n|--name to set a repository name." >&2
    exit 1
fi

# Validate GitHub user is set
if [ -z "$GITHUB_USER" ]; then
    echo "Error: GITHUB_USER environment variable is not set and USER is not available." >&2
    echo "Please set GITHUB_USER environment variable: export GITHUB_USER=your_github_username" >&2
    exit 1
fi

# Dry-run helper and interactive prompts
run_or_echo() {
    if [ "$DRY_RUN" = true ]; then
        echo "DRYRUN: $*"
    else
        eval "$@"
    fi
}

# Interactive prompts (if interactive)
if [ "$MODE" != "headless" ]; then
    echo "Using GitHub user: $GITHUB_USER"
fi

if [ -z "$REPO_NAME" ]; then
    read -p "Enter the folder name for the GitHub repo: " REPO_NAME
fi

# Validate input
if [ -z "$REPO_NAME" ]; then
    echo "Error: Repository name cannot be empty." >&2
    exit 1
fi

# NOTE: REPO_PATH assigned below after validation

REPO_PATH="$BASE_DIR/$REPO_NAME"
echo "Repo path will be: $REPO_PATH"
REMOTE_URL="git@github.com:$GITHUB_USER/$REPO_NAME.git"
if [ "$MODE" != "headless" ]; then
    echo "Using remote URL: $REMOTE_URL"
fi

# Check for existing non-empty directory to avoid accidental overwrite
if [ -d "$REPO_PATH" ] && [ -n "$(ls -A "$REPO_PATH" 2>/dev/null || echo)" ]; then
    if [ "$MODE" = "headless" ]; then
        echo "Error: Target directory '$REPO_PATH' already exists and is not empty. Aborting to avoid overwriting." >&2
        exit 1
    else
        read -p "Directory '$REPO_PATH' exists and is not empty. Continue and use this directory? (y/N): " CONTINUE_EXISTING
        if ! [[ "$CONTINUE_EXISTING" =~ ^[Yy]$ ]]; then
            echo "Aborting at user request."
            exit 1
        fi
    fi
fi

# Prompt for confirmation or allow override
if [ "$MODE" != "headless" ]; then
    read -p "Use this URL? (y/n) or enter custom URL: " CONFIRM_URL
    if [[ "$CONFIRM_URL" =~ ^[Yy]$ ]] || [ -z "$CONFIRM_URL" ]; then
        echo "Using constructed URL: $REMOTE_URL"
    elif [[ "$CONFIRM_URL" =~ ^[Nn]$ ]]; then
        read -p "Enter the GitHub repository URL: " REMOTE_URL
    else
        REMOTE_URL="$CONFIRM_URL"
    fi
fi

# Add remote and push

# create folder structure
run_or_echo "mkdir -p \"$REPO_PATH\""
if [ "$DRY_RUN" = true ]; then
    echo "DRYRUN: Would change directory to $REPO_PATH"
else
    cd "$REPO_PATH" || { echo "Failed to access directory."; exit 1; }
fi

# Initialize Git and create README if not present
if [ ! -d .git ]; then
    run_or_echo "git init"
fi

if [ ! -f README.md ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "DRYRUN: Would create README.md"
        if [ -n "$REPO_DESC" ]; then
            echo "DRYRUN: README.md would include description"
        fi
    else
        if [ -n "$REPO_DESC" ]; then
            {
                echo "# $REPO_NAME"
                echo
                echo "$REPO_DESC"
            } > README.md
        else
            echo "# $REPO_NAME" > README.md
        fi
    fi
fi

# scaffold files
scaffold_repo() {
    local type="$1"
    echo "Creating scaffold: $type"
    case "$type" in
        jekyll)
            run_or_echo "mkdir -p _posts _layouts assets css js"
            if [ "$DRY_RUN" = true ]; then
                echo "DRYRUN: Would create _posts/0000-00-00-welcome.md"
            else
                echo "title: 'Welcome'" > _posts/0000-00-00-welcome.md || true
            fi
            ;;
        python)
            run_or_echo "mkdir -p src tests docs scripts"
            if [ "$DRY_RUN" = true ]; then
                echo "DRYRUN: Would create src/__init__.py"
            else
                echo "# $REPO_NAME" > src/__init__.py
            fi
            ;;
        node)
            run_or_echo "mkdir -p src tests public"
            if [ "$DRY_RUN" = true ]; then
                echo "DRYRUN: Would create package.json"
            else
                echo "{}" > package.json
            fi
            ;;
        minimal)
            run_or_echo "mkdir -p docs scripts"
            ;;
        none)
            ;;
        *)
            echo "Unknown scaffold type: $type";
            ;;
    esac
}

create_local_license() {
    : > LICENSE
    case "$LICENSE" in
        MIT)
            cat > LICENSE <<EOF
MIT License

Copyright (c) $(date +%Y) $GITHUB_USER

Permission is hereby granted, free of charge...
EOF
            ;;
        Apache-2.0)
            cat > LICENSE <<'EOF'
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/
EOF
            ;;
        *)
            echo "License $LICENSE not supported by CLI fallback, creating empty LICENSE file"
            : > LICENSE
            ;;
    esac
}

if [ "$SCAFFOLD" != "none" ]; then
    scaffold_repo "$SCAFFOLD"
fi

# generate .gitignore using gitignore.io API if requested
if [ -n "$GITIGNORE" ]; then
    if command -v curl >/dev/null 2>&1; then
        echo "Generating .gitignore for: $GITIGNORE"
        if [ "$DRY_RUN" = true ]; then
            echo "DRYRUN: Would call https://www.toptal.com/developers/gitignore/api/$(echo "$GITIGNORE" | sed 's/,/%2C/g')"
        else
            curl -sL "https://www.toptal.com/developers/gitignore/api/$(echo "$GITIGNORE" | sed 's/,/%2C/g')" -o .gitignore || true
        fi
    else
        echo "curl not available, skipping .gitignore generation"
    fi
fi

# license creation (fallback if gh not available)
if [ "$LICENSE" != "None" ] && [ "$LICENSE" != "none" ]; then
    if $GH_CLI_AVAILABLE; then
        # Try using GitHub CLI to create a license in repo via template -- requires remote to exist
        echo "Creating license via gh (MIT or Apache-2.0 supported)"
        if [ "$DRY_RUN" = true ]; then
            echo "DRYRUN: Would attempt gh api -X PUT /repos/$GITHUB_USER/$REPO_NAME/license"
        else
            if ! gh api -X PUT "/repos/$GITHUB_USER/$REPO_NAME/license" >/dev/null 2>&1; then
                echo "gh license creation failed; falling back to local LICENSE file"
                create_local_license
            fi
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            echo "DRYRUN: Would generate a local LICENSE file"
        else
            echo "gh not found; generating a simple license file"
            create_local_license
        fi
    fi
fi

# If a GitHub template is requested use GH CLI or degit (if installed)
if [ -n "$TEMPLATE" ]; then
        if $GH_CLI_AVAILABLE; then
        echo "Creating repo from template $TEMPLATE using gh"
        # create repo from template on GitHub then clone via gh
            if [ "$DRY_RUN" = true ]; then
                echo "DRYRUN: Would run gh repo create $GITHUB_USER/$REPO_NAME --template $TEMPLATE --$VISIBILITY --confirm"
            else
                gh repo create "$GITHUB_USER/$REPO_NAME" --template "$TEMPLATE" --${VISIBILITY} --confirm || true
            fi
        # ensure remote is configured if not already
        if ! git remote get-url origin >/dev/null 2>&1; then
            run_or_echo "git remote add origin git@github.com:$GITHUB_USER/$REPO_NAME.git"
        fi
    elif command -v npx >/dev/null 2>&1; then
        echo "Creating scaffold from template via degit"
        if [ "$DRY_RUN" = true ]; then
            echo "DRYRUN: Would run npx degit $TEMPLATE"
        else
            npx degit "$TEMPLATE" . || true
        fi
    else
        echo "No method available to fetch template. Install gh or npx degit and retry." >&2
    fi
fi

# Ensure initial commit includes all created files when repository is new
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    if [ "$DRY_RUN" = true ]; then
        echo "DRYRUN: Would stage all files and create initial commit"
    else
        run_or_echo "git add ."
        # Don't let an empty tree fail the script
        run_or_echo "git commit -m 'Initial commit' || true"
    fi
fi

# Set remote, branch, and push
if [ "$MODE" = "headless" ]; then
    # If gh available, try to create the remote repo non-interactively
    if $GH_CLI_AVAILABLE; then
        echo "Creating remote repo using gh CLI"
        if [ "$DRY_RUN" = true ]; then
            echo "DRYRUN: Would run gh repo create $GITHUB_USER/$REPO_NAME --$VISIBILITY --description '$REPO_DESC' --source=. --remote=origin --confirm"
        elif ! gh repo create "$GITHUB_USER/$REPO_NAME" --$VISIBILITY --description "$REPO_DESC" --source=. --remote=origin --confirm 2>/dev/null; then
            echo "gh CLI create failed or repo already exists. We'll add remote URL if not set." >&2
            git remote add origin "$REMOTE_URL" 2>/dev/null || true
        fi
    else
        git remote add origin "$REMOTE_URL" 2>/dev/null || true
    fi
fi

git branch -M "$DEFAULT_BRANCH" || true
if [ "$FORCE_NO_PUSH" = false ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "DRYRUN: Would push branch $DEFAULT_BRANCH to origin"
    else
        git push -u origin "$DEFAULT_BRANCH" || echo "Push failed (remote might not exist or require auth)"
    fi
else
    echo "Skipping push per --no-push"
fi

echo "Repository initialized."
echo "Location: $REPO_PATH"
echo "Remote URL: $REMOTE_URL"