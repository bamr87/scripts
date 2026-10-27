# ForkMe - Advanced GitHub Repository Forking Utility

> The complete ForkMe guide: installation, the ten forking strategies, best practices and troubleshooting.

**License:** MIT · **Repository:** [bamr87/scripts](https://github.com/bamr87/scripts) (`FORKME/`) · **Version:** `./forkme.sh --version`

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

# Navigate to FORKME
cd scripts/FORKME

# Make forkme.sh executable
chmod +x forkme.sh

# Optional: Add to PATH
echo 'export PATH="$HOME/github/scripts/FORKME:$PATH"' >> ~/.zshrc
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

The one-page cheat sheet (strategies, common commands, use-case matrix, file-type shortcuts) is [FORKME-QUICK-REFERENCE.md](FORKME-QUICK-REFERENCE.md).

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

Step-by-step scenarios (security auditing, contribution prep, documentation, research, CI/CD, infrastructure, migration planning, batch processing) are in [FORKME-EXAMPLES.md](FORKME-EXAMPLES.md).

---

## Command Reference

`./forkme.sh --help` prints every option, grouped as strategy, clone, filtering, analysis, interactive and control options, with examples; `./forkme.sh --version` prints the version. The help text is the authoritative list, so it is not copied here.

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
