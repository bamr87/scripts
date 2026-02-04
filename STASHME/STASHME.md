# 💾 StashMe - Complete Documentation

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Options](#options)
- [Modes](#modes)
- [Branch Naming](#branch-naming)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Overview

StashMe is a powerful utility that saves uncommitted changes across multiple git repositories to remote backup branches. It's designed for scenarios where you need to quickly save all your open work to the cloud - like going on vacation, switching machines, or creating emergency backups.

### Why StashMe?

| Problem | StashMe Solution |
|---------|------------------|
| Multiple repos with uncommitted changes | Single command saves all |
| Need to switch machines | Changes synced to cloud |
| Want to preserve WIP without committing to main | Uses separate backup branches |
| Forget what you were working on | Lists all repos with changes |
| Need to recover old work | Restore mode retrieves changes |

### How It Works

```
                    ┌─────────────────────────────────────┐
                    │         Your Working Tree          │
                    │  (uncommitted changes preserved)   │
                    └─────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Find Repos    │───▶│  Create Branch  │───▶│  Commit & Push  │
│  with changes   │    │ stashme/date-ts │    │   to origin     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────────┐
                    │         GitHub (origin)            │
                    │  branch: stashme/2026-02-03-143021 │
                    └─────────────────────────────────────┘
```

## Installation

### Prerequisites

- **git** (version 2.0 or higher)
- **bash** (version 4.0 or higher)
- Remote repository (`origin`) configured for each repo you want to back up

### Setup

```bash
# Option 1: Clone scripts repository
git clone https://github.com/bamr87/scripts.git
cd scripts/STASHME
chmod +x stashme.sh

# Option 2: Download directly
curl -O https://raw.githubusercontent.com/bamr87/scripts/main/STASHME/stashme.sh
chmod +x stashme.sh

# Optional: Add to PATH for global access
sudo ln -s "$(pwd)/stashme.sh" /usr/local/bin/stashme
# Or add to your shell profile
echo 'alias stashme="/path/to/stashme.sh"' >> ~/.zshrc
```

### Verify Installation

```bash
./stashme.sh --version
./stashme.sh --help
```

## Quick Start

### Basic Usage

```bash
# Stash all repos in ~/github (default location)
./stashme.sh

# Stash repos in a specific directory
./stashme.sh ~/projects

# Preview what would happen (dry run)
./stashme.sh --dry-run

# List repos with uncommitted changes
./stashme.sh --list
```

### Common Workflows

**Before Going on Vacation:**
```bash
./stashme.sh -m "WIP: saving before vacation" --summary vacation-backup.txt
```

**Emergency Backup:**
```bash
./stashme.sh --force  # Force push even if branch exists
```

**New Machine Setup:**
```bash
# On old machine
./stashme.sh --summary backup-manifest.txt

# On new machine (after cloning repos)
./stashme.sh --restore
```

## Options

### Directory Options

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --dir <path>` | Base directory to search | `~/github` |
| `--max-depth <n>` | Maximum directory depth | `3` |
| `--include-hidden` | Include hidden directories | `false` |

### Branch Options

| Option | Description | Default |
|--------|-------------|---------|
| `-b, --branch <name>` | Custom branch name | Auto-generated |
| `--prefix <prefix>` | Branch name prefix | `stashme` |
| `--suffix <suffix>` | Branch name suffix | None |

### Commit Options

| Option | Description | Default |
|--------|-------------|---------|
| `-m, --message <msg>` | Custom commit message | Auto-generated |
| `--no-push` | Don't push to remote | `false` |
| `-f, --force` | Force push | `false` |

### Mode Options

| Option | Description |
|--------|-------------|
| `-l, --list` | List repos with changes (no action) |
| `-r, --restore` | Restore mode: checkout stashme branches |
| `--cleanup` | Cleanup mode: delete stashme branches |
| `-i, --interactive` | Confirm before each action |

### Output Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output |
| `-q, --quiet` | Suppress non-error output |
| `--dry-run` | Preview without executing |
| `--summary <file>` | Write summary to file |

## Modes

### Default Mode (Stash)

Creates backup branches and pushes changes to remote:

```bash
./stashme.sh ~/github
```

### List Mode

Shows repos with uncommitted changes without taking action:

```bash
./stashme.sh --list

# Output:
# [REPO] project-a (/Users/you/github/project-a)
#    📁 project-a: 3 file(s) changed
#        M src/main.py
#        M tests/test_main.py
#       ?? new-file.txt
```

### Restore Mode

Helps recover previously stashed changes:

```bash
./stashme.sh --restore

# For each repo with stashme branches:
# - Lists available stashme branches
# - Offers to checkout the most recent one
```

### Cleanup Mode

Removes old stashme branches:

```bash
./stashme.sh --cleanup

# For each repo:
# - Lists local stashme branches
# - Offers to delete local branches
# - Lists remote stashme branches
# - Offers to delete remote branches
```

### Interactive Mode

Confirms before each action:

```bash
./stashme.sh --interactive

# Prompts before:
# - Stashing each repo
# - Restoring branches
# - Deleting branches
```

## Branch Naming

### Default Format

```
stashme/YYYY-MM-DD-HHMMSS
```

Example: `stashme/2026-02-03-143021`

### Custom Naming

```bash
# Custom prefix
./stashme.sh --prefix backup
# Creates: backup/2026-02-03-143021

# Custom suffix
./stashme.sh --suffix pre-vacation
# Creates: stashme/2026-02-03-143021-pre-vacation

# Fully custom branch
./stashme.sh --branch wip/emergency-backup
# Creates: wip/emergency-backup
```

### Commit Message Format

Default commit message:

```
StashMe: Auto-saved changes from main at 2026-02-03 14:30:21

Original branch: main
Saved by: stashme.sh v1.0.0
Host: macbook-pro.local
User: developer
```

Custom message:

```bash
./stashme.sh -m "WIP: implementing feature X"
```

## Examples

See [STASHME-EXAMPLES.md](STASHME-EXAMPLES.md) for comprehensive examples.

### Quick Examples

```bash
# Basic stash
./stashme.sh

# Stash specific directory
./stashme.sh ~/work/projects

# Verbose dry run
./stashme.sh --dry-run --verbose

# Force push with custom message
./stashme.sh --force -m "Emergency backup before system update"

# Generate backup manifest
./stashme.sh --summary ~/Desktop/backup-$(date +%Y%m%d).txt
```

## Best Practices

### 1. Regular Backups

Create a cron job or alias for regular backups:

```bash
# Add to crontab (daily at 6 PM)
0 18 * * * /path/to/stashme.sh -q --summary ~/backups/stash-$(date +\%Y\%m\%d).txt
```

### 2. Use Meaningful Messages

```bash
# Instead of default message
./stashme.sh -m "WIP: user authentication feature, need to add tests"
```

### 3. Review Before Pushing

```bash
# First, see what would be stashed
./stashme.sh --list

# Then dry run
./stashme.sh --dry-run

# Finally, execute
./stashme.sh
```

### 4. Clean Up Regularly

```bash
# Weekly cleanup of old stashme branches
./stashme.sh --cleanup
```

### 5. Use Interactive Mode for Important Operations

```bash
./stashme.sh --interactive --cleanup
```

## Troubleshooting

### "No remote 'origin' configured"

The repo doesn't have a push destination:

```bash
# Add remote
cd /path/to/repo
git remote add origin git@github.com:username/repo.git
```

### "Failed to push"

Common causes:
- No network connection
- Authentication issues
- Branch already exists (use `--force`)

```bash
# Force push to overwrite
./stashme.sh --force

# Or check git credentials
git credential-helper
gh auth status
```

### "No git repositories found"

Check the directory path and depth:

```bash
# Increase search depth
./stashme.sh --max-depth 5

# Include hidden directories
./stashme.sh --include-hidden

# Verify repos exist
find ~/github -name ".git" -type d
```

### "Permission denied"

```bash
# Make script executable
chmod +x stashme.sh

# Check directory permissions
ls -la ~/github
```

## FAQ

**Q: Does this modify my working branch?**
A: No. StashMe creates a new branch, commits there, then returns to your original branch. Your working tree remains unchanged.

**Q: What about untracked files?**
A: All untracked files (not in `.gitignore`) are included in the stash.

**Q: Can I use this with private repos?**
A: Yes, as long as you have push access to the remote.

**Q: How do I get my changes back?**
A: Use `--restore` mode, or manually:
```bash
git fetch origin
git checkout stashme/2026-02-03-143021
# Or cherry-pick
git cherry-pick stashme/2026-02-03-143021
```

**Q: What if the branch already exists?**
A: The script will fail unless you use `--force` to overwrite.

**Q: Can I exclude certain repos?**
A: Not directly, but you can:
1. Use `--interactive` mode to skip repos
2. Organize repos into separate directories

**Q: Does this work with submodules?**
A: Submodules are treated as separate repos if they have their own `.git` directory.

---

**Version:** 1.0.0 | **Last Updated:** 2026-02-03
