# ForkMe Real-World Examples

This document provides practical, real-world examples of using ForkMe for various scenarios.

## 📚 Table of Contents

1. [Security Auditing](#security-auditing)
2. [Open Source Contribution](#open-source-contribution)
3. [Documentation Projects](#documentation-projects)
4. [Code Learning & Research](#code-learning--research)
5. [CI/CD Pipeline Testing](#cicd-pipeline-testing)
6. [Infrastructure Analysis](#infrastructure-analysis)
7. [Migration Planning](#migration-planning)
8. [Batch Processing](#batch-processing)

---

## Security Auditing

### Scenario 1: Quick Security Review of a New Dependency

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
    vendor/library-name
```

### Scenario 2: Security Scan of Multiple Repositories

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

### Scenario 3: Secrets Scanning

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

## Open Source Contribution

### Scenario 1: Exploring a New Project Before Contributing

```bash
# Step 1: Quick metadata check
./forkme.sh --analyze-only microsoft/vscode

# Step 2: Get project structure without downloading everything
./forkme.sh --strategy structure microsoft/vscode

# Step 3: Review contributing guidelines and docs
./forkme.sh --strategy sparse \
    --sparse-paths "CONTRIBUTING.md,CODE_OF_CONDUCT.md,docs/,README.md" \
    microsoft/vscode

# Step 4: If interested, get specific subsystem
./forkme.sh --strategy sparse \
    --sparse-paths "src/vs/editor/,docs/editor/" \
    microsoft/vscode
```

### Scenario 2: Understanding Code Before Issue Fix

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

## Documentation Projects

### Scenario 1: Extract All Documentation for Offline Reading

```bash
# Get all documentation files
./forkme.sh --strategy filetype \
    --file-types "md,txt,rst,adoc,pdf" \
    --no-fork \
    kubernetes/website

# Result: Only documentation files in workspace
cd forkme-workspace/website
tree  # View documentation structure
```

### Scenario 2: Creating Documentation Mirror

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

### Scenario 3: Multi-Repository Documentation Aggregation

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

## Code Learning & Research

### Scenario 1: Learning Design Patterns from Popular Projects

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

### Scenario 2: Language Learning - Study Idiomatic Code

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

### Scenario 3: Comparative Analysis

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

## CI/CD Pipeline Testing

### Scenario 1: Test GitHub Actions Workflows

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

### Scenario 2: Quick Clone for CI Testing

```yaml
# In your CI pipeline (.github/workflows/test.yml)

- name: Clone repository for testing
  run: |
    curl -O https://raw.githubusercontent.com/bamr87/it-journey/main/scripts/FORKME/forkme.sh
    chmod +x forkme.sh
    ./forkme.sh --strategy shallow --depth 1 --no-fork ${{ github.repository }}
```

---

## Infrastructure Analysis

### Scenario 1: Kubernetes Configuration Review

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

### Scenario 2: Terraform Infrastructure Audit

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

### Scenario 3: Docker Configuration Analysis

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

## Migration Planning

### Scenario 1: Pre-Migration Assessment

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

### Scenario 2: Dependency Analysis for Upgrade

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

## Batch Processing

### Scenario 1: Organization-Wide Audit

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

### Scenario 2: Dependency Version Survey

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

### Scenario 3: Create Offline Archive

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

## Advanced Patterns

### Pattern 1: Two-Stage Security Review

```bash
# Stage 1: Metadata and structure (no code download)
./forkme.sh --analyze-only suspicious/repo
./forkme.sh --strategy structure --no-fork suspicious/repo

# Stage 2: If safe, get specific files
./forkme.sh --strategy sparse \
    --sparse-paths "src/,package.json" \
    --no-fork \
    suspicious/repo
```

### Pattern 2: Progressive Download

```bash
# Level 1: Top-level files only
./forkme.sh --strategy toplevel --no-fork owner/large-repo

# Level 2: Add specific directories
./forkme.sh --strategy sparse \
    --sparse-paths "src/core/,docs/" \
    --no-fork \
    owner/large-repo

# Level 3: Full clone if needed
./forkme.sh --strategy full owner/large-repo
```

### Pattern 3: Multi-Format Analysis

```bash
# Get structure
./forkme.sh --strategy structure --target ./project-structure owner/repo

# Get docs
./forkme.sh --strategy filetype \
    --file-types "md,txt" \
    --target ./project-docs \
    --no-fork \
    owner/repo

# Get code
./forkme.sh --strategy filetype \
    --file-types "py,js" \
    --target ./project-code \
    --no-fork \
    owner/repo
```

---

**For more information, see [FORKME.md](FORKME.md)**
