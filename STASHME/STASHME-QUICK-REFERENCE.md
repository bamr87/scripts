# 📋 StashMe Quick Reference Card

## Basic Commands

```bash
# Stash all repos in ~/github
stashme.sh

# Stash repos in specific directory
stashme.sh ~/projects

# List repos with changes (no action)
stashme.sh --list

# Dry run (preview only)
stashme.sh --dry-run
```

## Common Options

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--dir <path>` | Base directory |
| `-b` | `--branch <name>` | Custom branch name |
| `-m` | `--message <msg>` | Custom commit message |
| `-l` | `--list` | List mode (no action) |
| `-r` | `--restore` | Restore mode |
| `-i` | `--interactive` | Confirm each action |
| `-v` | `--verbose` | Verbose output |
| `-q` | `--quiet` | Quiet mode |
| `-f` | `--force` | Force push |
| `-h` | `--help` | Show help |

## Modes

```bash
# Stash mode (default)
stashme.sh

# List mode
stashme.sh --list

# Restore mode
stashme.sh --restore

# Cleanup mode
stashme.sh --cleanup
```

## Branch Naming

```bash
# Default: stashme/YYYY-MM-DD-HHMMSS
stashme.sh
# → stashme/2026-02-03-143021

# Custom prefix
stashme.sh --prefix backup
# → backup/2026-02-03-143021

# Custom suffix
stashme.sh --suffix pre-vacation
# → stashme/2026-02-03-143021-pre-vacation

# Fully custom
stashme.sh --branch wip/feature-x
# → wip/feature-x
```

## Common Workflows

### Before Vacation
```bash
stashme.sh -m "WIP: saving before vacation" --summary backup.txt
```

### Emergency Backup
```bash
stashme.sh --force
```

### Check Pending Work
```bash
stashme.sh --list --verbose
```

### Recover Saved Work
```bash
stashme.sh --restore --interactive
```

### Clean Up Old Backups
```bash
stashme.sh --cleanup
```

### Dry Run Everything
```bash
stashme.sh --dry-run --verbose
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Partial success (some failed) |
| `2` | Invalid arguments |
| `3` | No repos found |
| `4` | All repos failed |

## Tips

```bash
# Add alias to shell
echo 'alias stash="~/scripts/STASHME/stashme.sh"' >> ~/.zshrc

# Create backup manifest
stashme.sh --summary ~/backups/stash-$(date +%Y%m%d).txt

# Verbose dry run before actual run
stashme.sh --dry-run -v && stashme.sh

# Interactive cleanup
stashme.sh --cleanup -i
```

## Directory Structure Default

```
~/github/           ← Default search location
├── repo-a/         
├── repo-b/         
└── subfolder/      
    └── repo-c/     ← Found with --max-depth 2+
```

---

**Full docs:** [STASHME.md](STASHME.md) | **Examples:** [STASHME-EXAMPLES.md](STASHME-EXAMPLES.md)
