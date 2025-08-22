#!/bin/bash
#
# @file scripts/linting/validate-lint-setup.sh
# @description Validates lint configurations across all repositories
# @author IT-Journey Team <team@it-journey.org>
# @created 2025-08-03
# @version 1.0.0
#
# Path: Configuration Discovery → Validation → Reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

main() {
    echo -e "${BLUE}🔍 Validating lint setup across IT-Journey workspace...${NC}\n"
    
    local workspace_root="/Users/bamr87/github"
    local repos=(
        "it-journey:jekyll"
        "ai-seed:javascript"
        "bashcrawl:shell"
        "ai-evolution-engine-seed:ai"
        "zer0-mistakes:jekyll"
        "zer0-pages:jekyll"
        "scripts:shell"
    )
    
    local total_repos=0
    local configured_repos=0
    
    for repo_info in "${repos[@]}"; do
        IFS=':' read -r repo_name repo_type <<< "$repo_info"
        local repo_path="$workspace_root/$repo_name"
        
        ((total_repos++))
        
        if [[ ! -d "$repo_path" ]]; then
            echo -e "${YELLOW}⚠️  $repo_name: Directory not found${NC}"
            continue
        fi
        
        echo -e "${BLUE}📁 Checking $repo_name ($repo_type)...${NC}"
        
        local repo_configured=false
        
        # Check for required configs based on type
        case "$repo_type" in
            "jekyll")
                if validate_jekyll_config "$repo_path"; then
                    repo_configured=true
                fi
                ;;
            "shell")
                if validate_shell_config "$repo_path"; then
                    repo_configured=true
                fi
                ;;
            "javascript")
                if validate_js_config "$repo_path"; then
                    repo_configured=true
                fi
                ;;
            "ai")
                if validate_ai_config "$repo_path"; then
                    repo_configured=true
                fi
                ;;
        esac
        
        if $repo_configured; then
            ((configured_repos++))
        fi
        
        echo ""
    done
    
    # Summary
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "Total repositories: $total_repos"
    echo -e "Properly configured: $configured_repos"
    
    if [[ $configured_repos -eq $total_repos ]]; then
        echo -e "${GREEN}✅ All repositories properly configured!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $((total_repos - configured_repos)) repositories need configuration${NC}"
        echo -e "\nTo fix configuration issues, run:"
        echo -e "${BLUE}./scripts/linting/setup-lint-configs.sh${NC}"
        return 1
    fi
}

validate_jekyll_config() {
    local repo_path="$1"
    local config_found=false
    
    # Check for .markdownlint.json
    if [[ -f "$repo_path/.markdownlint.json" ]]; then
        echo -e "  ${GREEN}✅ .markdownlint.json${NC}"
        config_found=true
    else
        echo -e "  ${RED}❌ .markdownlint.json missing${NC}"
    fi
    
    # Check for .yamllint.yml
    if [[ -f "$repo_path/.yamllint.yml" ]]; then
        echo -e "  ${GREEN}✅ .yamllint.yml${NC}"
        config_found=true
    else
        echo -e "  ${RED}❌ .yamllint.yml missing${NC}"
    fi
    
    $config_found
}

validate_shell_config() {
    local repo_path="$1"
    local config_found=false
    
    # Check for .shellcheckrc
    if [[ -f "$repo_path/.shellcheckrc" ]]; then
        echo -e "  ${GREEN}✅ .shellcheckrc${NC}"
        config_found=true
    else
        echo -e "  ${YELLOW}⚠️  .shellcheckrc missing (recommended)${NC}"
    fi
    
    # Check for .markdownlint.json
    if [[ -f "$repo_path/.markdownlint.json" ]]; then
        echo -e "  ${GREEN}✅ .markdownlint.json${NC}"
        config_found=true
    else
        echo -e "  ${RED}❌ .markdownlint.json missing${NC}"
    fi
    
    $config_found
}

validate_js_config() {
    local repo_path="$1"
    local config_found=false
    
    # Check for .prettierrc.json
    if [[ -f "$repo_path/.prettierrc.json" ]]; then
        echo -e "  ${GREEN}✅ .prettierrc.json${NC}"
        config_found=true
    else
        echo -e "  ${YELLOW}⚠️  .prettierrc.json missing (recommended)${NC}"
    fi
    
    # Check for .editorconfig
    if [[ -f "$repo_path/.editorconfig" ]]; then
        echo -e "  ${GREEN}✅ .editorconfig${NC}"
        config_found=true
    else
        echo -e "  ${YELLOW}⚠️  .editorconfig missing (recommended)${NC}"
    fi
    
    # Check for existing .eslintrc files in subdirectories
    if find "$repo_path" -name ".eslintrc*" -type f | grep -q .; then
        echo -e "  ${GREEN}✅ ESLint config found${NC}"
        config_found=true
    else
        echo -e "  ${YELLOW}⚠️  ESLint config missing${NC}"
    fi
    
    $config_found
}

validate_ai_config() {
    local repo_path="$1"
    local config_found=false
    
    # AI projects need comprehensive linting
    if validate_shell_config "$repo_path"; then
        config_found=true
    fi
    
    # Check for YAML config
    if [[ -f "$repo_path/.yamllint.yml" ]]; then
        echo -e "  ${GREEN}✅ .yamllint.yml${NC}"
        config_found=true
    else
        echo -e "  ${RED}❌ .yamllint.yml missing${NC}"
    fi
    
    $config_found
}

# Run the validation
main "$@"
