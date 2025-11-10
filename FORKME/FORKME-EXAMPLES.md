# ForkMe Real-World Examples

This document provides practical, real-world examples of using ForkMe for various scenarios.

## 📚 Table of Contents

1. [Security Auditing](#security-auditing)
2. [Open Source Contribution Prep](#open-source-contribution-prep)
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
    --exclude "tests/,docs/,examples/" \
    --no-fork \
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
    
    # Clone security-sensitive files only
    ./forkme.sh --strategy analysis \
        --sparse-paths "src/,config/,*.env.example,Dockerfile,docker-compose.yml" \
        --exclude "node_modules/,dist/,build/" \
        --no-fork \
        --target "./audit/$(basename $repo)" \
        "$repo"
    
    # Run security scanner (example with npm audit)
    cd "./audit/$(basename $repo)"
    if [ -f "package.json" ]; then
        npm audit --json > ../security-report-$(basename $repo).json
    fi
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
    --report-format="json" \
    --report-path="/path/gitleaks-report.json"

cd -
```

---

## Open Source Contribution Prep

### Scenario 1: Exploring a New Project Before Contributing

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

### Scenario 2: Understanding Code Before Issue Fix

```bash
# You want to fix issue #1234 in a project

# Get recent history with relevant code
./forkme.sh --strategy shallow \
    --depth 20 \
    --sparse-paths "src/module-with-bug/,tests/module-with-bug/" \
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
    microsoft/vscode-docs

# Result: Only documentation files in workspace
cd forkme-workspace/vscode-docs
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
    "vuejs/core"
    "angular/angular"
)

mkdir -p ./framework-docs

for repo in "${repos[@]}"; do
    framework=$(basename $repo)
    
    ./forkme.sh --strategy filetype \
        --file-types "md,mdx" \
        --no-fork \
        --target "./framework-docs/$framework" \
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
    --target ./rust-learning/tokio \
    tokio-rs/tokio

# Learning Python patterns
./forkme.sh --strategy sparse \
    --sparse-paths "src/,*.py" \
    --exclude "tests/,docs/" \
    --no-fork \
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
    
    # Get only source code
    ./forkme.sh --strategy sparse \
        --sparse-paths "lib/,src/,index.js" \
        --no-fork \
        --target "./framework-comparison/$name" \
        "$framework"
    
    # Analyze complexity
    cd "./framework-comparison/$name"
    echo "=== $name ===" >> ../metrics.txt
    echo "Files: $(find . -name '*.js' | wc -l)" >> ../metrics.txt
    echo "Lines: $(find . -name '*.js' -exec cat {} \; | wc -l)" >> ../metrics.txt
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

```bash
# In your CI pipeline (.github/workflows/test.yml)

- name: Clone repository for testing
  run: |
    curl -fsSL https://raw.githubusercontent.com/bamr87/scripts/main/forkme.sh -o forkme.sh
    chmod +x forkme.sh
    
    # Fast shallow clone
    ./forkme.sh --strategy shallow \
      --depth 1 \
      --no-fork \
      --target ./test-repo \
      ${{ github.repository }}
    
    # Run tests
    cd test-repo
    npm test
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
    
    # Get metadata
    ./forkme.sh --analyze-only "$repo" > "org-audit/${repo//\//-}-metadata.txt"
    
    # Get structure for analysis
    ./forkme.sh --strategy structure \
        --no-fork \
        --target "org-audit/${repo//\//-}" \
        "$repo" 2>/dev/null || echo "Failed: $repo"
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
        --no-fork \
        --target "./temp-$(basename $repo)" \
        "$repo"
    
    cd "./temp-$(basename $repo)"
    
    node_version=$(jq -r '.engines.node // "unknown"' package.json)
    react_version=$(jq -r '.dependencies.react // "none"' package.json)
    
    echo "$repo,$node_version,$react_version" >> ../survey.csv
    
    cd -
    rm -rf "./temp-$(basename $repo)"
done

echo "Survey complete: survey.csv"
```

### Scenario 3: Create Offline Archive

```bash
#!/bin/bash
# create-offline-archive.sh

repos=(
    "critical/app-1"
    "critical/app-2"
    "critical/database-schemas"
)

archive_dir="./offline-archive-$(date +%Y%m%d)"
mkdir -p "$archive_dir"

for repo in "${repos[@]}"; do
    echo "Archiving: $repo"
    
    # Create git bundle for complete offline access
    ./forkme.sh --strategy bundle \
        --target "$archive_dir/$(basename $repo)" \
        "$repo"
done

# Create archive
tar -czf "offline-archive-$(date +%Y%m%d).tar.gz" "$archive_dir"

echo "Offline archive created: offline-archive-$(date +%Y%m%d).tar.gz"
```

---

## Advanced Workflows

### Combining with Other Tools

#### With ripgrep for Code Search

```bash
# Clone and search for specific patterns
./forkme.sh --strategy filetype \
    --file-types "js,ts" \
    --no-fork \
    facebook/react

cd forkme-workspace/react
rg "useState|useEffect" --stats
```

#### With git-sizer for Repository Analysis

```bash
# Analyze repository size and complexity
./forkme.sh --strategy full \
    --no-fork \
    large/repository

cd forkme-workspace/repository
git-sizer --verbose
```

#### With CodeQL for Security Analysis

```bash
# Clone and run CodeQL analysis
./forkme.sh --strategy shallow \
    --depth 1 \
    --no-fork \
    target/project

cd forkme-workspace/project
codeql database create codeql-db --language=javascript
codeql database analyze codeql-db --format=sarif-latest --output=results.sarif
```

---

## Tips for Efficient Usage

1. **Always start with metadata** for unknown repositories:
   ```bash
   ./forkme.sh --analyze-only unknown/repo
   ```

2. **Use dry-run** for complex operations:
   ```bash
   ./forkme.sh --dry-run --verbose --strategy sparse owner/repo
   ```

3. **Combine strategies** for efficiency:
   ```bash
   # Fast analysis with specific focus
   ./forkme.sh --strategy analysis --sparse-paths "src/" --depth 1
   ```

4. **Clean up regularly**:
   ```bash
   rm -rf forkme-workspace/
   ```

5. **Script repetitive tasks** - see batch processing examples above

---

## Troubleshooting Real-World Issues

### Issue: Repository Too Large

```bash
# Solution: Use analysis strategy with specific paths
./forkme.sh --strategy analysis \
    --sparse-paths "path/to/relevant/code" \
    --depth 1 \
    huge/repository
```

### Issue: Need Specific Historical Context

```bash
# Solution: Increase depth for more commits
./forkme.sh --strategy shallow \
    --depth 50 \
    --branch main \
    owner/repo
```

### Issue: Multiple File Types Needed

```bash
# Solution: Combine file types
./forkme.sh --strategy filetype \
    --file-types "py,js,yaml,json,md" \
    owner/repo
```

---

**For more examples and scenarios, see:**
- [Full ForkMe Documentation](FORKME.md)
- [Quick Reference Card](FORKME-QUICK-REFERENCE.md)
- [GitHub Issues for Community Examples](https://github.com/bamr87/scripts/issues)
