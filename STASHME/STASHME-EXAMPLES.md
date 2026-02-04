# 📚 StashMe - Real-World Examples

Practical examples for common scenarios using StashMe.

## Table of Contents

- [Daily Workflows](#daily-workflows)
- [Emergency Scenarios](#emergency-scenarios)
- [Machine Migration](#machine-migration)
- [Team Collaboration](#team-collaboration)
- [CI/CD Integration](#cicd-integration)
- [Advanced Usage](#advanced-usage)

---

## Daily Workflows

### End of Day Backup

Save all your work at the end of the day:

```bash
# Quick backup with descriptive message
./stashme.sh -m "EOD: $(date +%A) work in progress"

# Example output:
# ═══════════════════════════════════════════════════════════════
#      StashMe - Multi-Repository Cloud Stash Utility v1.0.0
# ═══════════════════════════════════════════════════════════════
#
#   Base directory: /Users/developer/github
#   Branch name:    stashme/2026-02-03-180000
#   Dry run:        false
#   Push to remote: true
#
# [STEP] Searching for git repositories in: /Users/developer/github
# [INFO] Found 12 git repositories
#
# [REPO] Processing: webapp (/Users/developer/github/webapp)
# [INFO]   Found 5 changed file(s)
# [SUCCESS]   Pushed to origin/stashme/2026-02-03-180000
# ...
```

### Morning Review

Check what you were working on:

```bash
./stashme.sh --list --verbose

# Output shows all repos with pending changes:
# [REPO] webapp (/Users/developer/github/webapp)
#    📁 webapp: 5 file(s) changed
#        M src/components/Header.tsx
#        M src/pages/Dashboard.tsx
#        M tests/Header.test.tsx
#       ?? src/components/NewFeature.tsx
#       ?? docs/feature-spec.md
```

### Weekly Cleanup

Remove old backup branches:

```bash
./stashme.sh --cleanup --interactive

# Prompts for each repo:
# [REPO] webapp
# [INFO]   Local stashme branches:
#     stashme/2026-01-27-180000
#     stashme/2026-01-28-180000
#     stashme/2026-01-29-180000
#   Delete local stashme branches? [Y/n]:
```

---

## Emergency Scenarios

### Laptop About to Die

Quick backup when battery is critical:

```bash
./stashme.sh --force -q
# Quiet mode, force push, fastest execution
```

### System Update Pending

Save everything before a major update:

```bash
./stashme.sh \
    -m "Pre-update backup: $(sw_vers -productVersion)" \
    --summary ~/Desktop/pre-update-backup.txt \
    --force
```

### Unexpected Machine Issues

When you need to switch machines urgently:

```bash
# Save with detailed tracking
./stashme.sh \
    --suffix emergency \
    -m "Emergency backup - machine issues" \
    --summary emergency-manifest.txt

# Creates branches like: stashme/2026-02-03-143021-emergency
```

---

## Machine Migration

### Step 1: Backup on Old Machine

```bash
# Create comprehensive backup
./stashme.sh \
    --dir ~ \
    --max-depth 5 \
    -m "Machine migration: $(hostname)" \
    --summary ~/Desktop/migration-manifest.txt

# Review the manifest
cat ~/Desktop/migration-manifest.txt
```

### Step 2: Clone Repos on New Machine

```bash
# Use the manifest to identify repos
# Then clone them on new machine
```

### Step 3: Restore on New Machine

```bash
# After cloning repos, restore stashed work
./stashme.sh --restore --interactive

# For each repo:
# [REPO] webapp has stashme branches:
#     stashme/2026-02-03-143021
#     origin/stashme/2026-02-03-143021
#   Restore most recent stashme branch? [y/N]: y
# [INFO]   Checking out: stashme/2026-02-03-143021
```

### Step 4: Merge Changes Back

```bash
# Manually merge stashed changes into your working branch
cd ~/github/webapp
git checkout main
git merge stashme/2026-02-03-143021
# Or cherry-pick specific commits
git cherry-pick stashme/2026-02-03-143021
```

---

## Team Collaboration

### Sharing WIP with Colleague

```bash
# Create named branch for sharing
./stashme.sh \
    --branch wip/feature-auth-handoff \
    -m "WIP: Auth feature handoff to @colleague"

# Colleague can then:
# git fetch origin
# git checkout wip/feature-auth-handoff
```

### Code Review Checkpoint

```bash
# Save current state before making review changes
./stashme.sh \
    --suffix pre-review \
    -m "State before code review changes"
```

### Sprint End Backup

```bash
# Backup all team members' work
./stashme.sh \
    --suffix sprint-42 \
    -m "Sprint 42 end - WIP backup" \
    --summary reports/sprint-42-wip.txt
```

---

## CI/CD Integration

### Pre-Deploy Backup Script

```bash
#!/bin/bash
# pre-deploy-backup.sh

echo "Creating pre-deploy backup..."

./stashme.sh \
    --dir /home/deploy/projects \
    --suffix "pre-deploy-$(date +%Y%m%d-%H%M)" \
    -m "Pre-deploy backup: $DEPLOY_VERSION" \
    --summary /var/log/deploy-backups/$(date +%Y%m%d).txt \
    --quiet

if [ $? -eq 0 ]; then
    echo "Backup successful"
else
    echo "Backup had issues, check logs"
fi
```

### Scheduled Backup (Cron)

```bash
# Add to crontab
# Daily at 6 PM
0 18 * * * /usr/local/bin/stashme.sh -q --summary /var/log/stashme/daily-$(date +\%Y\%m\%d).txt

# Weekly cleanup on Sundays
0 10 * * 0 /usr/local/bin/stashme.sh --cleanup -q
```

### GitHub Actions Integration

```yaml
# .github/workflows/backup-wip.yml
name: Backup Work in Progress

on:
  schedule:
    - cron: '0 18 * * *'  # Daily at 6 PM UTC
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run StashMe
        run: |
          ./scripts/STASHME/stashme.sh \
            --suffix "ci-backup" \
            -m "Automated CI backup" \
            --dry-run  # Remove for actual backup
```

---

## Advanced Usage

### Custom Directory Structure

```bash
# Backup only frontend projects
./stashme.sh ~/projects/frontend --prefix frontend-wip

# Backup only backend projects  
./stashme.sh ~/projects/backend --prefix backend-wip

# Backup personal vs work separately
./stashme.sh ~/personal --prefix personal
./stashme.sh ~/work --prefix work
```

### Filtered Backup with Verbose Output

```bash
./stashme.sh \
    --verbose \
    --max-depth 2 \
    --include-hidden \
    ~/development

# Shows detailed information:
# [DEBUG] Found repo: /Users/dev/development/project-a
# [DEBUG] Found repo: /Users/dev/development/.dotfiles
# [DEBUG]   Current branch: main
# [DEBUG]   Creating branch: stashme/2026-02-03-143021
# [DEBUG]   Adding all changes...
# [DEBUG]   Committing changes...
# [DEBUG]   Returning to original branch: main
# [DEBUG]   Pushing: git push origin stashme/2026-02-03-143021
```

### Conditional Backup Script

```bash
#!/bin/bash
# smart-backup.sh

# Only backup if there are actually changes
CHANGES=$(./stashme.sh --list --quiet 2>&1 | grep -c "file(s) changed")

if [ "$CHANGES" -gt 0 ]; then
    echo "Found $CHANGES repos with changes, backing up..."
    ./stashme.sh -m "Auto-backup: $(date)"
else
    echo "No uncommitted changes found, skipping backup"
fi
```

### Integration with Git Hooks

```bash
# .git/hooks/pre-rebase (in each repo)
#!/bin/bash
# Backup before rebase operations

echo "Backing up before rebase..."
/usr/local/bin/stashme.sh \
    --dir "$(git rev-parse --show-toplevel)" \
    --max-depth 1 \
    --suffix "pre-rebase" \
    -q
```

### Multiple Environments

```bash
# Development environment
./stashme.sh ~/dev --prefix dev-wip

# Staging environment
./stashme.sh ~/staging --prefix staging-wip

# Production hotfixes
./stashme.sh ~/production --prefix hotfix-wip
```

---

## Output Examples

### Successful Run

```
═══════════════════════════════════════════════════════════════
     StashMe - Multi-Repository Cloud Stash Utility v1.0.0
═══════════════════════════════════════════════════════════════

  Base directory: /Users/developer/github
  Branch name:    stashme/2026-02-03-143021
  Dry run:        false
  Push to remote: true

[STEP] Searching for git repositories in: /Users/developer/github
[INFO] Found 8 git repositories

[REPO] Processing: webapp (/Users/developer/github/webapp)
[INFO]   Found 3 changed file(s)
[SUCCESS]   Pushed to origin/stashme/2026-02-03-143021

[REPO] Processing: api-server (/Users/developer/github/api-server)
[DEBUG]   No uncommitted changes, skipping

[REPO] Processing: mobile-app (/Users/developer/github/mobile-app)
[INFO]   Found 7 changed file(s)
[SUCCESS]   Pushed to origin/stashme/2026-02-03-143021

═══════════════════════════════════════════════════════════════
                         SUMMARY
═══════════════════════════════════════════════════════════════

  Repositories found:        8
  Repositories with changes: 2
  Successfully stashed:      2
  Successfully pushed:       2
  Skipped (no changes/user): 6
  Failed:                    0
```

### Dry Run Output

```
═══════════════════════════════════════════════════════════════
     StashMe - Multi-Repository Cloud Stash Utility v1.0.0
═══════════════════════════════════════════════════════════════

  Base directory: /Users/developer/github
  Branch name:    stashme/2026-02-03-143021
  Dry run:        true
  Push to remote: true

[REPO] Processing: webapp (/Users/developer/github/webapp)
[INFO]   Found 3 changed file(s)
[INFO]   [DRY RUN] Would create branch: stashme/2026-02-03-143021
[INFO]   [DRY RUN] Would commit 3 file(s)
[INFO]   [DRY RUN] Would push to origin
```

---

**Full docs:** [STASHME.md](STASHME.md) | **Quick Reference:** [STASHME-QUICK-REFERENCE.md](STASHME-QUICK-REFERENCE.md)
