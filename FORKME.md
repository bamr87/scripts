# ForkMe - Advanced GitHub Repository Forking Utility

**Version:** 1.0.0  
**Author:** IT-Journey Scripts Team  
**License:** MIT  

## 📋 Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Forking Strategies](#forking-strategies)
5. [Use Cases & Examples](#use-cases--examples)
6. [Command Reference](#command-reference)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Usage](#advanced-usage)

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
# Clone the scripts repository
cd ~/github
git clone https://github.com/bamr87/scripts.git

# Make forkme.sh executable
chmod +x scripts/forkme.sh

# Optional: Add to PATH
echo 'export PATH="$HOME/github/scripts:$PATH"' >> ~/.zshrc
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
- Creates a `.bundle` file containing entire repository
- Portable, single-file format
- Can be cloned offline

**Output:** `forkme-workspace/repo.bundle`

**Using bundles:**
```bash
# Create bundle
./forkme.sh --strategy bundle owner/repo

# Clone from bundle (offline)
git clone forkme-workspace/repo.bundle repo

# Transfer bundle securely
scp forkme-workspace/repo.bundle user@server:/path/
```

**Pros:** Offline capability, single file, secure transfer  
**Cons:** Static snapshot, requires space for temporary clone

---

### 10. Metadata Strategy

**Use Case:** Quick information gathering, project discovery, research

```bash
./forkme.sh --strategy metadata owner/repo
./forkme.sh --analyze-only owner/repo  # Shortcut
```

**What it does:**
- Queries GitHub API only (no clone)
- Displays comprehensive repository metadata
- Zero disk usage

**Information Retrieved:**
- Repository name and owner
- Description and creation date
- Size, stars, forks, watchers
- Primary language and all languages
- License information
- Fork status and parent repository

**Example Output:**
```
═══════════════════════════════════════════════════════════════
                    REPOSITORY METADATA
═══════════════════════════════════════════════════════════════
Repository: torvalds/linux
Description: Linux kernel source tree
Created: 2011-09-04T22:48:12Z
Last Updated: 2025-11-01T10:30:45Z
Last Push: 2025-11-01T09:15:22Z
Size: 3456789 KB
Stars: ⭐ 165432
Forks: 🍴 51234
Watchers: 👁️  9876
Primary Language: C
License: GPL-2.0
Private: false
Is Fork: false
═══════════════════════════════════════════════════════════════
```

**Pros:** Instant information, no cloning required, zero disk usage  
**Cons:** Metadata only, no code access

---

## Use Cases & Examples

### Security Review

**Scenario:** Audit a repository for security issues, review configuration files

```bash
# Review security-sensitive files
./forkme.sh --strategy analysis \
    --sparse-paths "src/,*.config,Dockerfile,docker-compose.yml" \
    --exclude "node_modules/,*.min.js,dist/" \
    owner/repo

# Configuration audit
./forkme.sh --strategy filetype \
    --file-types "yml,yaml,json,env,config" \
    owner/repo
```

**Why this works:**
- Fast download with analysis strategy
- Focused on security-relevant files
- Excludes generated/minified code
- Quickly identify misconfigurations

---

### Documentation Review

**Scenario:** Review project documentation, generate docs site, write tutorials

```bash
# Extract all documentation
./forkme.sh --strategy filetype \
    --file-types "md,txt,rst,adoc" \
    owner/repo

# Documentation structure only
./forkme.sh --strategy sparse \
    --sparse-paths "docs/,README.md,CONTRIBUTING.md,*.md" \
    owner/repo
```

---

### Code Structure Analysis

**Scenario:** Understand project organization before deeper dive

```bash
# Get structure only
./forkme.sh --strategy structure --analyze owner/repo

# Metadata + structure
./forkme.sh --analyze-only owner/repo
./forkme.sh --strategy structure owner/repo
```

---

### Testing & CI/CD

**Scenario:** Fast clone for automated testing pipelines

```bash
# Minimal clone for testing
./forkme.sh --strategy shallow \
    --depth 1 \
    --branch main \
    --no-fork \
    owner/repo

# Test-specific files only
./forkme.sh --strategy sparse \
    --sparse-paths "src/,tests/,package.json" \
    --no-fork \
    owner/repo
```

---

### Research & Learning

**Scenario:** Study specific parts of large projects

```bash
# Study specific module
./forkme.sh --strategy sparse \
    --sparse-paths "modules/authentication/,docs/auth/" \
    owner/large-monorepo

# Compare implementation approaches
./forkme.sh --strategy filetype \
    --file-types "py" \
    owner/python-project
```

---

### Open Source Contribution

**Scenario:** Prepare for contributing to open source project

```bash
# Full fork for development
./forkme.sh --strategy full owner/repo

# Quick exploration first
./forkme.sh --strategy shallow --depth 5 owner/repo
```

---

### Configuration Management

**Scenario:** Extract and analyze infrastructure configurations

```bash
# Kubernetes configs
./forkme.sh --strategy sparse \
    --sparse-paths "k8s/,manifests/,*.yaml" \
    owner/repo

# Terraform infrastructure
./forkme.sh --strategy filetype \
    --file-types "tf,hcl,tfvars" \
    owner/terraform-repo

# Docker environments
./forkme.sh --strategy sparse \
    --sparse-paths "Dockerfile,docker-compose.yml,.dockerignore" \
    owner/repo
```

---

### Offline Work

**Scenario:** Prepare repository for offline analysis or air-gapped environment

```bash
# Create portable bundle
./forkme.sh --strategy bundle owner/repo

# Transfer to offline environment
scp forkme-workspace/repo.bundle airgap-system:/secure/location/

# On offline system
git clone /secure/location/repo.bundle working-repo
```

---

## Command Reference

### Core Options

| Option | Description | Example |
|--------|-------------|---------|
| `--strategy <type>` | Forking strategy to use | `--strategy shallow` |
| `--depth <n>` | Commit history depth | `--depth 5` |
| `--branch <name>` | Clone specific branch | `--branch develop` |
| `--no-fork` | Skip GitHub fork creation | `--no-fork` |
| `--target <dir>` | Target directory path | `--target ./my-repo` |
| `--work-dir <dir>` | Base working directory | `--work-dir ~/projects` |

### Filtering Options

| Option | Description | Example |
|--------|-------------|---------|
| `--file-types <ext>` | Include file extensions | `--file-types "py,js"` |
| `--include <pattern>` | Include path patterns | `--include "src/*"` |
| `--exclude <pattern>` | Exclude path patterns | `--exclude "node_modules/"` |
| `--sparse-paths <p>` | Sparse checkout paths | `--sparse-paths "src/,docs/"` |

### Analysis Options

| Option | Description | Example |
|--------|-------------|---------|
| `--analyze` | Analyze after cloning | `--analyze` |
| `--analyze-only` | Metadata only (no clone) | `--analyze-only` |
| `--stats` | Show repository statistics | `--stats` |

### Control Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview without executing | `--dry-run` |
| `--verbose` | Verbose output | `--verbose` |
| `--help` | Display help | `--help` |

---

## Best Practices

### 1. Start with Metadata Analysis

Before cloning large repositories, check metadata first:

```bash
# Quick info gathering
./forkme.sh --analyze-only owner/large-repo

# If interesting, proceed with targeted clone
./forkme.sh --strategy analysis owner/large-repo
```

### 2. Use Dry Run for Complex Operations

Preview what will happen:

```bash
./forkme.sh --dry-run --strategy sparse \
    --sparse-paths "complex/path/structure/" \
    owner/repo
```

### 3. Choose the Right Strategy

| If you need... | Use strategy... |
|----------------|-----------------|
| Full development environment | `full` |
| Quick code review | `shallow` or `analysis` |
| Specific directories | `sparse` |
| Documentation only | `filetype` with `md,txt` |
| Project structure overview | `structure` |
| Backup/archival | `mirror` or `bundle` |
| Basic information | `metadata` |

### 4. Combine with Git Workflows

```bash
# Clone for feature development
./forkme.sh --strategy full owner/repo
cd forkme-workspace/repo

# Create feature branch
git checkout -b feature/new-feature

# Make changes and push to your fork
git push origin feature/new-feature
```

### 5. Clean Up After Analysis

```bash
# Remove cloned repositories
rm -rf forkme-workspace/

# Keep bundles for future use
mv forkme-workspace/*.bundle ~/backups/
```

### 6. Security Considerations

```bash
# Never clone untrusted repos with full history
# Use shallow or analysis strategy first
./forkme.sh --strategy shallow --depth 1 unknown/repo

# Review before running any code
./forkme.sh --strategy structure unknown/repo
```

---

## Troubleshooting

### Common Issues

#### 1. Authentication Failed

**Error:** `GitHub CLI not authenticated`

**Solution:**
```bash
gh auth login
# Follow interactive prompts
```

#### 2. Missing Dependencies

**Error:** `Missing required dependencies: jq`

**Solution:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

#### 3. Permission Denied

**Error:** `Permission denied (publickey)`

**Solution:**
```bash
# Use HTTPS instead of SSH
./forkme.sh https://github.com/owner/repo

# Or configure SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add to GitHub: Settings → SSH and GPG keys
```

#### 4. Large Repository Timeout

**Problem:** Clone taking too long or failing

**Solution:**
```bash
# Use shallow clone
./forkme.sh --strategy shallow --depth 1 owner/large-repo

# Or use analysis strategy
./forkme.sh --strategy analysis --sparse-paths "src/" owner/large-repo
```

#### 5. Sparse Checkout Not Working

**Error:** Sparse paths not available

**Solution:**
```bash
# Verify paths exist (check metadata first)
./forkme.sh --analyze-only owner/repo

# Use correct path format (no leading slash)
./forkme.sh --strategy sparse --sparse-paths "src/,docs/" owner/repo
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
./forkme.sh --verbose --strategy shallow owner/repo
```

### Getting Help

```bash
# Display help menu
./forkme.sh --help

# Check version and dependencies
./forkme.sh --version  # (if implemented)

# Test with dry run
./forkme.sh --dry-run --verbose --strategy <type> owner/repo
```

---

## Advanced Usage

### Custom Workflows

#### Batch Processing

```bash
#!/bin/bash
# Process multiple repositories

repos=(
    "owner1/repo1"
    "owner2/repo2"
    "owner3/repo3"
)

for repo in "${repos[@]}"; do
    ./forkme.sh --strategy shallow --depth 1 --no-fork "$repo"
done
```

#### Conditional Strategy Selection

```bash
#!/bin/bash
# Choose strategy based on repository size

repo="$1"
size=$(./forkme.sh --analyze-only "$repo" | grep "Size:" | awk '{print $2}')

if [[ $size -gt 100000 ]]; then
    strategy="analysis"
else
    strategy="full"
fi

./forkme.sh --strategy "$strategy" "$repo"
```

#### Automated Security Scans

```bash
#!/bin/bash
# Clone and scan for security issues

./forkme.sh --strategy analysis \
    --sparse-paths "src/,*.config" \
    --no-fork \
    "$1"

# Run security scanner
cd "forkme-workspace/$(basename $1)"
npm audit # or other security tools
cd -
```

### Integration with Other Tools

#### With Docker

```bash
# Clone into Docker volume
./forkme.sh --strategy shallow \
    --target /var/docker-volumes/repo \
    owner/repo

# Run analysis in container
docker run -v /var/docker-volumes/repo:/workspace analyzer
```

#### With CI/CD

```yaml
# GitHub Actions example
- name: Clone repository for testing
  run: |
    ./forkme.sh --strategy shallow \
      --depth 1 \
      --no-fork \
      --target ./test-repo \
      ${{ github.repository }}
```

#### With Code Analysis Tools

```bash
# Clone and analyze with SonarQube
./forkme.sh --strategy analysis owner/repo
cd forkme-workspace/repo
sonar-scanner -Dsonar.projectKey=myproject
```

---

## Contributing

Contributions are welcome! Please see:
- [CONTRIBUTING.md](https://github.com/bamr87/scripts/blob/main/CONTRIBUTING.md)
- [IT-Journey Copilot Instructions](https://github.com/bamr87/it-journey/blob/main/.github/copilot-instructions.md)

### Development Setup

```bash
# Clone scripts repository
git clone https://github.com/bamr87/scripts.git
cd scripts

# Make changes to forkme.sh

# Test with dry run
./forkme.sh --dry-run --verbose --strategy shallow test/repo

# Submit pull request
```

---

## License

MIT License - See [LICENSE](https://github.com/bamr87/scripts/blob/main/LICENSE) file

---

## Changelog

### Version 1.0.0 (2025-11-01)
- Initial release
- 10 forking strategies implemented
- GitHub CLI integration
- Repository analysis tools
- Comprehensive documentation

---

## Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Git Sparse Checkout Guide](https://git-scm.com/docs/git-sparse-checkout)
- [IT-Journey Documentation](https://github.com/bamr87/it-journey)

---

**Questions or Issues?**

- Open an issue: [GitHub Issues](https://github.com/bamr87/scripts/issues)
- Discussions: [GitHub Discussions](https://github.com/bamr87/scripts/discussions)
- IT-Journey Community: [IT-Journey Discussions](https://github.com/bamr87/it-journey/discussions)
