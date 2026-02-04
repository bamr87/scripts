# 💾 StashMe - Multi-Repository Cloud Stash Utility

Save uncommitted changes across multiple git repositories to remote backup branches. Essentially saves your open work to the cloud for all your repos at once.

## 📚 Documentation

- **[STASHME.md](STASHME.md)** - Complete documentation with installation, features, examples, and best practices
- **[STASHME-QUICK-REFERENCE.md](STASHME-QUICK-REFERENCE.md)** - Quick reference card for common commands
- **[STASHME-EXAMPLES.md](STASHME-EXAMPLES.md)** - Real-world usage examples

## 🚀 Quick Start

```bash
# Make executable
chmod +x stashme.sh

# Show help
./stashme.sh --help

# Stash all repos in ~/github (default)
./stashme.sh

# List repos with uncommitted changes
./stashme.sh --list

# Dry run to see what would happen
./stashme.sh --dry-run
```

## ✨ Key Features

- **Multi-Repo Support**: Process all git repositories under a directory tree
- **Cloud Backup**: Pushes changes to remote backup branches on GitHub
- **Safe by Default**: Creates new branches, never modifies your working branch
- **Timestamped Branches**: Automatic naming like `stashme/2026-02-03-143021`
- **Restore Mode**: Easily recover stashed changes later
- **Cleanup Mode**: Remove old stashme branches when done
- **Interactive Mode**: Confirm actions for each repository

## 🎯 Use Cases

| Scenario | Command |
|----------|---------|
| Going on vacation | `./stashme.sh -m "WIP: saving before vacation"` |
| Machine migration | `./stashme.sh --summary backup-report.txt` |
| Emergency backup | `./stashme.sh ~/projects` |
| Review pending work | `./stashme.sh --list` |
| Recover saved work | `./stashme.sh --restore` |
| Clean up old backups | `./stashme.sh --cleanup` |

## 📋 Prerequisites

- `git` - Version control system (2.0+)
- Remote repository (origin) configured for each repo

### Installation

```bash
# Clone the scripts repository
git clone https://github.com/bamr87/scripts.git
cd scripts/STASHME

# Make executable
chmod +x stashme.sh

# Optional: Add to PATH
ln -s "$(pwd)/stashme.sh" /usr/local/bin/stashme
```

## 📖 How It Works

1. **Discovers** all git repositories under the specified directory
2. **Identifies** repos with uncommitted changes (modified, staged, or untracked files)
3. **Creates** a timestamped branch from current HEAD
4. **Commits** all changes with a descriptive message
5. **Pushes** to origin (your fork/remote)
6. **Returns** to your original working branch

Your working branch is never modified. Changes are safely stored in a separate branch.

## 🔄 Workflow

```
~/github/
├── project-a/          # Has uncommitted changes → stashed
├── project-b/          # Clean → skipped
├── project-c/          # Has uncommitted changes → stashed
└── project-d/          # No remote → skipped

After running stashme.sh:
- project-a: Branch 'stashme/2026-02-03-143021' pushed to origin
- project-c: Branch 'stashme/2026-02-03-143021' pushed to origin
```

## 📁 Directory Structure

```
STASHME/
├── README.md                    # This file
├── stashme.sh                   # Main script
├── STASHME.md                   # Complete documentation
├── STASHME-QUICK-REFERENCE.md   # Quick reference card
└── STASHME-EXAMPLES.md          # Usage examples
```

## 🔗 Quick Links

- [Installation Guide](STASHME.md#installation)
- [Command Options](STASHME.md#options)
- [Real-World Examples](STASHME-EXAMPLES.md)
- [Quick Reference](STASHME-QUICK-REFERENCE.md)

---

**Built with ❤️ by the IT-Journey Scripts Team**
