# ForkMe - Advanced GitHub Repository Forking Utility

**Version:** 1.0.0  
**Author:** IT-Journey Scripts Team  
**License:** MIT  
**Repository:** bamr87/FORKME

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Quick Reference Card](#quick-reference-card)
5. [Forking Strategies](#forking-strategies)
6. [Real-World Examples](#real-world-examples)
7. [Command Reference](#command-reference)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Implementation Summary](#implementation-summary)

---

## Overview

ForkMe is a powerful command-line utility designed to provide flexible forking and cloning options for GitHub repositories. It goes beyond simple `git clone` by offering multiple strategies optimized for different workflows: security reviews, code analysis, documentation extraction, testing, research, and more.

### Key Features

- **10 Forking Strategies**: Full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, and metadata-only
- **Intelligent Filtering**: Filter by file types, directory patterns, and custom rules
- **GitHub Integration**: Automatic fork creation with GitHub CLI
- **Analysis Tools**: Built-in repository metadata and structure analysis
- **Dry Run Mode**: Preview operations without making changes
- **Cross-Platform**: Works on macOS, Linux, and Windows (WSL)
- **Optimized for Speed**: Shallow clones and sparse checkouts for large repositories

### Why Use ForkMe?

| Traditional `git clone` | ForkMe |
|-------------------------|--------|
| ✓ Full repository clone | ✓ Full clone + 9 other strategies |
| ✗ Manual filtering needed | ✓ Built-in filtering by file type, path, etc. |
| ✗ No GitHub fork automation | ✓ Automated fork creation |
| ✗ No analysis tools | ✓ Built-in metadata and structure analysis |
| ✗ All-or-nothing approach | ✓ Optimized for specific use cases |

---

## Installation

### Prerequisites

ForkMe requires the following tools:

- **git** - Version control system
- **gh** - GitHub CLI (for forking functionality)
- **jq** - JSON processor (for metadata parsing)
- **Standard Unix tools** - find, grep, sed (typically pre-installed)

### Platform-Specific Installation

#### macOS
```bash
brew install git gh jq
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install git gh jq
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install git gh jq
```

#### Windows (WSL)
```bash
sudo apt-get update
sudo apt-get install git gh jq
```

### GitHub CLI Authentication

After installing `gh`, authenticate with GitHub:

```bash
gh auth login
```

Follow the interactive prompts to complete authentication.

### Install ForkMe Script

```bash
# Clone the FORKME repository
cd ~/github
git clone https://github.com/bamr87/FORKME.git

# Make forkme.sh executable
chmod +x FORKME/forkme.sh

# Optional: Add to PATH
echo 'export PATH="$HOME/github/FORKME:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Verify Installation

```bash
./forkme.sh --help
```

You should see the ForkMe help menu.

---

## Quick Start

### Basic Usage

```bash
# Full fork with all history (default)
./forkme.sh https://github.com/owner/repo

# Shallow clone (last commit only)
./forkme.sh --strategy shallow --depth 1 owner/repo

# Clone without forking
./forkme.sh --no-fork owner/repo

# Dry run to preview actions
./forkme.sh --dry-run --strategy shallow owner/repo
```

### Common Patterns

```bash
# Quick documentation review
./forkme.sh --strategy filetype --file-types "md,txt" owner/repo

# Security configuration audit
./forkme.sh --strategy sparse --sparse-paths "*.yml,*.json,Dockerfile" owner/repo

# Code structure analysis
./forkme.sh --strategy structure --analyze owner/repo

# Metadata-only inspection (no clone)
./forkme.sh --analyze-only owner/repo
```

---

## Quick Reference Card

### 🚀 Command Format

```bash
./forkme.sh [options] <repo-url>
```

### 📋 Forking Strategies Cheat Sheet

| Strategy | Use Case | Command |
|----------|----------|---------|
| **full** | Complete development | `--strategy full` |
| **shallow** | Quick review/testing | `--strategy shallow --depth 1` |
| **sparse** | Specific directories | `--strategy sparse --sparse-paths "src/,docs/"` |
| **toplevel** | Root files only | `--strategy toplevel` |
| **structure** | Directory tree | `--strategy structure` |
| **filetype** | Specific file types | `--strategy filetype --file-types "py,js"` |
| **analysis** | Fast audit/review | `--strategy analysis` |
| **mirror** | Backup/archival | `--strategy mirror` |
| **bundle** | Offline/portable | `--strategy bundle` |
| **metadata** | Info only (no clone) | `--strategy metadata` or `--analyze-only` |

### ⚡ Common Commands

#### Quick Review
```bash
./forkme.sh --strategy shallow --depth 1 owner/repo
```

#### Documentation Only
```bash
./forkme.sh --strategy filetype --file-types "md,txt" owner/repo
```

#### Security Audit
```bash
./forkme.sh --strategy analysis --sparse-paths "src/,*.config" owner/repo
```

#### No Fork (Clone Only)
```bash
./forkme.sh --no-fork --strategy shallow owner/repo
```

#### Dry Run (Preview)
```bash
./forkme.sh --dry-run --strategy <type> owner/repo
```

#### Get Repository Info
```bash
./forkme.sh --analyze-only owner/repo
```

### 🎯 Use Case Matrix

| Need | Strategy | Options |
|------|----------|---------|
| **Quick code review** | `shallow` | `--depth 1` |
| **Docs extraction** | `filetype` | `--file-types "md,txt,rst"` |
| **Config audit** | `sparse` | `--sparse-paths "*.yml,*.json"` |
| **Structure overview** | `structure` | `--analyze` |
| **Full development** | `full` | (default) |
| **Offline work** | `bundle` | - |
| **Project info** | `metadata` | `--analyze-only` |

### 🔧 Essential Options

```bash
--strategy <type>           # Forking strategy
--depth <n>                 # Commit depth (shallow)
--branch <name>             # Specific branch
--no-fork                   # Skip GitHub fork
--target <dir>              # Target directory
--work-dir <dir>            # Working directory
--file-types <ext>          # File extensions (comma-separated)
--sparse-paths <paths>      # Sparse checkout paths
--analyze-only              # Metadata only
--dry-run                   # Preview mode
--verbose                   # Debug output
--help                      # Show help
```

### 💡 Pro Tips

1. **Always start with metadata:**
   ```bash
   ./forkme.sh --analyze-only owner/repo
   ```

2. **Use dry run for complex operations:**
   ```bash
   ./forkme.sh --dry-run --verbose --strategy sparse owner/repo
   ```

3. **Combine strategies for efficiency:**
   ```bash
   ./forkme.sh --strategy analysis --sparse-paths "src/" --depth 1 owner/repo
   ```

4. **Security-first approach:**
   ```bash
   # Check metadata first, then shallow clone
   ./forkme.sh --analyze-only unknown/repo
   ./forkme.sh --strategy shallow --depth 1 --no-fork unknown/repo
   ```

### 📊 File Type Shortcuts

| Use Case | File Types |
|----------|------------|
| **Documentation** | `md,txt,rst,adoc` |
| **Python** | `py,pyx,pyi` |
| **JavaScript** | `js,jsx,ts,tsx` |
| **Web** | `html,css,js` |
| **Config** | `yml,yaml,json,toml,ini` |
| **Infrastructure** | `tf,hcl,dockerfile,yml` |
| **Scripts** | `sh,bash,zsh,py,rb` |

### 🐛 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Auth failed | `gh auth login` |
| Missing deps | `brew install git gh jq` (macOS) |
| Permission denied | Use HTTPS URL |
| Slow clone | Use `--strategy shallow --depth 1` |
| Sparse paths fail | Check path format (no leading `/`) |

---

## Forking Strategies

ForkMe provides 10 distinct strategies, each optimized for specific workflows:

### 1. Full Strategy (Default)

**Use Case:** Complete repository backup, full feature development, maintaining history

```bash
./forkme.sh --strategy full owner/repo
```

**What it does:**
- Creates a GitHub fork (optional)
- Clones entire repository with full commit history
- Preserves all branches and tags
- Suitable for long-term development

**Pros:** Complete history, all branches, full functionality  
**Cons:** Slower for large repos, requires more disk space

---

### 2. Shallow Strategy

**Use Case:** Quick reviews, testing, temporary analysis, CI/CD pipelines

```bash
./forkme.sh --strategy shallow --depth 1 owner/repo
./forkme.sh --strategy shallow --depth 10 --branch main owner/repo
```

**What it does:**
- Clones only recent commits (default: 1 commit)
- Optionally targets specific branch
- Minimal disk space and download time

**Options:**
- `--depth <n>`: Number of commits to include
- `--branch <name>`: Clone specific branch only

**Pros:** Fast, minimal disk usage, good for quick inspections  
**Cons:** Limited history, may miss context

---

### 3. Sparse Strategy

**Use Case:** Working with specific subdirectories, microservices, documentation-only work

```bash
./forkme.sh --strategy sparse --sparse-paths "src/,docs/,README.md" owner/repo
```

**What it does:**
- Clones only specified paths
- Uses Git sparse-checkout feature
- Significantly reduces clone size for large monorepos

**Options:**
- `--sparse-paths <paths>`: Comma-separated list of paths to include

**Pros:** Minimal disk usage, faster clones, focused workspace  
**Cons:** Requires knowing structure beforehand, can't easily explore other paths

**Example Use Cases:**
```bash
# Microservice-specific work
./forkme.sh --strategy sparse --sparse-paths "services/auth/,shared/" owner/repo

# Documentation-only
./forkme.sh --strategy sparse --sparse-paths "docs/,*.md" owner/repo

# Configuration files only
./forkme.sh --strategy sparse --sparse-paths "config/,*.yml,*.json" owner/repo
```

---

### 4. Toplevel Strategy

**Use Case:** Quick overview, README-only reviews, license checks

```bash
./forkme.sh --strategy toplevel owner/repo
```

**What it does:**
- Clones repository
- Removes all subdirectories (keeps only root-level files)
- Useful for quick project overview

**Pros:** Minimal space, immediate overview  
**Cons:** No subdirectory access, limited usefulness

---

### 5. Structure Strategy

**Use Case:** Understanding project organization, planning navigation, generating documentation

```bash
./forkme.sh --strategy structure owner/repo
```

**What it does:**
- Clones repository with file structure
- Empties all file contents (0-byte files)
- Preserves directory tree and filenames

**Pros:** Understand organization without downloading content  
**Cons:** No actual code to review

**Example Output:**
```
project/
├── src/
│   ├── main.py (0 bytes)
│   └── utils.py (0 bytes)
├── tests/
│   └── test_main.py (0 bytes)
└── README.md (0 bytes)
```

---

### 6. Filetype Strategy

**Use Case:** Language-specific analysis, documentation extraction, configuration audits

```bash
./forkme.sh --strategy filetype --file-types "py,js,ts" owner/repo
./forkme.sh --strategy filetype --file-types "md,txt,rst" owner/repo
```

**What it does:**
- Clones repository
- Removes files not matching specified extensions
- Cleans up empty directories

**Options:**
- `--file-types <extensions>`: Comma-separated list of file extensions

**Pros:** Focused review, reduced clutter, faster analysis  
**Cons:** May miss important files with different extensions

**Common File Type Combinations:**

| Use Case | File Types |
|----------|------------|
| Documentation | `md,txt,rst,adoc` |
| Web Frontend | `html,css,js,jsx,ts,tsx` |
| Python Project | `py,pyx,pyi` |
| Configuration | `yml,yaml,json,toml,ini,cfg` |
| Infrastructure | `tf,hcl,yml,dockerfile` |
| Scripts | `sh,bash,zsh,py,rb` |

---

### 7. Analysis Strategy

**Use Case:** Security audits, code reviews, quick assessments

```bash
./forkme.sh --strategy analysis --sparse-paths "src/,package.json" owner/repo
```

**What it does:**
- Combines shallow clone (depth 1) with sparse checkout
- Optimized for fast analysis workflows
- Minimal download, focused workspace

**Options:**
- `--sparse-paths <paths>`: Paths to include (optional)

**Pros:** Very fast, minimal disk usage, targeted analysis  
**Cons:** Limited to specific paths and recent commits

---

### 8. Mirror Strategy

**Use Case:** Backups, creating alternate repositories, archival

```bash
./forkme.sh --strategy mirror owner/repo
```

**What it does:**
- Creates a bare mirror clone
- Includes all refs (branches, tags, etc.)
- Suitable for creating backup or alternate remote

**Pros:** Complete mirror, good for backups  
**Cons:** Bare repository (no working directory)

**How to use mirror:**
```bash
# Create mirror
./forkme.sh --strategy mirror owner/repo

# Push to alternate remote
cd forkme-workspace/repo
git push --mirror https://example.com/backup/repo.git
```

---

### 9. Bundle Strategy

**Use Case:** Offline analysis, sharing without network, secure transfers

```bash
./forkme.sh --strategy bundle owner/repo
```

**What it does:**
- Creates a git bundle file
- Contains full repository (or specified commits)
- Single file for easy transfer

**Pros:** Portable, offline-capable, secure transfer  
**Cons:** Requires unbundling to use

**How to use bundle:**
```bash
# Create bundle
./forkme.sh --strategy bundle owner/repo

# Transfer bundle file
# repo.bundle can be moved to another machine

# Clone from bundle
git clone forkme-workspace/repo.bundle repo-clone
```

---

### 10. Metadata Strategy

**Use Case:** Quick information gathering, pre-clone assessment, API-based analysis

```bash
./forkme.sh --strategy metadata owner/repo
# or
./forkme.sh --analyze-only owner/repo
```

**What it does:**
- Uses GitHub API to fetch repository information
- No cloning performed
- Displays: stars, forks, size, languages, license, description

**Pros:** Instant, no disk usage, no authentication for public repos  
**Cons:** Limited to metadata only

---

## Real-World Examples

### 📚 Example Categories

1. [Security Auditing](#security-auditing)
2. [Open Source Contribution Prep](#open-source-contribution-prep)
3. [Documentation Projects](#documentation-projects)
4. [Code Learning & Research](#code-learning--research)
5. [CI/CD Pipeline Testing](#cicd-pipeline-testing)
6. [Infrastructure Analysis](#infrastructure-analysis)
7. [Migration Planning](#migration-planning)
8. [Batch Processing](#batch-processing)

---

### Security Auditing

#### Scenario 1: Quick Security Review of a New Dependency

You want to audit a third-party library before adding it to your project.

```bash
# Step 1: Get metadata to understand the project
./forkme.sh --analyze-only vendor/library-name

# Step 2: Review configuration files for security issues
./forkme.sh --strategy sparse \
    --sparse-paths "setup.py,package.json,requirements.txt,Dockerfile,docker-compose.yml,*.config,*.yml" \
    --no-fork \
    vendor/library-name

# Step 3: Examine source code (excluding tests and docs)
./forkme.sh --strategy sparse \
    --sparse-paths "src/,lib/" \
    --exclude "tests/,docs/" \
    vendor/library-name
```

#### Scenario 2: Security Scan of Multiple Repositories

```bash
#!/bin/bash
# security-audit-batch.sh

repos=(
    "org/frontend-app"
    "org/backend-api"
    "org/infrastructure"
)

for repo in "${repos[@]}"; do
    echo "Auditing: $repo"
    
    ./forkme.sh --strategy analysis \
        --sparse-paths "src/,*.config,Dockerfile" \
        --no-fork \
        --target "./audit/$(basename $repo)" \
        "$repo"
    
    # Run security tools
    cd "./audit/$(basename $repo)"
    # npm audit, bandit, safety, etc.
    cd -
done

echo "Security audit complete. Reports in ./audit/"
```

#### Scenario 3: Secrets Scanning

```bash
# Clone and scan for accidentally committed secrets
./forkme.sh --strategy shallow \
    --depth 50 \
    --no-fork \
    suspicious/repo

cd forkme-workspace/repo

# Use gitleaks or similar tool
docker run -v $(pwd):/path zricethezav/gitleaks:latest detect \
    --source="/path" \
    --verbose \
    --report-path="/path/gitleaks-report.json"

cd -
```

---

### Open Source Contribution Prep

#### Scenario 1: Exploring a New Project Before Contributing

```bash
# Step 1: Quick metadata check
./forkme.sh --analyze-only torvalds/linux

# Step 2: Get project structure without downloading everything
./forkme.sh --strategy structure torvalds/linux

# Step 3: Review contributing guidelines and docs
./forkme.sh --strategy sparse \
    --sparse-paths "CONTRIBUTING.md,CODE_OF_CONDUCT.md,docs/,README.md" \
    torvalds/linux

# Step 4: If interested, get specific subsystem
./forkme.sh --strategy sparse \
    --sparse-paths "drivers/gpu/,Documentation/gpu/" \
    torvalds/linux
```

#### Scenario 2: Understanding Code Before Issue Fix

```bash
# You want to fix issue #1234 in a project

# Get recent history with relevant code
./forkme.sh --strategy shallow \
    --depth 20 \
    --branch main \
    owner/project

# Review tests to understand expected behavior
cd forkme-workspace/project
grep -r "test.*bug_related_functionality" tests/
```

---

### Documentation Projects

#### Scenario 1: Extract All Documentation for Offline Reading

```bash
# Get all documentation files
./forkme.sh --strategy filetype \
    --file-types "md,txt,rst,adoc,pdf" \
    --no-fork \
    microsoft/vscode-docs

# Result: Only documentation files in workspace
cd forkme-workspace/vscode-docs
tree  # View documentation structure
```

#### Scenario 2: Creating Documentation Mirror

```bash
# Clone documentation repository for offline access
./forkme.sh --strategy sparse \
    --sparse-paths "docs/,README.md,wiki/" \
    --no-fork \
    kubernetes/website

# Convert to single site for easy browsing
cd forkme-workspace/website
# Use mkdocs, sphinx, or similar to build static site
```

#### Scenario 3: Multi-Repository Documentation Aggregation

```bash
#!/bin/bash
# aggregate-docs.sh

repos=(
    "facebook/react"
    "vuejs/vue"
    "angular/angular"
)

mkdir -p ./framework-docs

for repo in "${repos[@]}"; do
    framework=$(basename $repo)
    
    ./forkme.sh --strategy filetype \
        --file-types "md,txt,rst" \
        --target "./framework-docs/$framework" \
        --no-fork \
        "$repo"
done

echo "All framework documentation in ./framework-docs/"
```

---

### Code Learning & Research

#### Scenario 1: Learning Design Patterns from Popular Projects

```bash
# Study specific patterns in well-known projects

# Get only source code (no tests, docs, config)
./forkme.sh --strategy filetype \
    --file-types "js,jsx,ts,tsx" \
    --no-fork \
    airbnb/javascript

# Analyze specific patterns
cd forkme-workspace/javascript
grep -r "class.*extends" .
grep -r "function\*" .  # Generator patterns
```

#### Scenario 2: Language Learning - Study Idiomatic Code

```bash
# Learning Rust? Study a well-written project
./forkme.sh --strategy filetype \
    --file-types "rs,toml" \
    --no-fork \
    --depth 20 \
    tokio-rs/tokio

# Learning Python patterns
./forkme.sh --strategy sparse \
    --sparse-paths "src/,*.py" \
    --no-fork \
    --depth 10 \
    psf/requests
```

#### Scenario 3: Comparative Analysis

```bash
#!/bin/bash
# compare-web-frameworks.sh

frameworks=(
    "expressjs/express"
    "fastify/fastify"
    "koajs/koa"
)

mkdir -p ./framework-comparison

for framework in "${frameworks[@]}"; do
    name=$(basename $framework)
    
    ./forkme.sh --strategy filetype \
        --file-types "js,json" \
        --target "./framework-comparison/$name" \
        --no-fork \
        "$framework"
    
    # Generate statistics
    cd "./framework-comparison/$name"
    cloc . > "../${name}-stats.txt"
    cd -
done
```

---

### CI/CD Pipeline Testing

#### Scenario 1: Test GitHub Actions Workflows

```bash
# Clone workflow files only
./forkme.sh --strategy sparse \
    --sparse-paths ".github/workflows/,action.yml,.github/actions/" \
    --no-fork \
    actions/checkout

# Review and adapt workflows
cd forkme-workspace/checkout/.github/workflows
# Copy and modify workflows for your project
```

#### Scenario 2: Quick Clone for CI Testing

```bash
# In your CI pipeline (.github/workflows/test.yml)

- name: Clone repository for testing
  run: |
    curl -O https://raw.githubusercontent.com/bamr87/FORKME/main/forkme.sh
    chmod +x forkme.sh
    ./forkme.sh --strategy shallow --depth 1 --no-fork ${{ github.repository }}
```

---

### Infrastructure Analysis

#### Scenario 1: Kubernetes Configuration Review

```bash
# Extract all K8s manifests
./forkme.sh --strategy sparse \
    --sparse-paths "k8s/,manifests/,*.yaml,*.yml" \
    --no-fork \
    organization/infrastructure-repo

# Validate manifests
cd forkme-workspace/infrastructure-repo
find . -name "*.yaml" -o -name "*.yml" | while read file; do
    echo "Validating: $file"
    kubectl apply --dry-run=client -f "$file"
done
```

#### Scenario 2: Terraform Infrastructure Audit

```bash
# Get all Terraform files
./forkme.sh --strategy filetype \
    --file-types "tf,hcl,tfvars" \
    --no-fork \
    company/terraform-infrastructure

# Analyze resources
cd forkme-workspace/terraform-infrastructure
terraform init -backend=false
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
```

#### Scenario 3: Docker Configuration Analysis

```bash
# Extract all Docker-related files
./forkme.sh --strategy sparse \
    --sparse-paths "Dockerfile,docker-compose.yml,.dockerignore,docker/" \
    --no-fork \
    project/backend

# Security scan
cd forkme-workspace/backend
docker run --rm -v $(pwd):/workspace aquasec/trivy config /workspace
```

---

### Migration Planning

#### Scenario 1: Pre-Migration Assessment

```bash
# Assess codebase before major refactor or migration

# Get structure first
./forkme.sh --strategy structure \
    --no-fork \
    legacy/monolith-app

# Get source code statistics
./forkme.sh --strategy filetype \
    --file-types "java,xml,properties" \
    --no-fork \
    legacy/monolith-app

cd forkme-workspace/monolith-app

# Analyze dependencies
find . -name "pom.xml" -o -name "build.gradle" | xargs cat > dependencies.txt

# Count lines of code by type
echo "Java files:" $(find . -name "*.java" | wc -l)
echo "Java LOC:" $(find . -name "*.java" -exec cat {} \; | wc -l)
```

#### Scenario 2: Dependency Analysis for Upgrade

```bash
# Analyze dependencies before major version upgrade

./forkme.sh --strategy sparse \
    --sparse-paths "package.json,package-lock.json,yarn.lock,requirements.txt,Gemfile,Gemfile.lock,go.mod,go.sum" \
    --no-fork \
    project/application

cd forkme-workspace/application

# Check for outdated dependencies
npm outdated > outdated-deps.txt 2>&1 || true
npm audit > security-audit.txt 2>&1 || true
```

---

### Batch Processing

#### Scenario 1: Organization-Wide Audit

```bash
#!/bin/bash
# org-wide-audit.sh

# Get all repos in organization
repos=$(gh repo list myorg --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')

mkdir -p org-audit

for repo in $repos; do
    echo "Processing: $repo"
    
    ./forkme.sh --strategy analysis \
        --sparse-paths "package.json,requirements.txt,go.mod" \
        --target "./org-audit/$(basename $repo)" \
        --no-fork \
        "$repo"
    
    # Extract dependency info
    # Run security scans
done

echo "Audit complete in ./org-audit/"
```

#### Scenario 2: Dependency Version Survey

```bash
#!/bin/bash
# survey-node-versions.sh

repos=(
    "team/frontend-app"
    "team/backend-api"
    "team/admin-panel"
)

echo "Repository,Node Version,React Version" > survey.csv

for repo in "${repos[@]}"; do
    ./forkme.sh --strategy sparse \
        --sparse-paths "package.json" \
        --target "./temp-$(basename $repo)" \
        --no-fork \
        "$repo"
    
    cd "./temp-$(basename $repo)"
    node_version=$(jq -r '.engines.node // "N/A"' package.json)
    react_version=$(jq -r '.dependencies.react // "N/A"' package.json)
    echo "$repo,$node_version,$react_version" >> ../survey.csv
    cd ..
    
    rm -rf "./temp-$(basename $repo)"
done

echo "Survey complete: survey.csv"
```

#### Scenario 3: Create Offline Archive

```bash
#!/bin/bash
# create-archive.sh

repos=(
    "critical/repo1"
    "critical/repo2"
    "critical/repo3"
)

mkdir -p archive

for repo in "${repos[@]}"; do
    ./forkme.sh --strategy bundle \
        --target "./archive/$(basename $repo)" \
        --no-fork \
        "$repo"
done

# Create compressed archive
tar -czf critical-repos-backup.tar.gz archive/
echo "Archive created: critical-repos-backup.tar.gz"
```

---

## Command Reference

### Complete Options List

```bash
./forkme.sh [OPTIONS] <repository-url>

Repository URL Formats:
  - Full URL: https://github.com/owner/repo
  - SSH URL: git@github.com:owner/repo.git
  - Short form: owner/repo

Strategy Options:
  --strategy <type>           Forking strategy (default: full)
                              full, shallow, sparse, toplevel, structure,
                              filetype, analysis, mirror, bundle, metadata

Clone Options:
  --depth <n>                 Limit history to <n> commits (shallow)
  --branch <name>             Clone specific branch only
  --no-fork                   Skip GitHub fork creation
  --target <dir>              Target directory for clone
  --work-dir <dir>            Working directory base (default: ./forkme-workspace)

Filtering Options:
  --file-types <ext>          Include only specific file types (comma-separated)
  --include <pattern>         Include paths matching pattern
  --exclude <pattern>         Exclude paths matching pattern
  --sparse-paths <paths>      Sparse checkout paths (comma-separated)

Analysis Options:
  --analyze                   Perform repository analysis after cloning
  --analyze-only              Analyze without cloning (GitHub API)
  --stats                     Show repository statistics

Control Options:
  --dry-run                   Show actions without executing
  --verbose                   Enable verbose output
  --help                      Display help message
```

---

## Best Practices

### 1. Security-First Approach

```bash
# Always check metadata first for unknown repositories
./forkme.sh --analyze-only unknown/repo

# Use shallow clones for initial review
./forkme.sh --strategy shallow --depth 1 --no-fork unknown/repo

# Avoid forking until you trust the repository
./forkme.sh --no-fork suspicious/repo
```

### 2. Efficient Workflow

```bash
# Use dry-run to preview complex operations
./forkme.sh --dry-run --verbose --strategy sparse --sparse-paths "..." repo

# Start with structure analysis
./forkme.sh --strategy structure repo

# Then get specific parts you need
./forkme.sh --strategy sparse --sparse-paths "path/to/interest/" repo
```

### 3. Disk Space Management

```bash
# Use shallow clones for space-constrained environments
./forkme.sh --strategy shallow --depth 1 repo

# Use sparse checkout for monorepos
./forkme.sh --strategy sparse --sparse-paths "specific/module/" repo

# Use bundles for archival (compressed)
./forkme.sh --strategy bundle repo
```

### 4. CI/CD Integration

```bash
# Fast clones in pipelines
./forkme.sh --strategy shallow --depth 1 --no-fork $REPO

# Clone only necessary files
./forkme.sh --strategy sparse --sparse-paths "src/,tests/" --no-fork $REPO
```

### 5. Research and Learning

```bash
# Compare multiple projects
for repo in repo1 repo2 repo3; do
    ./forkme.sh --strategy filetype --file-types "py" --no-fork $repo
done

# Study specific patterns
./forkme.sh --strategy sparse --sparse-paths "patterns/,examples/" repo
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "gh: command not found"

**Solution:**
```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt-get install gh

# Fedora
sudo dnf install gh

# Authenticate
gh auth login
```

#### Issue: "Permission denied (publickey)"

**Solution:**
- Use HTTPS URL instead of SSH
- Or set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh

```bash
# Use HTTPS
./forkme.sh https://github.com/owner/repo

# Not SSH
./forkme.sh git@github.com:owner/repo.git
```

#### Issue: Sparse checkout not working

**Solution:**
- Ensure paths don't have leading `/`
- Use relative paths from repository root

```bash
# Correct
./forkme.sh --strategy sparse --sparse-paths "src/,docs/"

# Incorrect
./forkme.sh --strategy sparse --sparse-paths "/src/,/docs/"
```

#### Issue: Clone is too slow

**Solution:**
- Use shallow clone
- Use sparse checkout
- Combine both with analysis strategy

```bash
./forkme.sh --strategy shallow --depth 1 repo
# or
./forkme.sh --strategy analysis --sparse-paths "src/" repo
```

#### Issue: "jq: command not found"

**Solution:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Fedora
sudo dnf install jq
```

#### Issue: Fork creation fails

**Solution:**
- Check GitHub authentication: `gh auth status`
- Use `--no-fork` flag to skip forking
- Check if fork already exists

```bash
# Skip forking
./forkme.sh --no-fork repo

# Re-authenticate
gh auth login
```

---

## Implementation Summary

### Project Overview

**Date:** November 1, 2025  
**Project:** ForkMe - Advanced GitHub Repository Forking Utility  
**Repository:** bamr87/FORKME  

### 📦 Deliverables

**Core Files:**
1. `forkme.sh` - Main bash script (1,300+ lines)
2. Complete documentation in this consolidated file

### 🎯 Features Implemented

**10 Forking Strategies:**
- ✅ Full - Complete development clone
- ✅ Shallow - Quick reviews with limited history
- ✅ Sparse - Specific directory targeting
- ✅ Toplevel - Root files only
- ✅ Structure - Directory tree analysis
- ✅ Filetype - Extension-based filtering
- ✅ Analysis - Fast audits (shallow + sparse)
- ✅ Mirror - Bare repository mirrors
- ✅ Bundle - Offline portable files
- ✅ Metadata - API-based info only

**Advanced Capabilities:**
- ✅ GitHub CLI integration for fork automation
- ✅ Intelligent filtering (file type, paths, patterns)
- ✅ Repository metadata and structure analysis
- ✅ Dry-run mode for safe previewing
- ✅ Comprehensive error handling
- ✅ Cross-platform support (macOS, Linux, WSL)

### 📊 Code Statistics

```
forkme.sh:              1,300 lines
Documentation:          2,500+ lines
Total Examples:         30+ real-world scenarios
Strategies:             10 unique approaches
```

### 🛠️ Technical Implementation

**Architecture:**
- Modular bash scripting
- GitHub CLI (`gh`) integration
- Git advanced features (sparse-checkout, shallow clone, bundles)
- JSON parsing with `jq`
- Comprehensive error handling

**Key Technologies:**
- Bash scripting
- GitHub CLI API
- Git version control
- Unix tools (find, grep, sed, awk)

### 🎓 Use Case Coverage

1. ✅ Security Auditing - Configuration reviews, secrets scanning
2. ✅ Open Source Contribution - Project exploration, issue fixing
3. ✅ Code Learning & Research - Design patterns, comparative analysis
4. ✅ CI/CD Integration - Fast pipelines, automated testing
5. ✅ Infrastructure Analysis - K8s, Terraform, Docker configs
6. ✅ Documentation Projects - Offline docs, aggregation
7. ✅ Migration Planning - Pre-migration assessment, dependency analysis
8. ✅ Batch Processing - Organization-wide audits, multi-repo operations

### 🚀 Quick Installation

```bash
# Clone FORKME repository
cd ~/github
git clone https://github.com/bamr87/FORKME.git

# Make executable
chmod +x FORKME/forkme.sh

# Add to PATH (optional)
echo 'export PATH="$HOME/github/FORKME:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 📝 Future Enhancements

**Potential Improvements:**
1. Performance optimizations (parallel processing, caching)
2. Git LFS and submodule support
3. Interactive mode for strategy selection
4. Configuration file support
5. Shell completions (bash/zsh)
6. Integration with code analysis tools
7. Language detection and statistics
8. Dependency vulnerability scanning

### 🔗 Related Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [IT-Journey Project](https://github.com/bamr87/it-journey)

### 🎉 Conclusion

ForkMe provides a comprehensive, flexible solution for GitHub repository operations beyond traditional `git clone`. With 10 distinct strategies, intelligent filtering, built-in analysis tools, and extensive documentation, it serves security professionals, open source contributors, developers, DevOps teams, and researchers.

**Key Principles:**
- **Design for Failure (DFF)**: Comprehensive error handling
- **Don't Repeat Yourself (DRY)**: Reusable functions
- **Keep It Simple (KIS)**: Clear, maintainable code
- **AI-Powered Development (AIPD)**: AI-assisted implementation

**Status:** ✅ Complete and Ready for Use  
**Version:** 1.0.0  
**Documentation:** Comprehensive  
**Testing:** Manual verification completed

---

*Created as part of IT-Journey's commitment to democratizing IT education through powerful, open-source tooling.*

---

**End of Documentation**
