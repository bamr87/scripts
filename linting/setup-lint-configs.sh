#!/bin/bash
#
# @file scripts/linting/setup-lint-configs.sh
# @description Unified lint configuration setup across IT-Journey repositories
# @author IT-Journey Team <team@it-journey.org>
# @created 2025-08-03
# @version 1.0.0
#
# Path: Repository Setup → Lint Configuration → Consistency Enforcement

set -euo pipefail

# Define the main execution path
main() {
    echo "🔧 Setting up lint configurations across repositories..."
    
    # Path segment: Discovery
    discover_repositories || return 1
    
    # Path segment: Configuration deployment
    deploy_lint_configs || return 2
    
    # Path segment: Validation
    validate_configurations || return 3
    
    echo "✅ Lint configuration setup complete!"
}

# Discover all repositories in the workspace
discover_repositories() {
    local workspace_root="/Users/bamr87/github"
    local repos=(
        "it-journey"
        "ai-seed"
        "bashcrawl"
        "ai-evolution-engine-seed"
        "zer0-mistakes"
        "zer0-pages"
        "scripts"
    )
    
    echo "📁 Discovered repositories:"
    for repo in "${repos[@]}"; do
        if [[ -d "$workspace_root/$repo" ]]; then
            echo "  ✅ $repo"
        else
            echo "  ❌ $repo (not found)"
        fi
    done
}

# Deploy appropriate lint configurations
deploy_lint_configs() {
    local workspace_root="/Users/bamr87/github"
    
    # Jekyll repositories
    local jekyll_repos=("it-journey" "zer0-mistakes" "zer0-pages")
    for repo in "${jekyll_repos[@]}"; do
        setup_jekyll_linting "$workspace_root/$repo"
    done
    
    # Shell-heavy repositories
    local shell_repos=("bashcrawl" "scripts")
    for repo in "${shell_repos[@]}"; do
        setup_shell_linting "$workspace_root/$repo"
    done
    
    # JavaScript/Node repositories
    local js_repos=("ai-seed")
    for repo in "${js_repos[@]}"; do
        setup_js_linting "$workspace_root/$repo"
    done
    
    # AI/Evolution repositories
    local ai_repos=("ai-evolution-engine-seed")
    for repo in "${ai_repos[@]}"; do
        setup_ai_linting "$workspace_root/$repo"
    done
}

# Setup Jekyll-specific linting
setup_jekyll_linting() {
    local repo_path="$1"
    [[ ! -d "$repo_path" ]] && return 1
    
    echo "🏗️  Setting up Jekyll linting for $(basename "$repo_path")"
    
    # Enhanced markdownlint for Jekyll
    cat > "$repo_path/.markdownlint.json" << 'EOF'
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false,
    "headers": false
  },
  "MD033": {
    "allowed_elements": [
      "details", "summary", "img", "div", "span", "br",
      "kbd", "sub", "sup", "ins", "del", "mark"
    ]
  },
  "MD041": false,
  "MD045": false,
  "MD046": {
    "style": "fenced"
  }
}
EOF
    
    # YAML linting for Jekyll configs
    cat > "$repo_path/.yamllint.yml" << 'EOF'
extends: default

rules:
  line-length:
    max: 120
    level: warning
  document-start: disable
  comments-indentation: disable
  comments:
    min-spaces-from-content: 1
  key-duplicates: enable
  key-ordering: disable
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
EOF
}

# Setup shell-specific linting
setup_shell_linting() {
    local repo_path="$1"
    [[ ! -d "$repo_path" ]] && return 1
    
    echo "🐚 Setting up shell linting for $(basename "$repo_path")"
    
    # ShellCheck configuration
    cat > "$repo_path/.shellcheckrc" << 'EOF'
# ShellCheck configuration for educational shell scripts
disable=SC2034  # Unused variables (common in educational examples)
disable=SC2086  # Double quote to prevent globbing (sometimes intentional)
disable=SC1091  # Not following sourced files (can't always resolve paths)

# Enable additional checks
enable=check-sourced
enable=check-unassigned-uppercase
EOF
    
    # Basic markdownlint for documentation
    cat > "$repo_path/.markdownlint.json" << 'EOF'
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD033": {
    "allowed_elements": ["details", "summary", "img"]
  },
  "MD041": false
}
EOF
}

# Setup JavaScript-specific linting
setup_js_linting() {
    local repo_path="$1"
    [[ ! -d "$repo_path" ]] && return 1
    
    echo "📜 Setting up JavaScript linting for $(basename "$repo_path")"
    
    # Prettier configuration for consistency
    cat > "$repo_path/.prettierrc.json" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false
}
EOF
    
    # EditorConfig for consistency
    cat > "$repo_path/.editorconfig" << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,json,yml,yaml,md}]
indent_style = space
indent_size = 2

[*.{sh,bash}]
indent_style = space
indent_size = 4

[Makefile]
indent_style = tab
EOF
}

# Setup AI/Evolution-specific linting
setup_ai_linting() {
    local repo_path="$1"
    [[ ! -d "$repo_path" ]] && return 1
    
    echo "🤖 Setting up AI project linting for $(basename "$repo_path")"
    
    # Comprehensive linting for AI projects
    setup_shell_linting "$repo_path"
    
    # Additional JSON linting for AI configs
    cat > "$repo_path/.markdownlint.json" << 'EOF'
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD033": {
    "allowed_elements": ["details", "summary", "img", "div", "span"]
  },
  "MD041": false,
  "MD024": {
    "siblings_only": true
  }
}
EOF
}

# Validate all configurations
validate_configurations() {
    echo "🔍 Validating lint configurations..."
    
    local workspace_root="/Users/bamr87/github"
    local total_configs=0
    local valid_configs=0
    
    for repo in it-journey ai-seed bashcrawl ai-evolution-engine-seed zer0-mistakes zer0-pages scripts; do
        local repo_path="$workspace_root/$repo"
        [[ ! -d "$repo_path" ]] && continue
        
        echo "  📁 Checking $repo..."
        
        # Check for markdownlint
        if [[ -f "$repo_path/.markdownlint.json" ]]; then
            ((total_configs++))
            if command -v markdownlint-cli2 >/dev/null 2>&1; then
                if markdownlint-cli2-config "$repo_path/.markdownlint.json" >/dev/null 2>&1; then
                    ((valid_configs++))
                    echo "    ✅ .markdownlint.json"
                else
                    echo "    ❌ .markdownlint.json (invalid)"
                fi
            else
                echo "    ⚠️  .markdownlint.json (markdownlint not installed)"
            fi
        fi
        
        # Check for yamllint
        if [[ -f "$repo_path/.yamllint.yml" ]]; then
            ((total_configs++))
            if command -v yamllint >/dev/null 2>&1; then
                if yamllint --config-file "$repo_path/.yamllint.yml" --version >/dev/null 2>&1; then
                    ((valid_configs++))
                    echo "    ✅ .yamllint.yml"
                else
                    echo "    ❌ .yamllint.yml (invalid)"
                fi
            else
                echo "    ⚠️  .yamllint.yml (yamllint not installed)"
            fi
        fi
    done
    
    echo "📊 Validation summary: $valid_configs/$total_configs configurations valid"
}

# Execute the main path
main "$@"
