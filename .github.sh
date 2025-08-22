#!/bin/bash
# Path: GitHub Structure Builder → Workflow Creation → Configuration Setup
# File: .github.sh
# Description: Automated builder for .github folder structure with workflows and copilot instructions
# Author: IT-Journey Team <team@it-journey.org>
# Created: 2025-08-01
# LastModified: 2025-08-01
# Version: 1.0.0
#
# Path Context:
#   - Entry Path: CLI execution → project detection → structure creation
#   - Workflow Paths: CI/CD pipeline → deployment → testing → monitoring
#   - Configuration Paths: Instructions → templates → policies → automation
#
# Usage: ./github.sh [project-type] [options]
# Examples:
#   ./github.sh jekyll --with-ai-evolution
#   ./github.sh node --minimal
#   ./github.sh python --full-stack

set -euo pipefail

# Path: Environment and Variable Setup
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(pwd)"
readonly GITHUB_DIR="${PROJECT_ROOT}/.github"
readonly WORKFLOWS_DIR="${GITHUB_DIR}/workflows"
readonly INSTRUCTIONS_DIR="${GITHUB_DIR}/instructions"
readonly ISSUE_TEMPLATES_DIR="${GITHUB_DIR}/ISSUE_TEMPLATE"
readonly PR_TEMPLATES_DIR="${GITHUB_DIR}/PULL_REQUEST_TEMPLATE"

# Path: Logging Setup
readonly LOG_FILE="${PROJECT_ROOT}/logs/github-builder.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Path: Color Output Functions
setup_colors() {
    if [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        PURPLE=''
        CYAN=''
        WHITE=''
        NC=''
    fi
}

# Path: Logging Functions
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[SUCCESS]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
}

# Path: Project Type Detection
detect_project_type() {
    local project_type="generic"
    
    if [[ -f "${PROJECT_ROOT}/Gemfile" && -f "${PROJECT_ROOT}/_config.yml" ]]; then
        project_type="jekyll"
    elif [[ -f "${PROJECT_ROOT}/package.json" ]]; then
        if grep -q "next" "${PROJECT_ROOT}/package.json" 2>/dev/null; then
            project_type="nextjs"
        elif grep -q "react" "${PROJECT_ROOT}/package.json" 2>/dev/null; then
            project_type="react"
        else
            project_type="node"
        fi
    elif [[ -f "${PROJECT_ROOT}/requirements.txt" || -f "${PROJECT_ROOT}/pyproject.toml" || -f "${PROJECT_ROOT}/setup.py" ]]; then
        project_type="python"
    elif [[ -f "${PROJECT_ROOT}/Dockerfile" ]]; then
        project_type="docker"
    elif [[ -f "${PROJECT_ROOT}/go.mod" ]]; then
        project_type="go"
    elif [[ -f "${PROJECT_ROOT}/Cargo.toml" ]]; then
        project_type="rust"
    fi
    
    echo "$project_type"
}

# Path: Directory Structure Creation
create_github_structure() {
    local project_type="$1"
    
    log_info "Creating .github directory structure for project type: $project_type"
    
    # Create main directories
    mkdir -p "$WORKFLOWS_DIR"
    mkdir -p "$INSTRUCTIONS_DIR"
    mkdir -p "$ISSUE_TEMPLATES_DIR"
    mkdir -p "$PR_TEMPLATES_DIR"
    
    log_success "GitHub directory structure created successfully"
}

# Path: Copilot Instructions Generation
create_copilot_instructions() {
    local project_type="$1"
    local instructions_file="${GITHUB_DIR}/copilot-instructions.md"
    
    log_info "Generating copilot instructions for $project_type project"
    
    cat > "$instructions_file" << 'EOF'
# Copilot Instructions

These instructions guide AI-powered development practices following the path-based development approach and IT-Journey principles.

## Core Development Principles

### Design for Failure (DFF)
- Always implement error handling and graceful degradation in generated code
- Include try-catch blocks with meaningful error messages
- Suggest redundancy and fallback mechanisms
- Add monitoring and logging capabilities where appropriate
- Consider edge cases and potential failure points

### Don't Repeat Yourself (DRY)
- Extract common functionality into reusable functions, components, or modules
- Suggest refactoring when duplicate code patterns are detected
- Create utility functions for repeated operations
- Use configuration files for repeated constants or settings
- Recommend template patterns for similar structures

### Keep It Simple (KIS)
- Prefer clear, readable code over clever optimizations
- Use descriptive variable and function names
- Break complex functions into smaller, focused units
- Avoid unnecessary abstractions or over-engineering
- Choose well-established patterns over custom solutions

### Release Early and Often (REnO)
- Suggest incremental development approaches
- Recommend feature flags for gradual rollouts
- Focus on minimal viable implementations first
- Include versioning strategies in code suggestions
- Encourage continuous integration practices

### Minimum Viable Product (MVP)
- Prioritize core functionality over advanced features
- Suggest starting with basic implementations that can be enhanced later
- Focus on solving the primary user problem first
- Recommend iterative improvement approaches
- Avoid feature creep in initial implementations

### Collaboration (COLAB)
- Write self-documenting code with clear comments
- Follow consistent coding standards and conventions
- Include comprehensive README and documentation suggestions
- Use semantic commit messages and PR descriptions
- Consider team workflows in code organization

### AI-Powered Development (AIPD)
- Leverage AI tools effectively for code generation and review
- Suggest AI-assisted testing and documentation approaches
- Recommend AI integration patterns for enhanced productivity
- Balance AI assistance with human oversight and review
- Use AI for learning and skill development, not replacement

## Path-Based Development Standards

### Code Organization
- **Entry Points**: Define clear starting paths with descriptive comments
- **Flow Control**: Use path-based logic that follows natural decision trees
- **Modular Paths**: Break code into functions that represent path segments
- **Path Documentation**: Comment each path junction and destination

### Error Handling Paths
- **Path Preservation**: Errors maintain context about which path failed
- **Fallback Paths**: Define alternative routes when primary paths fail
- **Path Logging**: Track the journey through the code for debugging

### Testing Along Natural Paths
- **Happy Paths**: Test the most common, successful routes
- **Edge Paths**: Explore boundary conditions and unusual routes
- **Error Paths**: Verify failure handling along exception routes

## Technology-Specific Guidelines

### Container-First Development
- **Build Paths**: Multi-stage Dockerfiles create clear transformation paths
- **Deployment Paths**: Containers flow through development → staging → production
- **Network Paths**: Service discovery creates dynamic communication routes
- **Volume Paths**: Data flows through well-defined storage pathways

### Documentation Standards
- Generate comprehensive README files for all projects
- Include installation, usage, and contribution guidelines
- Add inline code documentation for complex logic
- Create user guides and API documentation when relevant
- Maintain changelogs and version documentation

### Quality Standards
- **Security Best Practices**: Validate inputs, secure authentication, avoid hardcoded secrets
- **Performance Considerations**: Optimize for readability first, performance second
- **Accessibility & Inclusivity**: Follow WCAG guidelines, use inclusive language

---

*These instructions embody the path-based development philosophy, emphasizing natural flow, organic growth, and AI-enhanced development practices.*
EOF
    
    # Add project-specific instructions
    case "$project_type" in
        "jekyll")
            append_jekyll_instructions "$instructions_file"
            ;;
        "node"|"react"|"nextjs")
            append_node_instructions "$instructions_file"
            ;;
        "python")
            append_python_instructions "$instructions_file"
            ;;
        "docker")
            append_docker_instructions "$instructions_file"
            ;;
    esac
    
    log_success "Copilot instructions created: $instructions_file"
}

# Path: Project-Specific Instruction Appendages
append_jekyll_instructions() {
    local file="$1"
    
    cat >> "$file" << 'EOF'

## Jekyll-Specific Guidelines

### Content Management
- Use descriptive filenames following Jekyll conventions (YYYY-MM-DD-title.md)
- Include comprehensive frontmatter with proper metadata
- Organize content in logical directory structures
- Use liquid templates efficiently and safely

### Development Workflow
- Test locally before pushing changes
- Use bundle exec for consistent gem environments
- Optimize for build performance with proper exclusions
- Implement responsive design patterns

### Deployment
- Configure proper base URLs for different environments
- Use environment-specific configuration files
- Implement caching strategies for static assets
- Ensure SEO optimization with proper meta tags
EOF
}

append_node_instructions() {
    local file="$1"
    
    cat >> "$file" << 'EOF'

## Node.js/JavaScript-Specific Guidelines

### Package Management
- Use npm ci in production environments
- Keep package.json and package-lock.json in sync
- Regularly audit and update dependencies
- Use semantic versioning for package releases

### Code Standards
- Follow ES6+ standards and modern JavaScript practices
- Use async/await for asynchronous operations
- Implement proper error boundaries and handling
- Use TypeScript when beneficial for type safety

### Performance
- Implement lazy loading and code splitting
- Optimize bundle sizes and minimize dependencies
- Use appropriate caching strategies
- Monitor and profile application performance
EOF
}

append_python_instructions() {
    local file="$1"
    
    cat >> "$file" << 'EOF'

## Python-Specific Guidelines

### Environment Management
- Use virtual environments for project isolation
- Pin dependency versions in requirements.txt
- Use pyproject.toml for modern project configuration
- Follow PEP standards and best practices

### Code Quality
- Use type hints for better code documentation
- Follow PEP 8 style guidelines
- Implement comprehensive docstrings
- Use pytest for testing with good coverage

### Package Management
- Use pip-tools for dependency management
- Separate development and production dependencies
- Regularly update and audit packages
- Use wheel format for distribution
EOF
}

append_docker_instructions() {
    local file="$1"
    
    cat >> "$file" << 'EOF'

## Docker-Specific Guidelines

### Container Best Practices
- Use multi-stage builds for smaller images
- Run containers as non-root users
- Use specific image tags, avoid 'latest'
- Implement proper health checks

### Security
- Scan images for vulnerabilities
- Use minimal base images (alpine, distroless)
- Avoid embedding secrets in images
- Keep images updated with security patches

### Orchestration
- Use docker-compose for local development
- Implement proper service discovery
- Use volumes for persistent data
- Configure proper networking and isolation
EOF
}

# Path: Workflow Generation Functions
create_workflows() {
    local project_type="$1"
    local with_ai_evolution="$2"
    
    log_info "Creating GitHub Actions workflows for $project_type"
    
    # Create base CI workflow
    create_ci_workflow "$project_type"
    
    # Create release workflow
    create_release_workflow "$project_type"
    
    # Create dependency update workflow
    create_dependency_update_workflow "$project_type"
    
    # Create AI evolution workflow if requested
    if [[ "$with_ai_evolution" == "true" ]]; then
        create_ai_evolution_workflow "$project_type"
    fi
    
    # Create code quality workflow
    create_code_quality_workflow "$project_type"
    
    log_success "GitHub Actions workflows created"
}

# Path: CI Workflow Creation
create_ci_workflow() {
    local project_type="$1"
    local workflow_file="${WORKFLOWS_DIR}/ci.yml"
    
    cat > "$workflow_file" << EOF
name: 🔄 Continuous Integration

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.11'
  RUBY_VERSION: '3.1'

jobs:
  test:
    name: 🧪 Test Suite
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      
    - name: 🔍 Detect changes
      uses: dorny/paths-filter@v2
      id: changes
      with:
        filters: |
          src:
            - 'src/**'
            - 'lib/**'
            - '*.js'
            - '*.ts'
            - '*.py'
            - '*.rb'
          docs:
            - 'docs/**'
            - '*.md'
            - '_posts/**'
          config:
            - '*.yml'
            - '*.yaml'
            - '*.json'
            - 'Dockerfile*'
            - 'docker-compose*'
EOF

    case "$project_type" in
        "jekyll")
            append_jekyll_ci_steps "$workflow_file"
            ;;
        "node"|"react"|"nextjs")
            append_node_ci_steps "$workflow_file"
            ;;
        "python")
            append_python_ci_steps "$workflow_file"
            ;;
        *)
            append_generic_ci_steps "$workflow_file"
            ;;
    esac
}

append_jekyll_ci_steps() {
    local file="$1"
    
    cat >> "$file" << 'EOF'
            
    - name: 💎 Setup Ruby
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.docs == 'true'
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ env.RUBY_VERSION }}
        bundler-cache: true
        
    - name: 🔨 Build Jekyll site
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.docs == 'true'
      run: |
        bundle exec jekyll build --verbose
        
    - name: 🧪 Test generated site
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.docs == 'true'
      run: |
        bundle exec htmlproofer ./_site \
          --disable-external \
          --check-html \
          --allow-hash-href
          
    - name: 📊 Check file sizes
      run: |
        find ./_site -name "*.html" -exec wc -c {} + | sort -n
        du -sh ./_site
EOF
}

append_node_ci_steps() {
    local file="$1"
    
    cat >> "$file" << 'EOF'
            
    - name: 🟢 Setup Node.js
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.config == 'true'
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
        
    - name: 📦 Install dependencies
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.config == 'true'
      run: npm ci
      
    - name: 🔍 Lint code
      if: steps.changes.outputs.src == 'true'
      run: npm run lint
      
    - name: 🧪 Run tests
      if: steps.changes.outputs.src == 'true'
      run: npm test
      
    - name: 🔨 Build project
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.config == 'true'
      run: npm run build
      
    - name: 📊 Bundle analysis
      if: steps.changes.outputs.src == 'true'
      run: |
        npx webpack-bundle-analyzer dist/main.js --mode static || true
        du -sh dist/
EOF
}

append_python_ci_steps() {
    local file="$1"
    
    cat >> "$file" << 'EOF'
            
    - name: 🐍 Setup Python
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.config == 'true'
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
        
    - name: 📦 Install dependencies
      if: steps.changes.outputs.src == 'true' || steps.changes.outputs.config == 'true'
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt || true
        
    - name: 🔍 Lint with flake8
      if: steps.changes.outputs.src == 'true'
      run: |
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
        
    - name: 🧪 Test with pytest
      if: steps.changes.outputs.src == 'true'
      run: |
        pytest --cov=./ --cov-report=xml
        
    - name: 📊 Upload coverage
      if: steps.changes.outputs.src == 'true'
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
EOF
}

append_generic_ci_steps() {
    local file="$1"
    
    cat >> "$file" << 'EOF'
            
    - name: 🔍 Run basic checks
      run: |
        echo "Running basic project checks..."
        find . -name "*.sh" -exec shellcheck {} \; || true
        find . -name "*.yml" -o -name "*.yaml" | xargs yamllint || true
        
    - name: 🧪 Test if present
      run: |
        if [ -f "test.sh" ]; then
          chmod +x test.sh
          ./test.sh
        elif [ -f "Makefile" ] && grep -q "test" Makefile; then
          make test
        else
          echo "No test suite found"
        fi
EOF
}

# Path: Release Workflow Creation
create_release_workflow() {
    local project_type="$1"
    local workflow_file="${WORKFLOWS_DIR}/release.yml"
    
    cat > "$workflow_file" << 'EOF'
name: 🚀 Release & Deploy

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:
    inputs:
      release_type:
        description: 'Release type'
        required: true
        default: 'patch'
        type: choice
        options:
          - patch
          - minor
          - major

permissions:
  contents: write
  packages: write

jobs:
  create-release:
    name: 📦 Create Release
    runs-on: ubuntu-latest
    
    outputs:
      version: ${{ steps.version.outputs.version }}
      upload_url: ${{ steps.create_release.outputs.upload_url }}
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: 🔢 Calculate version
      id: version
      run: |
        if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
          # Get latest tag and increment
          latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
          version_parts=(${latest_tag//v/})
          IFS='.' read -ra VERSION_ARRAY <<< "${version_parts[0]}"
          
          case "${{ github.event.inputs.release_type }}" in
            "major")
              new_version="v$((VERSION_ARRAY[0] + 1)).0.0"
              ;;
            "minor")
              new_version="v${VERSION_ARRAY[0]}.$((VERSION_ARRAY[1] + 1)).0"
              ;;
            "patch")
              new_version="v${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}.$((VERSION_ARRAY[2] + 1))"
              ;;
          esac
          echo "version=$new_version" >> $GITHUB_OUTPUT
        else
          echo "version=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
        fi
        
    - name: 📝 Generate changelog
      run: |
        echo "# Changelog for ${{ steps.version.outputs.version }}" > changelog.md
        echo "" >> changelog.md
        
        # Get commits since last tag
        last_tag=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")
        if [[ -n "$last_tag" ]]; then
          git log ${last_tag}..HEAD --pretty=format:"- %s (%h)" >> changelog.md
        else
          git log --pretty=format:"- %s (%h)" >> changelog.md
        fi
        
    - name: 🎉 Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ steps.version.outputs.version }}
        release_name: Release ${{ steps.version.outputs.version }}
        body_path: changelog.md
        draft: false
        prerelease: false
EOF
}

# Path: Dependency Update Workflow
create_dependency_update_workflow() {
    local project_type="$1"
    local workflow_file="${WORKFLOWS_DIR}/dependency-update.yml"
    
    cat > "$workflow_file" << 'EOF'
name: 🔄 Dependency Updates

on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6 AM
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update-dependencies:
    name: 📦 Update Dependencies
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      
    - name: 🔍 Check for dependency files
      id: check_files
      run: |
        echo "has_package_json=$(test -f package.json && echo true || echo false)" >> $GITHUB_OUTPUT
        echo "has_gemfile=$(test -f Gemfile && echo true || echo false)" >> $GITHUB_OUTPUT
        echo "has_requirements=$(test -f requirements.txt && echo true || echo false)" >> $GITHUB_OUTPUT
        echo "has_go_mod=$(test -f go.mod && echo true || echo false)" >> $GITHUB_OUTPUT
        
    - name: 🟢 Setup Node.js
      if: steps.check_files.outputs.has_package_json == 'true'
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        
    - name: 💎 Setup Ruby
      if: steps.check_files.outputs.has_gemfile == 'true'
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.1'
        
    - name: 🐍 Setup Python
      if: steps.check_files.outputs.has_requirements == 'true'
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        
    - name: 🔄 Update Node dependencies
      if: steps.check_files.outputs.has_package_json == 'true'
      run: |
        npm update
        npm audit fix || true
        
    - name: 🔄 Update Ruby dependencies
      if: steps.check_files.outputs.has_gemfile == 'true'
      run: |
        bundle update
        
    - name: 🔄 Update Python dependencies
      if: steps.check_files.outputs.has_requirements == 'true'
      run: |
        pip install --upgrade pip
        pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U || true
        pip freeze > requirements.txt
        
    - name: 📝 Create Pull Request
      uses: peter-evans/create-pull-request@v5
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        commit-message: 'chore: update dependencies'
        title: '🔄 Automated dependency updates'
        body: |
          ## 📦 Dependency Updates
          
          This PR contains automated dependency updates.
          
          ### What's Changed
          - Updated outdated dependencies to their latest versions
          - Applied security fixes where available
          
          ### Review Notes
          - Please review the changes carefully
          - Run tests to ensure compatibility
          - Check for any breaking changes in updated packages
          
          ---
          *This PR was created automatically by the dependency update workflow*
        branch: dependency-updates
        delete-branch: true
EOF
}

# Path: AI Evolution Workflow
create_ai_evolution_workflow() {
    local project_type="$1"
    local workflow_file="${WORKFLOWS_DIR}/ai-evolution.yml"
    
    cat > "$workflow_file" << 'EOF'
name: 🤖 AI Evolution Engine

on:
  workflow_dispatch:
    inputs:
      evolution_mode:
        description: 'Evolution Mode'
        required: true
        default: 'adaptive'
        type: choice
        options:
          - adaptive
          - aggressive
          - conservative
          - experimental
      target_component:
        description: 'Target Component'
        required: false
        default: 'all'
        type: choice
        options:
          - all
          - documentation
          - code
          - tests
          - workflows
          - configuration
      evolution_prompt:
        description: 'Evolution Guidance'
        required: false
        default: 'Enhance code quality and documentation'

  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  ai-evolution:
    name: 🌱 AI-Powered Evolution
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: 🔍 Analyze project structure
      id: analyze
      run: |
        echo "Analyzing project structure..."
        
        # Count files by type
        echo "file_counts<<EOF" >> $GITHUB_OUTPUT
        find . -type f -name "*.md" | wc -l | xargs echo "markdown:"
        find . -type f -name "*.js" -o -name "*.ts" | wc -l | xargs echo "javascript:"
        find . -type f -name "*.py" | wc -l | xargs echo "python:"
        find . -type f -name "*.rb" | wc -l | xargs echo "ruby:"
        find . -type f -name "*.yml" -o -name "*.yaml" | wc -l | xargs echo "yaml:"
        echo "EOF" >> $GITHUB_OUTPUT
        
        # Detect primary language
        if [[ -f "Gemfile" ]]; then
          echo "primary_language=ruby" >> $GITHUB_OUTPUT
        elif [[ -f "package.json" ]]; then
          echo "primary_language=javascript" >> $GITHUB_OUTPUT
        elif [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
          echo "primary_language=python" >> $GITHUB_OUTPUT
        else
          echo "primary_language=generic" >> $GITHUB_OUTPUT
        fi
        
    - name: 🎯 Generate evolution suggestions
      id: suggestions
      run: |
        echo "Generating AI evolution suggestions..."
        
        # Create evolution report
        cat > evolution-report.md << 'EVOLUTION_EOF'
# 🤖 AI Evolution Report
        
## Project Analysis
- **Primary Language**: ${{ steps.analyze.outputs.primary_language }}
- **Evolution Mode**: ${{ github.event.inputs.evolution_mode || 'scheduled' }}
- **Target Component**: ${{ github.event.inputs.target_component || 'all' }}
        
## Detected Opportunities
        
### 📚 Documentation Enhancements
- [ ] README.md completeness and clarity
- [ ] API documentation generation
- [ ] Code comment coverage
- [ ] Contributing guidelines
        
### 🔧 Code Quality Improvements
- [ ] Test coverage analysis
- [ ] Performance optimization opportunities
- [ ] Security vulnerability scanning
- [ ] Dependency management
        
### 🚀 Workflow Optimizations
- [ ] CI/CD pipeline efficiency
- [ ] Automated testing improvements
- [ ] Deployment process enhancement
- [ ] Monitoring and alerting setup
        
### 🌐 Cross-Platform Compatibility
- [ ] Container standardization
- [ ] Environment configuration
- [ ] Path-based architecture
- [ ] Platform-specific optimizations
        
## Recommended Actions
        
1. **Immediate**: Fix critical issues and security vulnerabilities
2. **Short-term**: Enhance documentation and test coverage
3. **Medium-term**: Optimize workflows and performance
4. **Long-term**: Implement advanced features and integrations
        
## Evolution Metrics
- **Files Analyzed**: $(find . -type f | wc -l)
- **Lines of Code**: $(find . -name "*.js" -o -name "*.py" -o -name "*.rb" -o -name "*.ts" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
- **Documentation Coverage**: $(find . -name "*.md" | wc -l)%
        
---
*Generated by AI Evolution Engine on $(date)*
EVOLUTION_EOF
        
    - name: 🔄 Create Evolution PR
      uses: peter-evans/create-pull-request@v5
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        commit-message: 'feat: AI evolution suggestions and improvements'
        title: '🤖 AI Evolution: ${{ github.event.inputs.evolution_mode || "Scheduled" }} Enhancement'
        body: |
          ## 🌱 AI-Powered Evolution
          
          This PR contains AI-generated suggestions and improvements for the project.
          
          ### Evolution Configuration
          - **Mode**: ${{ github.event.inputs.evolution_mode || 'scheduled' }}
          - **Target**: ${{ github.event.inputs.target_component || 'all' }}
          - **Guidance**: ${{ github.event.inputs.evolution_prompt || 'Enhance code quality and documentation' }}
          
          ### What's Included
          - Detailed evolution analysis report
          - Suggested improvements and enhancements
          - Prioritized action items
          - Metrics and recommendations
          
          ### Next Steps
          1. Review the evolution report
          2. Implement suggested improvements
          3. Update documentation as needed
          4. Run tests to ensure quality
          
          ---
          *This PR was created automatically by the AI Evolution Engine*
        branch: ai-evolution-${{ github.run_number }}
        delete-branch: true
EOF
}

# Path: Code Quality Workflow
create_code_quality_workflow() {
    local project_type="$1"
    local workflow_file="${WORKFLOWS_DIR}/code-quality.yml"
    
    cat > "$workflow_file" << 'EOF'
name: 🔍 Code Quality & Security

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]
  schedule:
    - cron: '0 4 * * 2'  # Weekly on Tuesday at 4 AM

permissions:
  contents: read
  security-events: write
  actions: read

jobs:
  security-scan:
    name: 🛡️ Security Analysis
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      
    - name: 🔍 Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: javascript, python, ruby
        
    - name: 🏗️ Autobuild
      uses: github/codeql-action/autobuild@v2
      
    - name: 🔍 Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
      
    - name: 🔐 Dependency security scan
      uses: anchore/sbom-action@v0
      with:
        path: ./
        format: spdx-json
        
  lint-and-format:
    name: 📏 Lint & Format
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      
    - name: 🔍 Lint Markdown
      uses: articulate/actions-markdownlint@v1
      with:
        config: .markdownlint.json
        files: '**/*.md'
        ignore: node_modules
        
    - name: 🔍 Lint YAML
      uses: ibiqlik/action-yamllint@v3
      with:
        file_or_dir: .
        config_file: .yamllint.yml
        
    - name: 🔍 Lint Shell scripts
      run: |
        find . -name "*.sh" -exec shellcheck {} \;
        
  quality-metrics:
    name: 📊 Quality Metrics
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: 📈 Calculate metrics
      run: |
        echo "## 📊 Code Quality Metrics" > quality-report.md
        echo "" >> quality-report.md
        
        # File statistics
        total_files=$(find . -type f | wc -l)
        code_files=$(find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rb" | wc -l)
        doc_files=$(find . -name "*.md" | wc -l)
        
        echo "- **Total Files**: $total_files" >> quality-report.md
        echo "- **Code Files**: $code_files" >> quality-report.md
        echo "- **Documentation Files**: $doc_files" >> quality-report.md
        
        # Lines of code
        if [[ $code_files -gt 0 ]]; then
          loc=$(find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rb" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
          echo "- **Lines of Code**: $loc" >> quality-report.md
        fi
        
        # Git statistics
        commits_this_week=$(git log --since="7 days ago" --oneline | wc -l)
        contributors=$(git shortlog -sn | wc -l)
        
        echo "- **Commits This Week**: $commits_this_week" >> quality-report.md
        echo "- **Contributors**: $contributors" >> quality-report.md
        
        # Documentation ratio
        if [[ $code_files -gt 0 ]]; then
          doc_ratio=$((doc_files * 100 / code_files))
          echo "- **Documentation Ratio**: ${doc_ratio}%" >> quality-report.md
        fi
        
        cat quality-report.md
        
    - name: 💾 Upload quality report
      uses: actions/upload-artifact@v3
      with:
        name: quality-report
        path: quality-report.md
EOF
}

# Path: Issue and PR Templates
create_issue_templates() {
    log_info "Creating issue and pull request templates"
    
    # Bug report template
    cat > "${ISSUE_TEMPLATES_DIR}/bug_report.yml" << 'EOF'
name: 🐛 Bug Report
description: File a bug report to help us improve
title: "[Bug]: "
labels: ["bug", "triage"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Thank you for taking the time to report this bug! Please provide detailed information to help us resolve it quickly.

  - type: textarea
    id: description
    attributes:
      label: 📝 Bug Description
      description: A clear and concise description of what the bug is.
      placeholder: Tell us what happened!
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: 🔄 Steps to Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Go to '...'
        2. Click on '....'
        3. Scroll down to '....'
        4. See error
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: ✅ Expected Behavior
      description: A clear and concise description of what you expected to happen.
    validations:
      required: true

  - type: textarea
    id: screenshots
    attributes:
      label: 📸 Screenshots
      description: If applicable, add screenshots to help explain your problem.

  - type: dropdown
    id: environment
    attributes:
      label: 🌍 Environment
      description: What environment are you using?
      options:
        - Development
        - Staging
        - Production
        - Local
    validations:
      required: true

  - type: textarea
    id: system-info
    attributes:
      label: 💻 System Information
      description: |
        Please provide relevant system information
      placeholder: |
        - OS: [e.g. iOS, Windows, Linux]
        - Browser: [e.g. chrome, safari]
        - Version: [e.g. 22]
        - Node.js version: [if applicable]

  - type: textarea
    id: additional-context
    attributes:
      label: 📎 Additional Context
      description: Add any other context about the problem here.
EOF

    # Feature request template
    cat > "${ISSUE_TEMPLATES_DIR}/feature_request.yml" << 'EOF'
name: ✨ Feature Request
description: Suggest an idea for this project
title: "[Feature]: "
labels: ["enhancement", "feature-request"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Thank you for suggesting a new feature! Please provide detailed information about your idea.

  - type: textarea
    id: problem
    attributes:
      label: 🎯 Problem Statement
      description: Is your feature request related to a problem? Please describe.
      placeholder: I'm always frustrated when...
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: 💡 Proposed Solution
      description: Describe the solution you'd like to see.
      placeholder: I would like to see...
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: 🔄 Alternatives Considered
      description: Describe any alternative solutions or features you've considered.

  - type: dropdown
    id: priority
    attributes:
      label: 📊 Priority Level
      description: How important is this feature to you?
      options:
        - Low - Nice to have
        - Medium - Would improve workflow
        - High - Critical for my use case
    validations:
      required: true

  - type: checkboxes
    id: implementation
    attributes:
      label: 🛠️ Implementation
      description: Are you willing to help implement this feature?
      options:
        - label: I can help with implementation
        - label: I can help with testing
        - label: I can help with documentation

  - type: textarea
    id: additional-context
    attributes:
      label: 📎 Additional Context
      description: Add any other context, mockups, or examples about the feature request here.
EOF

    # Documentation improvement template
    cat > "${ISSUE_TEMPLATES_DIR}/documentation.yml" << 'EOF'
name: 📚 Documentation Improvement
description: Suggest improvements to documentation
title: "[Docs]: "
labels: ["documentation", "improvement"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Help us improve our documentation! Please provide specific suggestions.

  - type: dropdown
    id: doc-type
    attributes:
      label: 📋 Documentation Type
      description: What type of documentation needs improvement?
      options:
        - README
        - API Documentation
        - Installation Guide
        - User Guide
        - Contributing Guidelines
        - Code Comments
        - Other
    validations:
      required: true

  - type: textarea
    id: current-issue
    attributes:
      label: 🔍 Current Issue
      description: What's wrong with the current documentation?
      placeholder: The current documentation is unclear about...
    validations:
      required: true

  - type: textarea
    id: suggested-improvement
    attributes:
      label: ✨ Suggested Improvement
      description: How should the documentation be improved?
      placeholder: I suggest we add/change/remove...
    validations:
      required: true

  - type: textarea
    id: location
    attributes:
      label: 📍 Location
      description: Where is this documentation located? (file path, URL, etc.)

  - type: checkboxes
    id: help-offered
    attributes:
      label: 🤝 Contribution
      description: Can you help improve this documentation?
      options:
        - label: I can write the improved documentation
        - label: I can review the changes
        - label: I can provide examples or use cases
EOF

    # Pull request template
    cat > "${PR_TEMPLATES_DIR}/pull_request_template.md" << 'EOF'
## 📋 Description

Brief description of the changes made in this PR.

## 🔗 Related Issues

- Fixes #(issue number)
- Resolves #(issue number)

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔧 Maintenance/refactoring
- [ ] 🧪 Test improvements

## 🧪 Testing

- [ ] Tests pass locally
- [ ] New tests added for new functionality
- [ ] Manual testing completed

Describe the tests that you ran to verify your changes:

## 📝 Checklist

- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## 📸 Screenshots (if applicable)

Add screenshots to help reviewers understand the changes.

## 📎 Additional Notes

Any additional information, concerns, or questions for reviewers.

## 🎉 Celebration

What are you most excited about with this change?
EOF

    log_success "Issue and pull request templates created"
}

# Path: Configuration Files
create_configuration_files() {
    local project_type="$1"
    
    log_info "Creating configuration files for code quality tools"
    
    # Create .markdownlint.json
    cat > "${PROJECT_ROOT}/.markdownlint.json" << 'EOF'
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

    # Create .yamllint.yml
    cat > "${PROJECT_ROOT}/.yamllint.yml" << 'EOF'
extends: default

rules:
  line-length:
    max: 120
    level: warning
  document-start: disable
  comments-indentation: disable
  comments:
    min-spaces-from-content: 1
EOF

    # Create dependabot.yml
    mkdir -p "${GITHUB_DIR}"
    cat > "${GITHUB_DIR}/dependabot.yml" << EOF
version: 2
updates:
EOF

    case "$project_type" in
        "node"|"react"|"nextjs")
            cat >> "${GITHUB_DIR}/dependabot.yml" << 'EOF'
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "@bamr87"
    assignees:
      - "@bamr87"
EOF
            ;;
        "python")
            cat >> "${GITHUB_DIR}/dependabot.yml" << 'EOF'
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
            ;;
        "jekyll")
            cat >> "${GITHUB_DIR}/dependabot.yml" << 'EOF'
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
            ;;
    esac

    # Always add GitHub Actions dependency updates
    cat >> "${GITHUB_DIR}/dependabot.yml" << 'EOF'
  - package-ecosystem: "github-actions"
    directory: "/.github/workflows"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
EOF

    log_success "Configuration files created"
}

# Path: Main Execution Function
main() {
    local project_type="${1:-}"
    local with_ai_evolution="false"
    local minimal_mode="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --with-ai-evolution)
                with_ai_evolution="true"
                shift
                ;;
            --minimal)
                minimal_mode="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$project_type" ]]; then
                    project_type="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Setup colors and logging
    setup_colors
    
    log_info "🚀 Starting GitHub structure builder"
    log_info "Project directory: $PROJECT_ROOT"
    
    # Detect project type if not provided
    if [[ -z "$project_type" ]]; then
        project_type=$(detect_project_type)
        log_info "Detected project type: $project_type"
    else
        log_info "Using specified project type: $project_type"
    fi
    
    # Create directory structure
    create_github_structure "$project_type"
    
    # Create copilot instructions
    create_copilot_instructions "$project_type"
    
    # Create workflows unless in minimal mode
    if [[ "$minimal_mode" != "true" ]]; then
        create_workflows "$project_type" "$with_ai_evolution"
    fi
    
    # Create issue and PR templates
    create_issue_templates
    
    # Create configuration files
    create_configuration_files "$project_type"
    
    # Final summary
    log_success "✅ GitHub structure created successfully!"
    echo ""
    echo -e "${CYAN}📁 Created structure:${NC}"
    echo "  📂 .github/"
    echo "  ├── 📂 workflows/"
    find "$WORKFLOWS_DIR" -name "*.yml" -exec basename {} \; | sed 's/^/  │   ├── 📄 /'
    echo "  ├── 📂 ISSUE_TEMPLATE/"
    find "$ISSUE_TEMPLATES_DIR" -name "*.yml" -exec basename {} \; | sed 's/^/  │   ├── 📄 /'
    echo "  ├── 📂 PULL_REQUEST_TEMPLATE/"
    echo "  │   └── 📄 pull_request_template.md"
    echo "  ├── 📄 copilot-instructions.md"
    echo "  └── 📄 dependabot.yml"
    echo ""
    echo -e "${GREEN}🎉 Your project is now ready with GitHub workflows and AI assistance!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo "  1. Review and customize the generated workflows"
    echo "  2. Update the copilot instructions for your specific needs"
    echo "  3. Configure any repository secrets required by workflows"
    echo "  4. Enable GitHub Actions in your repository settings"
    echo "  5. Consider enabling Dependabot alerts and security updates"
}

# Path: Help Function
show_help() {
    cat << 'EOF'
🔧 GitHub Structure Builder

USAGE:
    ./github.sh [PROJECT_TYPE] [OPTIONS]

PROJECT TYPES:
    jekyll      Jekyll/Ruby static site projects
    node        Node.js/JavaScript projects
    react       React applications
    nextjs      Next.js applications
    python      Python projects
    docker      Docker-based projects
    go          Go projects
    rust        Rust projects
    (auto)      Automatically detect project type

OPTIONS:
    --with-ai-evolution    Include AI evolution workflows
    --minimal             Create minimal structure (no workflows)
    --help, -h            Show this help message

EXAMPLES:
    ./github.sh                              # Auto-detect project type
    ./github.sh jekyll --with-ai-evolution   # Jekyll with AI workflows
    ./github.sh node --minimal               # Node.js with minimal setup
    ./github.sh python                       # Python project with full setup

FEATURES:
    ✅ GitHub Actions workflows (CI/CD, releases, security)
    ✅ Issue and pull request templates
    ✅ Dependabot configuration
    ✅ Code quality and security scanning
    ✅ AI-powered copilot instructions
    ✅ Optional AI evolution workflows

For more information, visit: https://github.com/bamr87/it-journey
EOF
}

# Path: Script Entry Point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi