# Rename Directory Utility - Quick Reference

> How to use rename-directory.sh: common renames, previews and unattended runs, the pre-flight checks and prompts, what is preserved, follow-up steps and recovering from a backup.

## Basic Usage

```bash
~/github/scripts/rename-directory.sh [--dry-run] [-y|--yes] [--backup|--no-backup] <source> <target>
```

| Option | Effect |
| --- | --- |
| `--dry-run` | Runs the pre-flight checks read-only (paths, permissions, `docker ps`, `git status`) and prints what would happen. It never prompts, stops a container, copies or moves anything. |
| `-y`, `--yes` | Answers yes to the stop-containers and uncommitted-changes prompts and takes the backup unless `--no-backup` is given, so the rename runs unattended. |
| `--backup` | Creates the backup without asking. |
| `--no-backup` | Skips the backup without asking. |
| `-h`, `--help` | Prints the usage; `--help` is the authoritative flag list. |

## Preview and Unattended Runs

```bash
# See what would happen; nothing changes
~/github/scripts/rename-directory.sh --dry-run ~/github/old-project ~/github/new-project

# Scripts and cron: stop related containers, back up, rename
~/github/scripts/rename-directory.sh --yes ~/github/old-project ~/github/new-project

# The same without the backup
~/github/scripts/rename-directory.sh --yes --no-backup ~/github/old-project ~/github/new-project
```

Unattended mode is never less safe than answering by hand: `--yes` takes the backup unless you opt out with `--no-backup`. Without `--yes` or `--backup`/`--no-backup`, every prompt is read from stdin, and when there is no stdin to answer from (CI, cron) the run stops with an error before anything has changed. If piped answers run out partway, it stops before copying or moving anything, and the error names any containers an earlier answer already stopped.

## Common Examples

### Rename a Project
```bash
~/github/scripts/rename-directory.sh ~/github/old-project ~/github/new-project
```

### Rebrand Application
```bash
~/github/scripts/rename-directory.sh ~/github/posthog ~/github/bashog
```

### Reorganize Workspace
```bash
~/github/scripts/rename-directory.sh ~/projects/legacy-app ~/projects/app-v2
```

## Pre-Flight Checklist

✅ Source directory exists  
✅ Target directory doesn't exist  
✅ Parent directory has write permissions  
✅ Related Docker containers are identified  
✅ Git repository status is checked  
✅ Uncommitted changes are reviewed  

## Interactive Prompts

1. **Stop Docker containers?** (if found)
   - Recommended: `yes`
   - Pre-answered `yes` by `--yes`
   
2. **Continue with uncommitted changes?** (if found)
   - Review changes first
   - Commit or stash changes if possible
   - Pre-answered `yes` by `--yes`
   
3. **Create backup?**
   - Recommended: `yes` (especially for important projects)
   - Backup location: `<source>-backup-YYYYMMDD-HHMMSS`
   - Pre-answered by `--backup` or `--no-backup`; `--yes` alone means `yes`

## What Gets Preserved

✅ Git repository and history  
✅ File permissions and ownership  
✅ Directory structure  
✅ All file contents  
✅ Hidden files (`.git`, `.env`, etc.)  

## Post-Rename Actions

### VS Code
- Close workspace
- Open new location: `code <new-path>`

### Terminal Sessions
```bash
cd <new-path>
```

### Git Remote URLs (if applicable)
```bash
cd <new-path>
git remote set-url origin <new-repository-url>
```

### Docker Containers
```bash
# Rebuild with new name
docker-compose up --build -d
```

## Common Issues

### "Target directory already exists"
```bash
# Remove or rename existing target
rm -rf <target-path>  # OR
mv <target-path> <target-path>-old
```

### "Permission denied"
```bash
# Check directory permissions
ls -la $(dirname <source-path>)
ls -la $(dirname <target-path>)
```

### Git repository issues
```bash
# Check git status first
cd <source-path>
git status

# Commit changes
git add .
git commit -m "Checkpoint before rename"
```

## Backup Management

### Check backup size
```bash
du -sh <backup-directory>
```

### Remove backup (after verification)
```bash
rm -rf <backup-directory>
```

### Restore from backup (if needed)
```bash
rm -rf <target-path>
mv <backup-directory> <source-path>
```

## Safety Features

🔒 Won't overwrite existing directories  
🔒 Checks permissions before proceeding  
🔒 Preserves git history and configuration  
🔒 Stops Docker containers to prevent conflicts  
🔒 Warns about uncommitted changes  
🔒 Verifies successful rename  

## Tips

- **Always create a backup** for production or important projects
- **Commit git changes** before renaming
- **Close IDEs and terminals** in the source directory
- **Update environment variables** after rename
- **Test thoroughly** after rename

## Getting Help

```bash
~/github/scripts/rename-directory.sh --help
```

## Return Codes

- `0` - Success
- `1` - Error (check error message for details)

---

**Tip**: Add the scripts directory to your PATH for easier access:
```bash
echo 'export PATH="$PATH:~/github/scripts"' >> ~/.zshrc
source ~/.zshrc
# Then use: rename-directory.sh <source> <target>
```
